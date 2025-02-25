## TODO: both of these scripts should be purely visual stuff basically
##	and instead we handle most of everything in battle.gd
class_name EnemyBattle extends CharacterBody3D

@export_color_no_alpha var enemy_color: Color = Color("e74c3c")  
@export_color_no_alpha var emission_color: Color = Color("f1948a")
var enemy_resource: EnemyResource = null

signal health_change(new_health: float)

func _ready():
	position = Vector3(3, 1, 0)
	
	var material = StandardMaterial3D.new()
	material.albedo_color = enemy_color
	material.emission_enabled = true
	material.emission = emission_color
	material.emission_energy_multiplier = 0.5
	$MeshInstance3D.material_override = material
	
	health_change.connect(on_health_change)
	
func on_health_change(health_change: float) -> void:
	print("Visual stuff here!")

func reveal_weakness():
	return enemy_resource.weakness
