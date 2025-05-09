extends Node

const SNEAKING_STEALTH_MODIFIER: float = 0.6
# By how much does global alertness influence the player's detectability
const GLOBAL_ALERTNESS_WEIGHT: float = 0.3
const BASELINE_GLOBAL_ALERTNESS: float = 0.2
const OBSERVATION_SCORE_WEIGHT: float = 0.2

# Value ranging from 0.0 - 1.0,
#	either a global difficulty
var global_alertness_level: float = BASELINE_GLOBAL_ALERTNESS

var suspicion_level: float = 0.0
var player_position: Vector3 = Vector3.ZERO
var stealth_modifier: float = 1.0
# Whether or not the player can be seen
var can_be_seen: bool = true
var player_grace_elapsed: float = 0.0
const player_grace_period: float = 1.5

var player_observed_position: Vector3 = Vector3.INF
var player_observed_elapsed: float = 0.0
var player_observer_position: Vector3 = Vector3.INF

# TODO: remove
# Tracks the timestamp of every observation
#	check delta time, if under a minute, filter
#	length is number of observations in last minute
#	TODO: weight observations effect on global alertness by recency?
var observation_tracker: PackedFloat32Array = []
var observation_amnesia: float = 60.0

var in_encounter: bool = false

signal change_suspicion_level(new_level: float)
signal change_stealth_level(new_stealth: float)
signal change_global_alertness(new_level: float)
signal set_all_suspicion_level(new_level: float)

func _ready() -> void:
	# TODO: use anonymous functions/lambdas instead, better
	#	to attach functionality in same area as the signal connection
	change_suspicion_level.connect(update_suspicion_level)
	change_stealth_level.connect(update_stealth_modifier)
	change_global_alertness.connect(update_global_alertness)
	set_all_suspicion_level.connect(_set_all_suspicion_level)
	
func observe_player(observed_player_position: Vector3, security_position: Vector3):
	player_observed_elapsed = 0.0
	player_observed_position = observed_player_position
	player_observer_position = security_position
	
func get_security() -> Array[Security]:
	var security_group: Array[Node] = get_tree().get_nodes_in_group("security")
	var security: Array[Security]
	security.assign(security_group)
	
	return security
	
func _set_all_suspicion_level(new_level: float):
	suspicion_level = new_level
	change_suspicion_level.emit(new_level)

func calculate_global_alertness() -> void:
	var global_alertness: float = BASELINE_GLOBAL_ALERTNESS
	
	# The more times the player has been recently observed, the higher this score is
	#	ranges from 0-number of units
	var observation_score: float = 0.0
	
	for time_since_observed in observation_tracker:
		observation_score += 1.0 - (time_since_observed / observation_amnesia)
	
	global_alertness += observation_score * OBSERVATION_SCORE_WEIGHT
	global_alertness = clamp(global_alertness, 0.0, 1.0)
	
	if global_alertness != global_alertness_level:
		change_global_alertness.emit(global_alertness)

func _process(delta: float) -> void:
	calculate_stealth_modifier()
	calculate_global_alertness()
	
	player_observed_elapsed += delta
	player_grace_elapsed += delta
	can_be_seen = player_grace_elapsed > player_grace_period
	
	var security: Array[Security] = get_security()
	if not security: return
	
	# Get maximum suspicion level of all enemies
	var max_sus_level: float = 0.0
	observation_tracker = []
	
	for unit in security:
		# Suspicion level calculation
		if unit.suspicion_level > max_sus_level:
			max_sus_level = unit.suspicion_level
			
		if unit.time_since_seen_player < observation_amnesia:
			observation_tracker.append(unit.time_since_seen_player)
			
	# Update suspicion level if changed
	if suspicion_level != max_sus_level:
		change_suspicion_level.emit(max_sus_level)
		
	if global_alertness_level > 0.6:
		for reinforcement in get_tree().get_nodes_in_group("reinforcement_group"):
			var reinforcement_point: ReinforcementPoint = reinforcement as ReinforcementPoint
			
			reinforcement_point.activate()

func update_suspicion_level(new_level: float):
	suspicion_level = new_level
	
func update_stealth_modifier(new_stealth: float):
	stealth_modifier = new_stealth
	
func update_global_alertness(new_level: float):
	global_alertness_level = new_level
	
func calculate_stealth_modifier():
	var current_stealth: float = 1.0
	
	current_stealth -= global_alertness_level * GLOBAL_ALERTNESS_WEIGHT
	
	if Input.is_action_pressed("sneak"):
		current_stealth += SNEAKING_STEALTH_MODIFIER
	
	if stealth_modifier != current_stealth: change_stealth_level.emit(current_stealth)

# Volume parameter describes how "severe" a sound is, where moving is of low interest,
#	but the player-made distraction is of maximum volume
func player_makes_sound(location: Vector3, hearing_range: float):
	var security: Array[Security] = get_security()
	if not security: return
	
	for unit in security:
		unit.process_distraction(location, hearing_range)
