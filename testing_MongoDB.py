import os
import unittest

from datetime import datetime, timezone
from langgraph.checkpoint.memory import MemorySaver
from langgraph.checkpoint.memory import MemorySaver
from typing import Optional
from pydantic import BaseModel
from langgraph.checkpoint.mongodb import MongoDBSaver
from pymongo import MongoClient

mongodb_uri = os.getenv("MONGODB_URI")
db_name = "SE-prog"

class UserProfile(BaseModel):
    """User profile information for personalization"""
    user_id: str
    name: Optional[str] = None
    user_preferences: Optional[str] = None
    interaction_style: Optional[str] = None
    updated_at: Optional[datetime] = None
    conversation_count: int = 0

def get_mongodb_connection():
    """Get MongoDB connection"""
    try:
        client = MongoClient(mongodb_uri)
        client.admin.command('ping')
        print("Connected to MongoDB")
        return client
    except Exception as e:
        print(f"Error connecting to MongoDB: {e}")
        return None

def mongodb_saver(client):
    """Create MongoDBSaver for checkpointing"""
    if client: 
        return MongoDBSaver(client)
    else:
        print("Using in memory saver as fallback")
        return MemorySaver()
    
mongo_client = get_mongodb_connection()
checkpointer = mongodb_saver(mongo_client)

def get_user_profile(user_id):
    """Get user profile from MongoDB"""
    if not mongo_client:
        return None
    
    db = mongo_client[db_name]
    collection = db["User-Profiles"]
    profile = collection.find_one({"user_id": user_id})
    if profile:
        return UserProfile(**profile)
    return None

def save_user_profile(profile: UserProfile):
    """Save user profile to MongoDB"""
    if not mongo_client:
        return False
    
    db = mongo_client[db_name]
    collection = db["User-Profiles"]
    
    profile.updated_at = datetime.now(timezone.utc)
    profile_dict = profile.model_dump()

    result = collection.update_one( #update one ere as to ensure there is only one profile per user
        {"user_id": profile.user_id},
        {"$set": profile_dict},
        upsert=True
    )

    return result.acknowledged

def save_conversation_summary(user_id, summary):
    """Save conversation summary to MongoDB"""
    if not mongo_client:
        return False
    
    db = mongo_client[db_name]
    collection = db["Convo-History"]

    convo_doc = {
        "user_id": user_id,
        "summary": summary,
        "created_at": datetime.now(timezone.utc)
    }

    result = collection.insert_one(convo_doc)
    return result.acknowledged

def get_recent_conversation(user_id, limit=4):
    """Get recent conversations from MongoDB"""
    if not mongo_client:
        return []
    db = mongo_client[db_name]
    collection = db["Convo-History"]

    conversation = list(collection.find(
        {"user_id" : user_id},
        sort=[("created_at", -1)],
        limit=limit
    ))

    return conversation

#Test saving a user profile to MongoDB
profile = UserProfile(
            user_id="test_user",
            name="Test User",
            user_preferences="Test Preferences",
            interaction_style="Friendly",
            updated_at=datetime.now(timezone.utc),
            conversation_count=1
        )
result = save_user_profile(profile)
print(result)

#Test retrieving a user profile from MongoDB
retrieved_profile = get_user_profile("test_user")
print(retrieved_profile)

#Test saving a conversation summary to MongoDB
result = save_conversation_summary("test_user", "Summary 1.")
result = save_conversation_summary("test_user", "Summary 2.")
result = save_conversation_summary("test_user", "Summary 3.")
result = save_conversation_summary("test_user", "Summary 4.")
result = save_conversation_summary("test_user", "Summary 5.")
print(result)

#Test retrieving recent conversations from MongoDB
conversations = get_recent_conversation("test_user")
print(conversations)
