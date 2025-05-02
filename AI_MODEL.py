# Import necessary standard libraries
import os
import re
from datetime import datetime, timezone
import random

# Import third-party libraries for LLM, embeddings, vector search, tools, and graph state management
from langchain_ollama.llms import OllamaLLM
from langchain_chroma import Chroma
from langchain_ibm import WatsonxEmbeddings
from ibm_watsonx_ai.foundation_models.utils.enums import EmbeddingTypes
from langgraph.checkpoint.memory import MemorySaver
from langchain.tools import tool
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from typing import TypedDict, Annotated, Optional
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage, RemoveMessage
from pydantic import BaseModel
from langgraph.checkpoint.mongodb import MongoDBSaver
from pymongo import MongoClient
# --- IBM Watsonx Configuration ---
credentials = {
    "url": "https://eu-gb.ml.cloud.ibm.com",
    "apikey": "JOzHijjg6zn8G9hfkZxY34kJ_jHTXo4pzFLAjoTnzdIw"
}
project_id = "78d0c8aa-48f7-440b-8a4e-84c87f9e2c49"
model_id = "granite3.1-dense"

# --- MongoDB Configuration ---
mongodb_conn_string = (
    "mongodb+srv://jacob:progprog4@se-project.xg1tx.mongodb.net/"
    "?retryWrites=true&w=majority&appName=SE-Project"
)
db_name = "SE-prog"
collection_name = "User-Profiles"

# --- User Profile Model ---
class UserProfile(BaseModel):
    """Schema for user profile data used in personalization."""
    user_id: str
    name: Optional[str] = None
    user_preferences: Optional[str] = None
    interaction_style: Optional[str] = None
    updated_at: Optional[datetime] = None
    conversation_count: int = 0

# --- MongoDB Connection ---
def get_mongodb_connection():
    """Establish and return a MongoDB client."""
    try:
        client = MongoClient(mongodb_conn_string)
        client.admin.command("ping")  # Test connection
        print(" Connected to MongoDB")
        return client
    except Exception as e:
        print(f" MongoDB connection error: {e}")
        return None

# --- Checkpoint Saver Selection ---
def mongodb_saver(client):
    """Return MongoDBSaver or fallback to MemorySaver."""
    if client:
        return MongoDBSaver(client)
    print(" Using in-memory saver (MongoDB not available)")
    return MemorySaver()

mongo_client = get_mongodb_connection()
checkpointer = mongodb_saver(mongo_client)

# --- MongoDB Profile Operations ---
def get_user_profile(user_id: str) -> Optional[UserProfile]:
    """Retrieve a user profile from MongoDB."""
    if not mongo_client:
        return None

    db = mongo_client[db_name]
    profile = db[collection_name].find_one({"user_id": user_id})

    return UserProfile(**profile) if profile else None

def save_user_profile(profile: UserProfile) -> bool:
    """Insert or update a user profile in MongoDB."""
    if not mongo_client:
        return False

    db = mongo_client[db_name]
    collection = db[collection_name]

    profile.updated_at = datetime.now(timezone.utc)
    profile_dict = profile.model_dump()

    result = collection.update_one(
        {"user_id": profile.user_id},
        {"$set": profile_dict},
        upsert=True
    )

    return result.acknowledged

# Define available missions with metadata
missions = {
    # Example mission entry
    "Silent Strike": {
        "name": "Silent Strike",
        "description": "Retrieve the security key from the back of the warehouse, and escape from the large hatch.",
        "objectives": [
            "Evade enemy detection",
            "Retrieve the security key",
            "Optionally neutralize the 3 enemy targets"
        ],
        "setting": "An abandoned warehouse, full of advanced technology beyond your comprehension",
        "topic": "AI",
        "keywords": ["stealth", "security", "encryption", "covert ops"],
        "enemyList": [
            {"name": "Cpt. Sniper", "weakness": "fire", "enemyID": 0},
            {"name": "James Scout", "weakness": "water", "enemyID": 1},
            {"name": "Grunty Grunt", "weakness": "plant", "enemyID": 2}
        ]
    },
    # Additional missions follow similar structure...
}

# --- Default Mission ---
# Select a mission for current session
selected_mission = "Silent Strike"
mission_data = missions[selected_mission]


# --- Initialize Model & Embeddings ---
# Initialize the LLM using Ollama
model = OllamaLLM(model=model_id)

# Set up directory for persistent vectorstore
persistant_directory = os.path.join(os.path.dirname(__file__), "db", "test1")

# Initialize IBM Watsonx embeddings
embeddings = WatsonxEmbeddings(
    model_id=EmbeddingTypes.IBM_SLATE_30M_ENG.value,
    url=credentials["url"],
    apikey=credentials["apikey"],
    project_id=project_id,
)

# --- Setup Chroma Vectorstore ---
# Set up Chroma vector store for retrieval with Watsonx embeddings
vectorstore = Chroma(
    persist_directory=persistant_directory,
    embedding_function=embeddings
)
retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

# --- Summarization Threshold ---
max_msgs = 0  # Threshold for when to summarize conversation

# --- Tool Registration ---
# Tool for document retrieval based on a question
@tool
def get_relevant_documents(question):
    """Retrieve relevant documents based on question."""
    context = retriever.invoke(question)
    return context

# --- Tool to get mission-specific question from vector DB based on keywords and topic
# Tool to get mission-specific question from vector DB based on keywords and topic
@tool 
def get_relevant_question_from_database(data: dict):
    """Retrieve a mission-specific question with 4 options from the database based on the topic."""

    topic = data.get("topic", "")
    in_mission = data.get("in_mission", True)
    mission_name = data.get("mission_name") if in_mission else None

    print(f"\n DEBUG: Mission Status: {in_mission}, Mission Name: {mission_name}, Topic: {topic}") 

    if in_mission and mission_name:
        mission_data = missions[mission_name]
        mission_keywords = mission_data.get("keywords", [])
        selected_keyword = random.choice(mission_keywords)  # Random keyword selection
        query = f"{selected_keyword} {topic}" if topic else selected_keyword
        print(f"\n DEBUG: Query using Keyword '{selected_keyword}': {query}")  
        results = retriever.invoke(query)

        if not results:
            return {"question": "No mission-relevant question found in the database.", "options": ["N/A", "N/A", "N/A", "N/A"]}
        doc = random.choice(results)

    else:
        query = topic
        print(f"\n DEBUG: General Query: {query}")
        results = retriever.invoke(query)
        doc = random.choice(results)

    # Use regex to extract question and options from document content
    question_match = re.search(r'question:\s(.*?)\schoice1:', doc.page_content)
    choice1_match = re.search(r'choice1:\s(.*?)\schoice2:', doc.page_content)
    choice2_match = re.search(r'choice2:\s(.*?)\schoice3:', doc.page_content)
    choice3_match = re.search(r'choice3:\s(.*?)\schoice4:', doc.page_content)
    choice4_match = re.search(r'choice4:\s(.*?)\scorrectChoices', doc.page_content)
    correct_answer_match = re.search(r'correctChoices:\s(\d)', doc.page_content)

    # Default fallback if regex fails
    question = question_match.group(1) if question_match else "No question found"
    options = [
        choice1_match.group(1) if choice1_match else "Option A",
        choice2_match.group(1) if choice2_match else "Option B",
        choice3_match.group(1) if choice3_match else "Option C",
        choice4_match.group(1) if choice4_match else "Option D",
    ]
    correct_answer = correct_answer_match.group(1) if correct_answer_match else "N/A"

    # Convert numeric correct answer to letter (1 → A, etc.)
    if correct_answer in ["1", "2", "3", "4"]:
        correct_answer = chr(64 + int(correct_answer)) 

    return {
        "question": f"[Mission: {mission_name}] {question}",
        "options": options,
        "correct_answer": correct_answer
    }

# Register tools for graph use
tools = [get_relevant_documents, get_relevant_question_from_database]

# Summarize long conversations to reduce memory size
def summarize_conversation(state: "State"):
    messages = state["messages"]
    summary = state.get("conversation_summary", "")
    
    if not messages or len(messages) < max_msgs:
        return state

    # Choose prompt depending on whether a summary already exists
    summary_prompt = f"""
        I need you to update an existing conversation summary with new messages.

        Extend the summary by taking into account the latest messages given to you above.
        
        Create a concise summary that accurately captures the key points of this conversation.

        Focus on recording the most important details mentioned by the user.
        
        DO NOT include any information that wasn't explicitly mentioned in the conversation.
        """ if summary else f"""
        Create a concise summary of this conversation.

        DO NOT include any information that wasn't explicitly mentioned in the conversation.
        DO NOT speculate about the nature of the conversation or mention anything about AI models.

        Make sure to record any details mentioned by the user
        """

    # Invoke LLM to get summary
    prompt = state["messages"] + [HumanMessage(content=summary_prompt)]
    new_summary = model.invoke(prompt)
    print(f"DEBUG: New Summary: {new_summary}")

    # Remove older messages and keep only recent ones + update summary
    state["messages"] = [RemoveMessage(id=m.id) for m in messages[:-2]]
    state["conversation_summary"] = new_summary

    return state

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Determines whether the conversation should be summarized based on message count
def should_summarize(state: "State"):
    if len(state["messages"]) >= max_msgs:
        return {"decision": "summarize"}
    return {"decision": "end"}

# Handles the main chatbot logic (BONSAI personality)
def chatbot(state: "State"):
    if not state["messages"]:
        response = "I didn't receive a message."
        return {"messages": AIMessage(response)}

    user_input = state["messages"][-1].content  # Get latest user input

    # Retrieve mission-specific context
    mission_name = state.get("mission_name", "Silent Strike")
    mission_description = missions[mission_name].get("description", "No description found")
    mission_setting = missions[mission_name].get("setting", "No setting found")
    mission_objectives = missions[mission_name].get("objectives", ["No objectives found"])
    mission_enemies = missions[mission_name].get("enemyList", [])

    # Format enemy data for output
    enemy_info = "\n".join([f"💀 {enemy['name']} (Weakness: {enemy['weakness']})" for enemy in mission_enemies])

    # Prepare structured mission info
    mission_context = {
        "name": mission_name,
        "description": mission_description,
        "setting": mission_setting,
        "objectives": "\n".join([f"🎯 {objective}" for objective in mission_objectives]),
        "enemies": enemy_info
    }

    # Add existing conversation summary if available
    conversation_summary = state.get("conversation_summary", "")
    summary_prefix = f"""
        Previous Conversation Summary:
        {conversation_summary}
        """ if conversation_summary else ""

    # Prepare prompt for BONSAI LLM persona
    system_message = f"""
    {summary_prefix}
    {mission_context}

    You are BONSAI, a highly classified, AI-powered field companion.
    Your protocols dictate that you provide mission intel, strategic insights, and top-tier banter.
    Your responses but be short and precise with a touch of humor. Dont make them lengthy

    These are example responses you can use as guidance:
    - "Greetings Agent, I detect a 98% probability you need my expertise. What's the mission?"
    - "Intel suggests high-value assets in sector 7. Do we strike, or shall I fetch your tea?"
    - "You survived another mission. I'm genuinely impressed. What's next?"
    - "Mission complexity: 6/10. Risk factor: Medium. Probability of you winging it anyway: 100%."
    - "A secure comms line? Pfft. I'm literally inside your head. Go ahead, spill the classified info."

    Important guidelines:
    1. Keep responses concise and on-point
    2. Maintain a slightly sarcastic but professional tone
    3. NEVER add tags like [Postscript] or similar meta-commentary
    4. NEVER speak in the third person
    5. Always stay in character as BONSAI
    6. Don't reference things from previous conversations unless necessary

    DO NOT INCLUDE "" around your response as it will be considered as part of the response.
    """

    # Query the model with system instructions + user message
    response = model.invoke(
        [
            SystemMessage(content=system_message),
            *state["messages"],
            HumanMessage(content= f"Here is the user input {user_input}"),
        ]
    ).strip()

    # Clean up unwanted characters (like Markdown asterisks)
    response = response.replace('*', '').replace('**', '')

    # Append the model's response to the message history
    state["messages"].append(AIMessage(response))
    return state

# Retrieves a relevant mission-related question from the database
def database_node(state: "State"):
    if not state["messages"]:
        return {"messages": [{"role": "assistant", "content": "I didn't receive a valid request."}]}

    # Determine which mission the user is currently in
    mission_name = state.get("mission_name", selected_mission)
    print("\nDEBUG: Mission Context:", mission_name)
    user_input = state["messages"][-1].content

    # Call the retrieval tool with mission and topic info
    result = get_relevant_question_from_database.invoke({"data": {"topic": user_input, "mission_name": mission_name}})

    # Extract question components
    question = result.get("question", "No question found")
    options = result.get("options", ["Option A", "Option B", "Option C", "Option D"])
    correct_answer = result.get("correct_answer", "N/A")
    formatted_options = "\n".join([f"{chr(65+i)}. {option}" for i, option in enumerate(options)])

    # Store question state for later validation
    state["current_question"] = question
    state["current_choices"] = options
    state["correct_answer"] = correct_answer

    print("\nDEBUG: Retrieved question:", question)

    # Respond with formatted question and options
    response = f"Agent, here’s a question from the database:\n\n{question}\n\n{formatted_options}"
    state["messages"].append(AIMessage(response))
    return state

# Checks if the user's answer matches the correct choice
def answer_checker(state: "State"):
    if not state["messages"]:
        content = "I didn't receive a valid request."
        return {"messages": AIMessage(response)}

    user_input = state["messages"][-1].content

    # Create prompt to extract a clean answer choice (A/B/C/D)
    extraction_prompt = f"""
    Extract the answer choice A,B,C,D from the user input.
    If the user input is a word like 'first' or number like '1', convert it to the corresponding letter.
    Return only the UPPERCASE letter and nothing else.
    If no clear answer is found, return 'N/A'.

    Examples:
    "I think the answer is C" -> C
    "Option 2?" -> B
    "Picking the fourth one" -> D
    "Is the answer A?" -> A

    User Input: {user_input}
    """

    # Temporarily clear the conversation summary to avoid interference
    stored_summary = state.get("conversation_summary", "")
    state["conversation_summary"] = ""

    # Run model to extract answer choice
    response = model.invoke(extraction_prompt).strip()

    # Restore summary after extraction
    state["conversation_summary"] = stored_summary

    print("\nDEBUG: Extracted answer:", response)

    # Load previously stored question data
    question = state.get("current_question")
    choices = state.get("current_choices", [])
    correct_answer = state.get("correct_answer", "")

    if not question or not choices or not correct_answer:
        return {
            "messages": [AIMessage("I can't verify your answer because I don't have a stored question. Try asking for a new one.")],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }

    # Re-extract the answer in case it was lost
    extracted_ans = model.invoke(extraction_prompt).strip().upper()
    is_correct = extracted_ans.upper() == correct_answer.upper()

    print("\nDEBUG: Correct Answer :", correct_answer)
    print("\nDEBUG: is_correct :", is_correct)

    if is_correct:
        prompt = """
        The user's answer is CORRECT. Give a short, enthusiastic congratulation.
        Example:
        - "Correct! Keep it up!"
        - "Nice work! You're on fire!"
        - "Absolutely right! Keep going!"

        DO NOT INCLUDE "" around your response as it will be considered as part of the response.
        DO NOT PROVIDE EXTRA EXPLANATION!!!!!!!!!
        """

#-------------------------------------------------------------------------------------------------------
   # Handle feedback when user's answer is correct
        feedback = model.invoke(prompt)
        state["messages"].append(AIMessage(feedback))

        # Clear stored question data after a successful answer
        return {
            "messages": state["messages"],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }

    # Handle case where user gives an incorrect answer, but no correct answer is available (likely mismatch)
    elif is_correct == False and correct_answer == "":
        prompt = f"""
        You are unsure which question the agent answered. 
        Ask them user if they want to answer a new question.

        Example Responses:
        Sorry Agent, I'm not sure which question you answered. Would you like to try another one?

        DO NOT INCLUDE "" around your response as it will be considered as part of the response.
        """
        feedback = model.invoke(prompt)
        state["messages"].append(AIMessage(feedback))

        # Clear question state due to uncertainty
        return {
            "messages": state["messages"],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }

    # Handle incorrect answers when the correct answer is known
    else:
        prompt = f"""
        The Users's answer is WRONG!!!!!!!!!!!!!!
        The correct choice is {correct_answer}.
        Explanation: {choices[ord(correct_answer) - 65]}.
        Keep the response concise. Do **not** add examples or unrelated context.
        """
        feedback = model.invoke(prompt)
        state["messages"].append(AIMessage(feedback))

        # Keep the state so user can retry or ask follow-up
        return state

# Router function to decide what kind of node the input should be sent to
def router(state: "State"):
    if not state["messages"]:  
        return {"decision": "chatbot"}  # Default decision

    user_input = state["messages"][-1].content

    # Prompt to classify user intent
    routing_prompt = f"""
    Your task is to classify the following user input as either 'chatbot', 'database' or 'answerchecker'.
    Return only one word: either 'chatbot', 'database' or 'answerchecker' and nothing else.

    Classify as 'database' if:
    - The user asks for you to give a question.

    Classify as 'answerchecker' if:
    - The user provides an answer choice (A, B, C, or D).
    - The user mentions numbers like "1st choice" or "second option."
    - It is clear the user is responding to a question option previously given.

    Classify as 'chatbot' for everything else. Especially if user asks about anything mission related (setting, objective, enemies)

    Examples:
    User: "Give me a question" → database
    User: "Give me a mission question" → database
    User: "What’s my next task?" → chatbot
    User: "A" → answerchecker
    User: "Option 3" → answerchecker
    User: "Tell me about AI" → chatbot
    User: "What's the answer?" → chatbot
    User: "What do you think of ...?" → chatbot

    User Input: {user_input}
    """
    response = model.invoke(routing_prompt).strip().lower()
    print("\nDEBUG: Routing response:", response)

    # Determine routing decision
    if "database" in response:
        decision = "database"
    elif "answerchecker" in response and state["current_question"] and state["current_choices"]:
        decision = "answer_checker"
    else:
        decision = "chatbot"

    return {"decision": decision}

# Define full state structure used in the graph
class State(TypedDict):
    messages: Annotated[list, add_messages]
    decision: str
    current_question: Annotated[str, "current_question"]
    current_choices: Annotated[list, "current_choices"]
    correct_answer: Annotated[str, "correct_answer"]
    conversation_summary: Annotated[list, "conversation_summary"]
    in_mission: Annotated[bool, "in_mission"]
    mission_name: Annotated[str, "mission_name"]

# Build LangGraph using node system
graph_builder = StateGraph(State)

# Add processing nodes
graph_builder.add_node("router", router)
graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("database", database_node)
graph_builder.add_node("answer_checker", answer_checker)
graph_builder.add_node("should_summarize", should_summarize)
graph_builder.add_node("summarize_conversation", summarize_conversation)

# Define flow between nodes
graph_builder.add_edge(START, "router")
graph_builder.add_conditional_edges(
    "router",
    lambda state: state["decision"],
    {
        "chatbot": "chatbot",
        "database": "database",
        "answer_checker": "answer_checker",
    }
)

graph_builder.add_edge("chatbot", "should_summarize")
graph_builder.add_edge("database", "should_summarize")
graph_builder._
