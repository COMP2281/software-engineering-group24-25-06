import os
from langchain_ollama.llms import OllamaLLM
from langchain_chroma import Chroma
from langchain_ibm import WatsonxEmbeddings
from ibm_watsonx_ai.foundation_models.utils.enums import EmbeddingTypes
from langgraph.checkpoint.memory import MemorySaver
from langchain.tools import tool
from langchain.prompts import MessagesPlaceholder
from langchain.prompts import ChatPromptTemplate
from langchain.tools.render import render_text_description_and_args
from langchain_core.runnables import RunnablePassthrough
from langchain.agents.output_parsers import JSONAgentOutputParser
from langchain.agents import AgentExecutor
from langchain.agents.format_scratchpad import format_log_to_str
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.checkpoint.memory import MemorySaver
from typing import TypedDict, Annotated

#EU = "https://eu-gb.ml.cloud.ibm.com"
credentials = {
    "url" : "https://us-south.ml.cloud.ibm.com",
    "apikey" : os.getenv("WATSONX_APIKEY")
}

project_id = os.getenv("WATSONX_PROJECT_ID")
model_id = "granite3.1-dense"

model = OllamaLLM(model=model_id)
persistant_directory = os.path.join(os.path.dirname(__file__), "db", "test1")

embeddings = WatsonxEmbeddings(
    model_id=EmbeddingTypes.IBM_SLATE_30M_ENG.value,
    url = credentials.get("url"),
    apikey = credentials.get("apikey"),
    project_id = project_id,
)
#20 AI questions, 19 Cyberseucrity questions, 21 Data Analytic questions, 27 Cloud questions.

vectorstore = Chroma(persist_directory=persistant_directory, embedding_function=embeddings)

#Can also apply filters like "filter": {"metadata.credential": "Getting Started with Artificial Intelligence"}
search_kwargs = {
    "k": 4,
}

retriever = vectorstore.as_retriever(search_kwargs=search_kwargs)

@tool
def get_relevant_documents(question):
    """Retrieve relevant documents based on question."""
    rephrased_question = question  # Assuming no rephrasing is necessary
    context = retriever.invoke(f"{rephrased_question}")
    return context

tools = [get_relevant_documents]

contextualize_system_prompt = """Given a chat history and the
         latest user question which might 
         reference context in the chat history, 
         formulate a standalone question which 
         can be understood without the chat history. 
         Do NOT answer the question, just reformulate 
         it if needed and otherwise return it as is"""

contextualize_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", contextualize_system_prompt),
        MessagesPlaceholder("chat_history", optional=True),
        ("human", "User question: {input}"),
    ]
)

system_prompt = """You are a helpful and freindly AI assitant. You can engage in casual conversation and help with questions/tasks.
Respond to the human as helpfully and accurately as possible. You have access to the following tools: {tools}
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

For direct responses, use the following format:
{{
"action": "Final Answer",
"action_input": "Your response here"
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


class State(TypedDict):
    messages : Annotated[list, add_messages]

graph_builder = StateGraph(State)
memory = MemorySaver()

def chatbot(state: State):

    chain = (
        RunnablePassthrough.assign(
            agent_scratchpad=lambda x: format_log_to_str(x.get("intermediate_steps", [])),
            chat_history=lambda x: state["messages"],
        )
        | prompt
        | model
        | JSONAgentOutputParser()
    )

    agent_executor = AgentExecutor(
        agent=chain, 
        tools=tools, 
        handle_parsing_errors=True, 
        verbose=True)

    last_message = state["messages"][-1]
    input_content = last_message.content

    input_dict = {
        "input": input_content,
    }
    
    result = agent_executor.invoke(input_dict)

    return {"messages": result["output"]}

graph_builder.add_node("chatbot", chatbot)

graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", END)

graph = graph_builder.compile(checkpointer=memory)

def answering(user_input):
    for event in graph.stream({"messages": [{"role": "user", "content": user_input}]}, config):
        for val in event.values():
            print('AI:', val["messages"])

config = {"configurable" : {"thread_id": "1"}}

print("Start chatting with the AI! Type '!exit' to quit.")
while True:
    query = input("You: ")
    if query.lower() == "!exit":
        print("Byebye")
        break
    
    answering(query)



