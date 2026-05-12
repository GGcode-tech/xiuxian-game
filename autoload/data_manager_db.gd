## DataManagerDB - 管理game_database.json的查询方法
## 从data_manager.gd拆分出来
extends RefCounted


func get_data(key: String):
	var db = _load_game_database()
	return db.get(key, {})


func get_sects() -> Dictionary:
	var db = _load_game_database()
	return db.get("sects", {})


func get_dungeons() -> Dictionary:
	var db = _load_game_database()
	return db.get("dungeons", {})


func get_daily_activities() -> Dictionary:
	var db = _load_game_database()
	return db.get("daily_activities", {})


func get_spirit_beasts() -> Dictionary:
	var db = _load_game_database()
	return db.get("spirit_beasts", {})


func get_equipment_sets() -> Dictionary:
	var db = _load_game_database()
	return db.get("equipment_sets", {})


func _load_game_database() -> Dictionary:
	var db_path = "res://data/game_database.json"
	if not FileAccess.file_exists(db_path):
		return {}

	var file = FileAccess.open(db_path, FileAccess.READ)
	if not file:
		return {}

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		return {}

	return json.data if json.data is Dictionary else {}
