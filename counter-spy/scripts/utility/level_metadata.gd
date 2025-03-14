class_name LevelMetadata

var name: String
var objectives: Array[String]
var keywords: Array[String]
var description: String
var setting: String
var topic: String # NOTE: would be enum if they worked well in godot
var enemy_list: Array[EnemyMetadata]
var enemies_by_id: Dictionary[String, EnemyMetadata]
