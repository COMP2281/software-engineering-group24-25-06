extends Node3D

@export var proto_controller: ProtoController
@onready var response: Label3D = $Response
@onready var line_edit: LineEdit = $CanvasLayer/LineEdit

# TODO: make labels auto-face player
# TODO: look-at code abstracted for security cameras

var http_request: HTTPRequest

func show_ui():
	$CanvasLayer.show()
	
func hide_ui():
	$CanvasLayer.hide()

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed) #signal emitted when request is done
	
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
	line_edit.visible = false
	response.text = "Hi, I'm BonsAI"
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json==null:
		response.text = " Invalid response from server!"
		return
		
	if json.has("message"): #For GET
		response.text = json["message"]
	elif json.has("status") and json.has("received"): #For POST
		print("Server received our message: ", json["received"])
		response.text = json["received"]
	
func _on_LineEdit_text_entered(text):
	print("Typed message: ", text)
	
	var url = "http://127.0.0.1:8000/" #"http://ai_int.skyecarroll.com"
	var headers = ["Content-Type: application/json"]
	var json_data = JSON.stringify({"content": text})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("An error has occured when sending the message")
		
	proto_controller.can_move = true
	line_edit.visible = false
	line_edit.text = ""
	
func _process(delta: float) -> void:
	var vector_to_bonsai: Vector3 = (global_position - proto_controller.global_position).normalized()
	var look_vector: Vector3 = proto_controller.get_look_vector()
	
	var similarity: float = look_vector.dot(vector_to_bonsai)
	
	# Sufficiently high dot product means they're parallel (normalised)?
	if similarity > 0.8:
		$Label3D.show()
		
		if Input.is_action_pressed("interact"):
			proto_controller.can_move = false
			proto_controller.mouse_captured = false
			line_edit.visible = true
			if line_edit.visible:
				line_edit.grab_focus()
			
	else:
		$Label3D.hide()
