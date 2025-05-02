extends Control

func _ready():
	# Hide the transition screen initially
	self.visible = false

	# Example setup for debugging or animation testing (optional)

	# var anim_player = $AnimationPlayer  # Reference to the AnimationPlayer node
	# anim_player.get_parent().get_node("ColorRect").color = Color(0, 0, 0, 1)  # Set background to fully opaque black
	
	# Debug print to confirm AnimationPlayer is found
	# print("AnimationPlayer found:", anim_player)

	# Play a fade animation at startup (for testing purposes)
	# anim_player.play("fade_in_to_loading_screen")
	# anim_player.play("fade_out_to_level")

	# Optional delay for animation timing test
	# await get_tree().create_timer(0.5).timeout
	
	# Debug print to confirm visibility status
	# print("TransitionScreen visibility:", self.visible)
