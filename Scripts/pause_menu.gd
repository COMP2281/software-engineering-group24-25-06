extends Control

func _ready():
	$AnimationPlayer.play('RESET')
	self.visible = false


func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards('blur')
	self.visible = false
	
func pause():
	get_tree().paused = true
	$AnimationPlayer.play('blur')
	self.visible = true
	

	
func TestEsc():
	if Input.is_action_just_pressed('Escape'):
		if get_tree().paused:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()


func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _process(delta):
	TestEsc()
