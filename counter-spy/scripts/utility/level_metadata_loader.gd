extends Node

func load_level_metadata(metadata_path: String) -> LevelMetadata:
	# TODO: integration with AI system from here
	# TODO: level data loading should be abstracted to a script
	var level_dict = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	var level_metadata: LevelMetadata = LevelMetadata.new()
	level_metadata.description = level_dict["description"]
	level_metadata.name = level_dict["name"]
	level_metadata.objectives = []
	level_metadata.keywords = []
	for objective in level_dict["objectives"]:
		level_metadata.objectives.append(objective as String)
	for keyword in level_dict["keywords"]:
		level_metadata.keywords.append(keyword as String)
	
	level_metadata.setting = level_dict["setting"]
	level_metadata.topic = level_dict["topic"]
	
	var enemy_list = level_dict["enemyList"]
	
	for enemy in enemy_list:
		var enemy_metadata: EnemyMetadata = EnemyMetadata.new()
		
		enemy_metadata.name = enemy["name"]
		enemy_metadata.weakness = enemy["weakness"]
		enemy_metadata.id = str(enemy["enemyID"])
		
		level_metadata.enemy_list.append(enemy_metadata)
		level_metadata.enemies_by_id[enemy_metadata.id] = enemy_metadata
		
		print(level_metadata.enemies_by_id)
		
	return level_metadata
