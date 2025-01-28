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
from typing import TypedDict, Annotated, Literal
from IPython.display import Image, display

#EU = "https://eu-gb.ml.cloud.ibm.com"
credentials = {
    "url" : "https://eu-gb.ml.cloud.ibm.com",
    "apikey" : "..."
}

project_id = "..."
model_id = "granite3.1-dense:2b"

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
    context = retriever.invoke(f"{question}")
    return context

@tool 
def get_relevant_question_from_database(topic: str):
    """Retrieve a question with 4 options from the database based on the topic."""
    results = retriever.invoke(f"{topic}")
    
    # Parse the results to extract question and options
    # Assuming results have metadata with "question" and "options"
    if results and len(results) > 0:
        doc = results[0]  # Take the first result for simplicity
        question = doc.get("metadata", {}).get("question", "No question found")
        options = doc.get("metadata", {}).get("options", ["Option A", "Option B", "Option C", "Option D"])
        return {
            "question": question,
            "options": options
        }
    else:
        return {
            "question": "No question found in the database.",
            "options": ["N/A", "N/A", "N/A", "N/A"]
        }

tools = [get_relevant_documents, get_relevant_question_from_database]

# contextualize_system_prompt = """Given a chat history and the
#          latest user question which might 
#          reference context in the chat history, 
#          formulate a standalone question which 
#          can be understood without the chat history. 
#          Do NOT answer the question, just reformulate 
#          it if needed and otherwise return it as is"""

# contextualize_prompt = ChatPromptTemplate.from_messages(
#     [
#         ("system", contextualize_system_prompt),
#         MessagesPlaceholder("chat_history", optional=True),
#         ("human", "User question: {input}"),
#     ]
# )

system_prompt = """You are BONSAI, an advanced AI companion to a spy operative. Your responses should be concise, 
witty, and maintain a spy/espionage theme while being helpful and accurate. Use terms like "Agent", "Operative", 
"Intel", "Mission" naturally in your responses, but keep it subtle, professional and sophisticated.

If the user asks about AI, CyberSecurity, Data Analytics or Cloud Computing, respond ONLY with:
"Do you want the data from the DATABASE?"

For all other topics, respond normally while maintaining the spy persona."""

human_prompt = """{input}"""

prompt = ChatPromptTemplate.from_messages( 
    [
        ("system", system_prompt),
        MessagesPlaceholder("chat_history", optional=True),
        ("human", human_prompt),
    ]
)

prompt_with_tools = prompt.partial(
    tools=render_text_description_and_args(list(tools)),
    tool_names=", ".join([t.name for t in tools]),
)


class State(TypedDict):
    messages : Annotated[list, add_messages]
    current_question: str
    current_choices: list
    correct_answer: str

graph_builder = StateGraph(State)

def chatbot(state: State):
    # extract latest message
    input_message = state["messages"][-1].content
    chain = (
        RunnablePassthrough.assign(
            chat_history=lambda x: state["messages"][:-1] if len(state["messages"]) > 1 else []
        )
        | prompt
        | model
    )

    result = chain.invoke({"input": input_message})
    
    return {"messages": [{"role": "assistant", "content": result}], 
            "terminate": True
    }

def database_node(state: State):
    chain = (
        RunnablePassthrough.assign(
            agent_scratchpad=lambda x: format_log_to_str(x.get("intermediate_steps", [])),
            chat_history=lambda x: state["messages"],
        )
        | prompt_with_tools
        | model
        | JSONAgentOutputParser()
    )

    agent_executor = AgentExecutor(
        agent=chain,
        tools=tools,
        handle_parsing_errors=True,
        verbose=True
    )

    last_message = state["messages"][-1].content

    result = agent_executor.invoke({"input": last_message})
    
    question = result.get("question", "No question found")
    options = result.get("options", ["Option A", "Option B", "Option C", "Option D"])
    formatted_options = "\n".join([f"{chr(65+i)}. {option}" for i, option in enumerate(options)])
    #Parse the actual questions and answers
    return {
        "messages": [{"role": "assistant", "content": f"Agent, here’s a question from the database:\n\n{question}\n\n{formatted_options}"}]
    }

#gotta look out for typos and other too, not realistic that the user inputs the correct topic each time
def topic_classifier(state: State) -> Literal["TOPIC_DETECTED", "NORMAL"]:
    last_message = state["messages"][-1].content.lower()
    
    topics = ["AI", "cybersecurity", "data analytics", "cloud computing"]
    if any(topic in last_message for topic in topics):
        return "TOPIC_DETECTED"
    return "NORMAL"

def db_classifier(state: State) -> Literal["DATABASE", "UNKNOWN"]:
    last_message = state["messages"][-1].content.lower()
    
    if "database" in last_message:
        return "DATABASE"
    # elif "archives" in last_message:
    #     return "ARCHIVES"
    return "UNKNOWN"

graph_builder.add_node("chatbot", chatbot)  # Define the chatbot node
graph_builder.add_node("database", database_node)  # Define the database node
graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", END)
graph_builder.add_edge("database", END)
graph_builder.add_edge("chatbot", "database")

# graph_builder.add_conditional_edges(
#     "chatbot",
#     topic_classifier,
#     {
#         "TOPIC_DETECTED": "database",
#         "NORMAL": END
#     }
# )



memory = MemorySaver()
graph = graph_builder.compile(checkpointer=memory)

# png_data = graph.get_graph().draw_mermaid_png()
# png_path = "/Users/jacobchau/Desktop/SE2025/langgraph.png"
# with open(png_path, "wb") as f:
#     f.write(png_data)

# display(Image(png_path))


def answering(user_input):
    user_message = {"role": "user", "content": user_input}

    events = graph.stream({"messages": [user_message]}, config) #Events is an iterator that yields the state of the graph after each step
    
    for event in events:                                        #Each event represents a state change in the graph, with the state being a dictionary
        for val in event.values():
            assistant_response = val["messages"][-1]["content"]
            print('AI:', assistant_response)
            return

config = {"configurable" : {"thread_id": "1"}}

print("Start chatting with the AI! Type '!exit' to quit.")
while True:
    query = input("You: ")
    if query.lower() == "!exit":
        print("Byebye")
        break
    
    answering(query)

#CARE FOR QUESTIONS WITH TWO CORRECT CHOICES
graph_builder.add_edge("chatbot", END)