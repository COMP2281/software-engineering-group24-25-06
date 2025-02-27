from fastapi import FastAPI, requests
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Union, Any
import uvicorn

#Built on async patterns, works well with Uvicron to serve 😩 (ASGI server)
#Dont have to manually jsonify the response, FastAPI automaticaally handles the conversion of Python dictionaries to JSON responses.
#When you return a dict -> convert to JSON -> sets content type to application/json -> returns proper HTTP response
#Automatic documentation too
app = FastAPI()

#Cross-Origin Resource Sharing (CORS) is a security feature that prevents websites from making requests to domain different from the one that served the website.
#This is here just for an extra layer that processes the requests and responses before route handlers are called. 
# (* menas all so basically means "OK for any website to make requests to this server")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

counter = 0

#(Automatic) Defining the datamodel with validation. POST req comes -> parse into model -> validate (i.e. has content field which can be string or any other value)
class MessageData(BaseModel):
    content: Union[str, Any]

#Route handles, one for GET and one for POST
@app.get("/")
async def get_counter():
    """Handle GET requests by incrementing and returning the counter"""
    global counter 
    counter += 1

    response = { 
        "message": f"Hello your new number is {counter}"
    }

    print(f"Sent response: {response}")
    return response

@app.post("/")
async def receive_message(data: MessageData):
    """Handle POST requests by echoing the message"""
    
    print(f"Received message: {data.content}")
    content = data.content

    return { "status": "success", "received": content }

if __name__ == "__main__":
    print("Starting server")
    uvicorn.run(app, host="127.0.0.1", port=8000)