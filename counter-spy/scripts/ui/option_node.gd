extends Control

@export var option_name: String
@export var option_default: String
@export var input_map_name: String

@export_color_no_alpha var background_color: Color
@export_color_no_alpha var background_hover_color: Color

# TODO: functionality
var is_hovering: bool = false
var displayed_value: String = ""

func _ready() -> void:
	$HBoxContainer/InputName.text = option_name
	$HBoxContainer/Container/Keybind.text = option_default
	$HBoxContainer/Container/ColorRect.color = background_color
	displayed_value = option_default
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_hovering: return
	
	if event is InputEventKey:
		if event.pressed:
			var key_name: String = event.as_text_key_label()
			
			InputMap.action_erase_events(input_map_name)
			InputMap.action_add_event(input_map_name, event)
			
			$HBoxContainer/Container/Keybind.text = key_name
			displayed_value = key_name
			
func on_hover_enter() -> void:
	is_hovering = true
	$HBoxContainer/Container/ColorRect.color = background_hover_color
	$HBoxContainer/Container/Keybind.text = "Press key..."
	
func on_hover_exit() -> void:
	is_hovering = false
	$HBoxContainer/Container/ColorRect.color = background_color
	$HBoxContainer/Container/Keybind.text = displayed_value

func _on_mouse_entered() -> void:
	on_hover_enter()

func _on_mouse_exited() -> void:
	on_hover_exit()

func _on_focus_entered() -> void:
	on_hover_enter()

func _on_focus_exited() -> void:
	on_hover_exit()
