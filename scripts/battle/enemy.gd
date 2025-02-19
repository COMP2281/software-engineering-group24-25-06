extends CharacterBody3D

var health = 100
var max_health = 100
var weakness = "fire"  
var active = false 
signal health_change(new_health)

func _ready():
	position = Vector3(3, 1, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("e74c3c")  
	material.emission_enabled = true
	material.emission = Color("f1948a") 
	material.emission_energy_multiplier = 0.5
	$MeshInstance3D.material_override = material

func take_damage(amount):
	health -= amount
	health = max(0, health)
	health_change.emit(health)
	
func reveal_weakness():
	return weakness
