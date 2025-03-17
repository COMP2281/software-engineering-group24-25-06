extends Node3D

@export var proto_controller: ProtoController = null
@export var similarity_threshold: float = 0.9

@onready var response: Label3D = $Response
@onready var line_edit: LineEdit = $CanvasLayer/BonsUI/PanelContainer/LineEdit
@onready var bons_ui: CanvasLayer = $CanvasLayer

# TODO: make labels auto-face player

var http_request: HTTPRequest

func show_ui():
	pass
	
func hide_ui():
	pass

func _ready():
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed) #signal emitted when request is done
	
	line_edit.text_submitted.connect(_on_LineEdit_text_entered)
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
	
	if proto_controller != null:
		proto_controller.set_all_inputs(true)
		
	bons_ui.hide()
	line_edit.text = ""
	response.text = "Processing..."
	
func _process(delta: float) -> void:
	var vector_to_bonsai: Vector3
	var look_vector: Vector3
	
	if proto_controller != null:
		vector_to_bonsai = (global_position - proto_controller.head.global_position).normalized()
		look_vector = proto_controller.get_look_vector()
	
	var similarity: float = look_vector.dot(vector_to_bonsai)
	
	# Sufficiently high dot product means they're parallel (normalised)?
	if similarity >= similarity_threshold:
		$Label3D.show()
		
		if Input.is_action_pressed("bonsai_talk"):
			if proto_controller != null:
				proto_controller.set_all_inputs(false)

			bons_ui.show()
			line_edit.grab_focus()
			
	else:
		$Label3D.hide()
