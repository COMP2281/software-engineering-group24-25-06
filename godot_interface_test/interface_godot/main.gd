extends Node3D

@onready var line_edit: LineEdit = $CanvasLayer/LineEdit
var client = StreamPeerTCP.new()

func _ready() -> void:
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	line_edit.visible = false
	$DisplayBoardText.text = "CounterTime"
	connect_to_server()
	
func connect_to_server():
	var ip = "127.0.0.1"
	var port = 5011
	
	var error = client.connect_to_host(ip, port)
	print(error)
	OS.delay_msec(500)
	
	client.poll()
	if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		print("Failed to establish connection")
		$DisplayBoardText.text = "Failed to establish connection!"
	
func _process(_delta):
	client.poll() #Fixed issue -> Need to poll to update the state.
	var status = client.get_status()

	if status == StreamPeerTCP.STATUS_CONNECTED:
		send("") #Simple test to show messages can be sent to python server (will infinitely loop for now)
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
	
func _on_LineEdit_text_entered(text):
	print("Typed message: ", text)
	$ProtoController.can_move = true
	line_edit.visible = false
	line_edit.text = ""
	

func send(data): #data needs to be PackedByteArray type
	client.poll()

	var test_string = "Hello from Godot"
	var encoded_string = test_string.to_ascii_buffer()
	print("Encoded string: ", encoded_string)
	var error = client.put_data(encoded_string)

	if error != OK:
		print("Error writing to stream: ", error)
	
func _input(event):
	if event.is_action_pressed("typing"):
		$ProtoController.can_move = false
		$ProtoController.mouse_captured = false 
		line_edit.visible = true
		if line_edit.visible:
			line_edit.grab_focus()

	if event.is_action_pressed("test_action"):
		$DisplayBoardText.modulate = Color.DARK_GREEN
	
	if event.is_action_released("test_action"):
		$DisplayBoardText.modulate = Color.BLACK
		
