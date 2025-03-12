extends Node3D

@onready var line_edit = $CanvasLayer/LineEdit
@onready var display_board = $DisplayBoardText

#HTTP request node reference then actually create it on ready
var http_request: HTTPRequest

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed) #signal emitted when request is done
	
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	line_edit.visible = false
	display_board.text = "CounterTime"
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json==null:
		display_board.text = " Invalid response from server!"
		return
		
	if json.has("message"): #For GET
		display_board.text = json["message"]
	elif json.has("status") and json.has("received"): #For POST
		print("Server received our message: ", json["received"])
	
func _on_LineEdit_text_entered(text):
	print("Typed message: ", text)
	
	var url = "http://127.0.0.1:8000/" #"http://ai_int.skyecarroll.com"
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify({"content": text})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("An error has occured when sending the message")
		
	$ProtoController.can_move = true
	line_edit.visible = false
	line_edit.text = ""
	
func _input(event):
	if event.is_action_pressed("typing"):
		$ProtoController.can_move = false
		$ProtoController.mouse_captured = false
		line_edit.visible = true
		if line_edit.visible:
			line_edit.grab_focus()
	
	if event.is_action_pressed("test_action"):
		$DisplayBoardText.modulate = Color.DARK_GREEN
	if event.is_action_pressed("test_action"):
		$DisplayBoardText.modulate = Color.BLACK

func _on_button_pressed():
	var url = "http://127.0.0.1:8000/" #"http://ai_int.skyecarroll.com"
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_GET)
