import os
import pandas as pd

from langchain_ibm import WatsonxEmbeddings, WatsonxLLM
from langchain_chroma import Chroma
from langchain_community.document_loaders import WebBaseLoader, CSVLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain.prompts import PromptTemplate
from langchain.tools import tool
from langchain.tools.render import render_text_description_and_args
from langchain.agents.output_parsers import JSONAgentOutputParser
from langchain.agents.format_scratchpad import format_log_to_str
from langchain.agents import AgentExecutor
from langchain.memory import ConversationBufferMemory
from langchain_core.runnables import RunnablePassthrough
from langchain_core.messages import HumanMessage, AIMessage
from ibm_watson_machine_learning.metanames import GenTextParamsMetaNames as GenParams
from ibm_watsonx_ai.foundation_models.utils.enums import EmbeddingTypes

credentials = {
    "url" : "https://eu-gb.ml.cloud.ibm.com",
    "apikey" : os.getenv("WATSONX_APIKEY2")
}
project_id = os.getenv("WATSONX_PROJECT_ID2")
model_id = "ibm/granite-3-8b-instruct"

llm = WatsonxLLM(
    model_id=model_id,
    url=credentials.get("url"),
    apikey=credentials.get("apikey"),
    project_id=project_id,
    params={
        GenParams.DECODING_METHOD: "greedy", 
        GenParams.TEMPERATURE: 0,
        GenParams.MIN_NEW_TOKENS: 5,
        GenParams.MAX_NEW_TOKENS: 250,
        GenParams.STOP_SEQUENCES: ["Human", "Observation"],
    },
)

#CLEANING CSV FILE -> SPLITTING THE TEXT INTO CHUNKS -> EMBEDDING THE CHUNKS -> CREATING CHROMA DB FOR VECTORSTORE OF EMBEDDINGS
persistant_directory = os.path.join(os.path.dirname(__file__), "db", "test1")

if not os.path.exists(persistant_directory):
    csv_file_path = os.path.join(os.path.dirname(__file__), "Questions.csv")

    loader = CSVLoader(csv_file_path) #returns list of dicstionaries, each dictionary is a row, key are the column headers
    documents = loader.load()

    cleaned_documents = []
    for doc in documents:
        cleaned_page_content = doc.page_content.replace('\n', ' ').strip()
        cleaned_doc = Document(
            metadata=doc.metadata,
            page_content=cleaned_page_content
        )
        cleaned_documents.append(cleaned_doc)

    text_splitter = RecursiveCharacterTextSplitter.from_tiktoken_encoder(chunk_size = 250, chunk_overlap=0)
    splitted = text_splitter.split_documents(cleaned_documents)

    print(f"Number of documents: {len(splitted)}")
    print(f"Samples Chunk: {splitted[0].page_content}")

    embeddings = WatsonxEmbeddings(
        model_id=EmbeddingTypes.IBM_SLATE_30M_ENG.value,
        url = credentials.get("url"),
        apikey = credentials.get("apikey"),
        project_id = project_id,
    )

    db = Chroma.from_documents(splitted, embeddings, persist_directory=persistant_directory)
    print("Chroma DB created")
else:
    print("Chroma DB already exists")

embeddings = WatsonxEmbeddings(
    model_id=EmbeddingTypes.IBM_SLATE_30M_ENG.value,
    url = credentials.get("url"),
    apikey = credentials.get("apikey"),
    project_id = project_id,
)

vectorstore = Chroma(persist_directory=persistant_directory, embedding_function=embeddings)

retriever = vectorstore.as_retriever()

@tool
def multiplier(x, y):
    """Multiply two numbers together."""
    return x * y

@tool
def wikipedia(query):
    """Get a summary of a Wikipedia article on the query from the user."""
    from wikipedia import summary

    try:
        return summary(query, sentence=3)
    except:
        return "No summary found for this query."

def rephrase_question(question):
    """Rephrase the user's question to make it standalone to be queried in the database if related."""
    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", "Given a chat history and the latest user question which might reference context in the chat history, formulate a standalone question which can be understood without the chat history. Do NOT answer the question, just reformulate it if needed and otherwise return it as is"),
            MessagesPlaceholder("chat_history", optional=True),
            ("human", "User question: {input}"),
        ]
    )
    agent = prompt | llm
    result = agent.invoke({"input": question})

    return result

@tool
def get_relevant_documents(question):
    """Get the most relevant documents from the vector store based on the rephrased question."""
    rephrased_question = rephrase_question(question)
    context = retriever.invoke(rephrased_question)
    return context

tools = [multiplier, wikipedia, get_relevant_documents]

#rephrase for the vector store to retrieved the most relevant documents
contextualize_system_prompt = """Given a chat history and the latest user question which might reference context in the chat history, formulate a standalone question which can be understood without the chat history. Do NOT answer the question, just reformulate it if needed and otherwise return it as is"""

contextualize_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", contextualize_system_prompt),
        MessagesPlaceholder("chat_history", optional=True),
        ("human", "User question: {input}"),
    ]
)

#using ibms structured chat system prompt (typically used for conversations) for now 
system_prompt = """Respond to the human as helpfully and accurately as possible. You have access to the following tools: {tools}
Use a json blob to specify a tool by providing an action key (tool name) and an action_input key (tool input).
Valid "action" values: "Final Answer" or {tool_names}
Provide only ONE action per $JSON_BLOB, as shown:"
```
{{
  "action": $TOOL_NAME,
  "action_input": $INPUT
}}
```
Follow this format:
Question: input question to answer
Thought: consider previous and subsequent steps
Action:
```
$JSON_BLOB
```
Observation: action result
... (repeat Thought/Action/Observation N times)
Thought: I know what to respond
Action:
```
{{
  "action": "Final Answer",
  "action_input": "Final response to human"
}}
Begin! Reminder to ALWAYS respond with a valid json blob of a single action.
Respond directly if appropriate. Format is Action:```$JSON_BLOB```then Observation"""

human_prompt = """{input}
{agent_scratchpad}
(reminder to always respond in a JSON blob)""" 

prompt = ChatPromptTemplate.from_messages( 
    [
        ("system", system_prompt),
        MessagesPlaceholder("chat_history", optional=True),
        ("human", human_prompt),
    ]
)

prompt = prompt.partial(
    tools=render_text_description_and_args(list(tools)),
    tool_names=", ".join([t.name for t in tools]),
)


memory = ConversationBufferMemory()

#Set up the chain 
chain = (
    RunnablePassthrough.assign(
        agent_scratchpad=lambda x: format_log_to_str(x["intermediate_steps"]),
        chat_history=lambda x: memory.chat_memory.messages,
    )
    | prompt
    | llm
    | JSONAgentOutputParser()
)

agent_executor = AgentExecutor(agent=chain, tools=tools, handle_parsing_errors=True, verbose=True, memory=memory)

def chatting():
    print("Start chatting with the AI! Type '!exit' to quit.")

    while True:
        query = input("You: ")
        if query.lower() == "!exit":
            break
            
        memory.chat_memory.add_message(HumanMessage(query))
    
        result = agent_executor.invoke({"input" : query})
        output = result["output"]
        print(f"AI: {output}")

        memory.chat_memory.add_message(AIMessage(output))

chatting()