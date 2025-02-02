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
from langchain_core.messages import HumanMessage, SystemMessage
from pydantic import BaseModel, Field
from typing_extensions import Literal

# IBM Watson Credentials
credentials = {
    "url": "https://eu-gb.ml.cloud.ibm.com",
    "apikey": "..."
}

project_id = "..."
model_id = "granite3.1-dense:2b"

# Initialize Model
model = OllamaLLM(model=model_id)
persistant_directory = os.path.join(os.path.dirname(__file__), "db", "test1")

# Initialize Embeddings
embeddings = WatsonxEmbeddings(
    model_id=EmbeddingTypes.IBM_SLATE_30M_ENG.value,
    url=credentials["url"],
    apikey=credentials["apikey"],
    project_id=project_id,
)

# Initialize Vector Store
vectorstore = Chroma(persist_directory=persistant_directory, embedding_function=embeddings)
search_kwargs = {"k": 4}
retriever = vectorstore.as_retriever(search_kwargs=search_kwargs)

@tool
def get_relevant_documents(question):
    """Retrieve relevant documents based on question."""
    context = retriever.invoke(question)
    return context
import re

@tool 
def get_relevant_question_from_database(topic: str):
    """Retrieve a question with 4 options from the database based on the topic."""
    results = retriever.invoke(topic)

    # print("\nDEBUG: Retrieved results:", results)  # Debugging Line

    if results and len(results) > 0:
        doc = results[0]  # Take the first result
        # print("\nDEBUG: Retrieved document page_content:", doc.page_content)  # Debugging Line
        
        # Extract question and choices using regex
        question_match = re.search(r'question:\s(.*?)\schoice1:', doc.page_content)
        choice1_match = re.search(r'choice1:\s(.*?)\schoice2:', doc.page_content)
        choice2_match = re.search(r'choice2:\s(.*?)\schoice3:', doc.page_content)
        choice3_match = re.search(r'choice3:\s(.*?)\schoice4:', doc.page_content)
        choice4_match = re.search(r'choice4:\s(.*?)\s', doc.page_content)

        question = question_match.group(1) if question_match else "No question found"
        options = [
            choice1_match.group(1) if choice1_match else "Option A",
            choice2_match.group(1) if choice2_match else "Option B",
            choice3_match.group(1) if choice3_match else "Option C",
            choice4_match.group(1) if choice4_match else "Option D",
        ]

        return {"question": question, "options": options}
    else:
        return {"question": "No question found in the database.", "options": ["N/A", "N/A", "N/A", "N/A"]}



tools = [get_relevant_documents, get_relevant_question_from_database]

# Define chatbot node
def chatbot(state: "State"):
    """Handles normal chatbot responses."""
    if not state["messages"]:
        return {"messages": [{"role": "assistant", "content": "I didn't receive a message."}]}

    user_input = state["messages"][-1].content
    response = model.invoke(user_input).strip()

    return {
        "messages": [{"role": "assistant", "content": response}]
    }

# Define database node
def database_node(state: "State"):
    """Retrieves a relevant question from the database."""
    if not state["messages"]:
        return {"messages": [{"role": "assistant", "content": "I didn't receive a valid request."}]}

    user_input = state["messages"][-1].content
    result = get_relevant_question_from_database.invoke(user_input)
    
    question = result.get("question", "No question found")
    options = result.get("options", ["Option A", "Option B", "Option C", "Option D"])
    formatted_options = "\n".join([f"{chr(65+i)}. {option}" for i, option in enumerate(options)])

    return {
        "messages": [{"role": "assistant", "content": f"Agent, here’s a question from the database:\n\n{question}\n\n{formatted_options}"}]
    }

# Define router function
def router(state: "State"):
    """Routes the input to the chatbot or database node based on intent."""

    if not state["messages"]:  
        return {"decision": "chatbot"}  # Default to chatbot if no messages exist

    user_input = state["messages"][-1].content  

    routing_prompt = f"""
    Your task is to classify the following user input as either 'chatbot' or 'database'.
    Return only one word: either 'chatbot' or 'database' and nothing else.

    User Input: {user_input}
    """

    response = model.invoke(routing_prompt).strip().lower()

    # Ensure valid decision
    if "database" in response:
        decision = "database"
    else:
        decision = "chatbot"

    return {"decision": decision}

# Define state structure
class State(TypedDict):
    messages: Annotated[list, add_messages]
    decision: str
    current_question: str
    current_choices: list
    correct_answer: str

# Create the graph
graph_builder = StateGraph(State)

# Add nodes
graph_builder.add_node("router", router)
graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("database", database_node)

# Define conditional edges
graph_builder.add_edge(START, "router")
graph_builder.add_conditional_edges(
    "router",
    lambda state: state["decision"],
    {
        "chatbot": "chatbot",
        "database": "database"
    }
)

graph_builder.add_edge("chatbot", END)
graph_builder.add_edge("database", END)

# Compile the graph
memory = MemorySaver()
graph = graph_builder.compile(checkpointer=memory)

# Define answering function
def answering(user_input):
    """Handles user queries and processes responses from the AI."""
    user_message = {"role": "user", "content": user_input}

    # Ensure State is always initialized properly
    state = {
        "messages": [user_message],
        "decision": "",
        "current_question": "",
        "current_choices": [],
        "correct_answer": "",
    }

    events = graph.stream(state, config)

    assistant_response = "No response received."  # Default fallback response

    for event in events:
        for val in event.values():
            if "messages" in val and val["messages"]:
                assistant_response = val["messages"][-1]["content"]
    
    print('AI:', assistant_response)  # ✅ Always prints a response

config = {"configurable": {"thread_id": "1"}}

# Start chatbot loop
print("Start chatting with the AI! Type '!exit' to quit.")
while True:
    query = input("You: ")
    if query.lower() == "!exit":
        print("Byebye")
        break
    answering(query)
