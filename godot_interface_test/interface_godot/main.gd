extends Node3D

var client = StreamPeerTCP.new()

func _ready() -> void:
	$DisplayBoardText.text = "CounterTime"
	connect_to_server()
	
func connect_to_server():
	var ip = "localhost" 
	var port = 5001
	
	var error = client.connect_to_host(ip, port)
	
func _process(_delta):
	client.poll() #Fixed issue -> Need to poll to update the state.
	var status = client.get_status()

	if status == StreamPeerTCP.STATUS_CONNECTED:
		#send("") #Simple test to show messages can be sent to python server (will infinitely loop for now)
		var available_bytes = client.get_available_bytes()
		if available_bytes > 0 :
			print("Available bytes: ", available_bytes)
			var data = client.get_partial_data(available_bytes)
			print("Received data: ", data[1])
			var decoded_data = data[1].get_string_from_ascii()
			decoded_data = decoded_data.trim_prefix("\"").trim_suffix("\"") #JSON format
			print("Decoded data: ",decoded_data)
			$DisplayBoardText.text = decoded_data

	else:
		print("Lost connection!")
		$DisplayBoardText.text = "Lost connection to server!"	

func send(data): #data needs to be PackedByteArray type
	client.poll()

	var test_string = "Hello from Godot"
	var encoded_string = test_string.to_ascii_buffer()
	print("Encoded string: ", encoded_string)
	var error = client.put_data(encoded_string)

	if error != OK:
		print("Error writing to stream: ", error)
	
func _input(event):
	if event.is_action_pressed("test_action"):
		$DisplayBoardText.modulate = Color.DARK_GREEN
	
	if event.is_action_released("test_action"):
		$DisplayBoardText.modulate = Color.BLACK
