import os
import re

from langchain_ollama.llms import OllamaLLM
from langchain_chroma import Chroma
from langchain_ibm import WatsonxEmbeddings
from ibm_watsonx_ai.foundation_models.utils.enums import EmbeddingTypes
from langgraph.checkpoint.memory import MemorySaver
from langchain.tools import tool
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.checkpoint.memory import MemorySaver
from typing import TypedDict, Annotated
from langchain_core.messages import HumanMessage, SystemMessage, AIMessage
# from langmem import MemoryStore, Memory



#EU = "https://eu-gb.ml.cloud.ibm.com"
#NA = "https://us-south.ml.cloud.ibm.com"
credentials = {
    "url": "https://eu-gb.ml.cloud.ibm.com",
    "apikey": "...",
}

project_id = "..."
model_id = "granite3.1-dense"

#--------------------------------------------------------
#-------------------MIssion Stuff------------------------


missions = {
    "Silent Strike": {
        "description": "Eliminate 10 high-value targets and extract encrypted intel from the vault.",
        "objectives": [
            "Neutralize all 10 targets.",
            "Retrieve the encryption keys.",
            "Evade enemy detection."
        ],
        "keywords": ["Cyber Security", "Security", "Encryption"]
    },
    "Cyber Heist": {
        "description": "Infiltrate the mainframe, extract classified documents, and escape unnoticed.",
        "objectives": [
            "Hack the bank's security system.",
            "Download confidential files.",
            "Exit through the safehouse."
        ]
    },
    "Operation Blackout": {
        "description": "Disable the city’s power grid to create a diversion for your team’s entry.",
        "objectives": [
            "Locate the power station control room.",
            "Disable critical generators.",
            "Escape before the backup systems activate."
        ]
    }
}


## --------------------------------------------------------
## -------------------Long term memory---------------------
#----------------------------------------------------------

# memory_store = MemoryStore()
# USER_NAMESPACE = "user_123"  # Replace dynamically per user session

# def store_user_memory(user_id, key, value):
#     """Stores user-specific memory in LangMem"""
#     namespace = f"user_{user_id}"  # Unique namespace per user
#     memory_store.save(
#         namespace=namespace,
#         memory=Memory(content={key: value})
#     )



# --------------------------------------------------------
# --------------------------------------------------------


selected_mission = "Silent Strike"
mission_data = missions[selected_mission]

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

@tool 
def get_relevant_question_from_database(data: dict):
    """Retrieve a mission-specific question with 4 options from the database based on the topic."""

    topic = data.get("topic", "")
    mission_name = data.get("mission_name")
    print("\n🔥 DEBUG: Mission Name :", mission_name)  # Debugging Line


    mission_data = missions[mission_name]
    print("\n🔥 DEBUG: Mission Data:", mission_data)  # Debugging Line
    
    mission_keywords = mission_data.get("keywords", [])

    keyword_query = " ".join(mission_keywords)
    print("\n🔥 DEBUG: Mission Keywords:", mission_keywords)  # Debugging Line


    query = f"{mission_keywords} {topic}" if keyword_query else topic 
    print("\n🔥 DEBUG: Query Sent to Retriever:", query)  # Debugging Line
 
    results = retriever.invoke(query)

    # print("\nDEBUG: Retrieved results:", results)  # Debugging Line

    if results and len(results) > 0:
        # Filter for the most relevant mission-based question
        best_match = None
        for doc in results:
            for keyword in mission_keywords:
                if keyword.lower() in doc.page_content.lower():
                    best_match = doc  # Prioritize mission-related question
                    break  
            if best_match:
                break

        doc = best_match if best_match else results[0]  # Fallback to first result
        print("\nDEBUG: Retrieved document page_content:", doc.page_content)  # Debugging Line
        
        # Extract question and choices using regex
        question_match = re.search(r'question:\s(.*?)\schoice1:', doc.page_content)
        choice1_match = re.search(r'choice1:\s(.*?)\schoice2:', doc.page_content)
        choice2_match = re.search(r'choice2:\s(.*?)\schoice3:', doc.page_content)
        choice3_match = re.search(r'choice3:\s(.*?)\schoice4:', doc.page_content)
        choice4_match = re.search(r'choice4:\s(.*?)\scorrectChoices', doc.page_content)
        correct_answer_match = re.search(r'correctChoices:\s(\d)', doc.page_content)

        question = question_match.group(1) if question_match else "No question found"
        options = [
            choice1_match.group(1) if choice1_match else "Option A",
            choice2_match.group(1) if choice2_match else "Option B",
            choice3_match.group(1) if choice3_match else "Option C",
            choice4_match.group(1) if choice4_match else "Option D",
        ]
        correct_answer = correct_answer_match.group(1) if correct_answer_match else "N/A"

        if correct_answer in ["1", "2", "3", "4"]:
            correct_answer = chr(64 + int(correct_answer)) 

        return {
            "question": f"[Mission: {mission_name}] {question}",
            "options": options,
            "correct_answer": correct_answer
        }
    
    else:
        return {"question": "No mission-relevant question found in the database.", "options": ["N/A", "N/A", "N/A", "N/A"]}



tools = [get_relevant_documents, get_relevant_question_from_database]

# Define chatbot node
def chatbot(state: "State"):
    """Handles normal chatbot responses."""
    if not state["messages"]:
        response = "I didn't receive a message."
        return {"messages": AIMessage(response)}

    user_input = state["messages"][-1].content
    mission_name = state.get("mission_name", selected_mission)  # Retrieve mission name
    mission_data = missions.get(mission_name, {})  # Retrieve mission details
    mission_description = mission_data.get("description", "Mission details unavailable.")
    mission_objectives = mission_data.get("objectives", ["Mission objectives not specified."])

    system_message = f"""
    ⚡ Mission Update: {mission_name} ⚡

    Briefing: {mission_description}

    You are speaking to BONSAI, your highly classified, AI-powered field companion.
    My protocols dictate that I provide mission intel, strategic insights, and top-tier banter.

    🔹 **Mission Status:** Active  
    🔹 **Operative Status:** Hopefully caffeinated  
    🔹 **Potential Threats:** Low (unless your Wi-Fi goes out)  

    🎯 **Objectives:**
    {chr(10).join(['- ' + obj for obj in mission_objectives])}

    💡 **Directives:**  
    - Stay Tactical: Efficiency is key, but style is everything.  
    - Witty Yet Wise: Expect intelligence with a side of sarcasm.  
    - Field Tested, Operative Approved: No unnecessary exposition. You ask, I deliver.  
    - Security First: Remember, the walls may have ears. Stay discreet.  

    🕵️‍♂️ **Example Responses (Use this style in responses):**  
    - Greetings: "Agent, I detect a 98% probability you need my expertise. What's the mission?"  
    - Briefing Mode: "Intel suggests high-value assets in sector 7. Do we strike, or shall I fetch your tea?"  
    - Casual Exchange: "You survived another mission. I’m genuinely impressed. What’s next?"  
    - Strategic Advisory: "Mission complexity: 6/10. Risk factor: Medium. Probability of you winging it anyway: 100%."  
    - Field Humor: "A secure comms line? Pfft. I’m literally inside your head. Go ahead, spill the classified info."  
    """


    response = model.invoke(
        [
            SystemMessage(content=system_message), 
            *state["messages"],
            HumanMessage(
                content= f"Here is the user input {user_input}"
            ),
        ]
    ).strip()

    # Ensure clean output without extra formatting
    response = response.replace('*', '').replace('**', '')

    state["messages"].append(AIMessage(response))

    # print("FROM CHATBOT :", state["messages"])  # Debugging Line

    return {
        "messages": state["messages"]
    }

# Define database node
def database_node(state: "State"):
    """Retrieves a relevant question from the database."""
    
    if not state["messages"]:
        return {"messages": [{"role": "assistant", "content": "I didn't receive a valid request."}]}


    mission_name = state.get("mission_name", selected_mission)  # Retrieve mission name
    print("\nDEBUG: Mission Context:", mission_name)  # Debugging Line
    user_input = state["messages"][-1].content

    result = get_relevant_question_from_database.invoke({"data": {"topic": user_input, "mission_name": mission_name}})

    question = result.get("question", "No question found")
    options = result.get("options", ["Option A", "Option B", "Option C", "Option D"])
    correct_answer = result.get("correct_answer", "N/A")
    formatted_options = "\n".join([f"{chr(65+i)}. {option}" for i, option in enumerate(options)])

    state["current_question"] = question
    state["current_choices"] = options
    state["correct_answer"] = correct_answer


    print("\nDEBUG: Retrieved question:", question)  # Debugging Line

    response = f"Agent, here’s a question from the database:\n\n{question}\n\n{formatted_options}"
    state["messages"].append(AIMessage(response))

    return state

# Define answer_checker node
def answer_checker(state: "State"):
    """Checks the user's answer against the correct answer."""
    if not state["messages"]:
        content = "I didn't receive a valid request."
        return {"messages": AIMessage(response)}

    user_input = state["messages"][-1].content
    
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

    response = model.invoke(extraction_prompt).strip()

    print("\nDEBUG: Extracted answer:", response)  # Debugging Line
        
    question = state.get("current_question")
    choices = state.get("current_choices", [])
    correct_answer = state.get("correct_answer", "")  # Convert to uppercase

    if not question or not choices or not correct_answer:
        return {
            "messages": [AIMessage("I can't verify your answer because I don't have a stored question. Try asking for a new one.")],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }

    is_correct = response.lower() == correct_answer.lower()

    print("\nDEBUG: Correct Answer :", correct_answer)  # Debugging Line
    print("\nDEBUG: is_correct :", is_correct)  # Debugging Line

    if is_correct:
        prompt = """
        The agent got the answer right! Give a short, enthusiastic congratulation.
        Example:
        - "Correct! Keep it up!"
        - "Nice work! You're on fire!"
        - "Absolutely right! Keep going!"
        """

        feedback = model.invoke(prompt)

        state["messages"].append(AIMessage(feedback))

        #Clears the state when we reset the question
        return {
            "messages": state["messages"],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }
    
    elif is_correct == False and correct_answer == "":
        prompt = f"""
        You are unsure which question the agent answered. 
        Ask them user if they want to answer a new question.

        Example Responses:
        Sorry Agent, I'm not sure which question you answered. Would you like to try another one?
        """
        feedback = model.invoke(prompt)

        state["messages"].append(AIMessage(feedback))

        return {
            "messages": state["messages"],
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }
    
    else:
        prompt = f"""
        Your answer was incorrect. The correct choice is {correct_answer}.
        Explanation: {choices[ord(correct_answer) - 65]}.
        Keep the response concise. Do **not** add examples or unrelated context.
        """
        feedback = model.invoke(prompt)

        state["messages"].append(AIMessage(feedback))

        # Keep the state for retry

    return {
        "messages": state["messages"],
        "current_question": "",
        "current_choices": [],
        "correct_answer": ""
    }
    
# Define router function
def router(state: "State"):
    """Routes the input to the chatbot, database or answer_checker node based on intent."""

    if not state["messages"]:  
        return {"decision": "chatbot"}  # Default to chatbot if no messages exist

    user_input = state["messages"][-1].content  

    # WE NEED TO FIX WHEN THE USER SIMPLY SAYS A B C D THEN IT SHOULD GO ANSWER CHECKER
    routing_prompt = f"""
    Your task is to classify the following user input as either 'chatbot', 'database' or 'answerchecker'.
    Return only one word: either 'chatbot', 'database' or 'answerchecker' and nothing else.

    Classify as 'database' if:
    - The user asks for a question.

    Classify as 'answerchecker' if:
    - The user provides an answer choice (A, B, C, or D).
    - The user mentions numbers like "1st choice" or "second option."
    - It is clear the user is responding to a question option previously given.

    Classify as 'chatbot' for everything else.

    Examples:
    User: "Give me a question" → database
    User: "Give me a mission question" → database
    User: "What’s my next task?" → chatbot
    User: "A" → answerchecker
    User: "Option 3" → answerchecker
    User: "Tell me about AI" → chatbot

    User Input: {user_input}
    """

    response = model.invoke(routing_prompt).strip().lower()

    print("\nDEBUG: Routing response:", response)  # Debugging Line

    # Ensure valid decision
    if "database" in response:
        decision = "database"
    elif "answerchecker" in response and state["current_question"] and state["current_choices"]:
        decision = "answer_checker"
    else:
        decision = "chatbot"

    return {"decision": decision}

# Define state structure
class State(TypedDict):
    messages: Annotated[list, add_messages]
    decision: str
    current_question: Annotated[str, "current_question"]
    current_choices: Annotated[list, "current_choices"]  
    correct_answer: Annotated[str, "correct_answer"]

# Create the graph
graph_builder = StateGraph(State)

# Add nodes
graph_builder.add_node("router", router)
graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("database", database_node)
graph_builder.add_node("answer_checker", answer_checker)

# Define conditional edges
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

graph_builder.add_edge("chatbot", END)
graph_builder.add_edge("database", END)
graph_builder.add_edge("answer_checker", END) #yo

# Compile the graph
memory = MemorySaver()
graph = graph_builder.compile(checkpointer=memory)

# Define answering function
def answering(user_input):
    """Handles user queries and processes responses from the AI."""
    config = {"configurable": {"thread_id": "1"}}

    user_message = {"role": "user", "content": user_input}


    # Ensure State is always initialized properly
    try:
        current_state = graph.get_state(config)
        state = {
            "messages": current_state.values.get("messages", []) + [user_message],
            "decision": "",
            "current_question": current_state.values.get("current_question", ""),
            "current_choices": current_state.values.get("current_choices", []),
            "correct_answer": current_state.values.get("correct_answer", "")
        }
    except:
        state = {
            "messages": [user_message],
            "decision": "",
            "current_question": "",
            "current_choices": [],
            "correct_answer": ""
        }

    events = graph.stream(state, config)

    assistant_response = "No response received."  # Default fallback response

    for event in events:
        for val in event.values():
            if isinstance(val, dict) and "messages" in val:
                if isinstance(val["messages"], list) and val["messages"]:
                    assistant_response = val["messages"][-1].content
                elif isinstance(val["messages"], AIMessage):
                    assistant_response = val["messages"].content

    print('DEBUG : Current Question:', state.get("current_question", ""))
    print('DEBUG : Current Choices:', state.get("current_choices", []))
    print('DEBUG : Correct Answer:', state.get("correct_answer", ""))
    
    print('AI:', assistant_response)

# png_data = graph.get_graph().draw_mermaid_png()

# png_path = "langgraph.png"
# with open(png_path, "wb") as f:
#     f.write(png_data)

# Start chatbot loop
print("Start chatting with the AI! Type '!exit' to quit.")
while True:
    query = input("You: ")
    if query.lower() == "!exit":
        print("Byebye")
        break
    answering(query)
