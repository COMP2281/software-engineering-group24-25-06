extends Node

func load_level_metadata(metadata_path: String) -> LevelMetadata:
	# TODO: integration with AI system from here
	# TODO: level data loading should be abstracted to a script
	var level_dict = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	var level_metadata: LevelMetadata = LevelMetadata.new()
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
		
	return level_metadata
