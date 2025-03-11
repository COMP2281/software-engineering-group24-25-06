extends Control

func _ready():
	self.visible = false
	#print("TransitionScreen is ready.")
#
	#var anim_player = $AnimationPlayer  # Adjust path if needed
	#anim_player.get_parent().get_node("ColorRect").color = Color(0, 0, 0, 1)  # Fully opaque black
	#
	##print("AnimationPlayer found:", anim_player)
##
	### Play animation on start to test if it's working
	##anim_player.play("fade_in_to_loading_screen")
	#anim_player.play("fade_out_to_level")
	#await get_tree().create_timer(0.5).timeout

	#print("TransitionScreen visibility:", self.visible)
#
	pass
	#print("Attempting to play animation: fade_out_to_loading_screen")
