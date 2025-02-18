import socket
import threading
import json

class TCPServer:
    def __init__(self , host="localhost", port=5001):
        self.server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server.bind((host, port))
        self.server.listen(1)
        self.client = None #Single client for now
        self.client_address = None

    def start(self):
        print("Server started")
        self.client, self.client_address = self.server.accept()
        print(f"Client: {self.client}")
        print(f"Client connected from: {self.client_address}")
        
        receive_thread = threading.Thread(target=self.receive_messages)
        receive_thread.daemon = True #Ensures that the thread will not prevent the program from exiting if main thread finishes execution.
        receive_thread.start()

        self.handle_input()

    def receive_messages(self):
        while True:
            try:
                message = self.client.recv(1024).decode()
                if message:
                    print(f"Received message from Godot: {message}")
            except Exception as e:
                print(f"Error: {e}")
                break
    
    def handle_input(self):
        while True:
            try:
                message = input("Enter message to send to Godot (!quit to exit): ")

                if message.lower() == "!quit":
                    print("Quitting server")
                    break

                if self.client:
                    json_data = json.dumps(message) #JSON formatted string (adds double quotes and escaping any special chars in string).
                    print(f"Sending JSON: {json_data}")
                    bytes_sent = self.client.send(json_data.encode())
                    print(f"Bytes sent: {bytes_sent}")
                else:
                    print("No client connected")

            except Exception as e:
                print(f"Error: {e}")
                break

if __name__ == "__main__":
    server = TCPServer()
    server.start()
