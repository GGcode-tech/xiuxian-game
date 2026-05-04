## 存档管理器 - 处理游戏存档和读取
extends Node

const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"
const AUTO_SAVE_SLOT = "auto"

var _save_slots: Array[Dictionary] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	refresh_save_slots()
	print("[SaveManager] 初始化完成")


func save_game(slot: String) -> bool:
	var save_data = _build_save_data()
	var file = FileAccess.open(SAVE_DIR + slot + SAVE_EXTENSION, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] 无法创建存档文件: " + str(FileAccess.get_open_error()))
		return false
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	refresh_save_slots()
	print("[SaveManager] 存档成功: %s" % slot)
	return true


func load_game(slot: String) -> bool:
	var file = FileAccess.open(SAVE_DIR + slot + SAVE_EXTENSION, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] 无法读取存档文件")
		return false
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[SaveManager] 存档解析失败: " + json.get_error_message())
		return false
	var save_data = json.data
	if not _check_version_compatibility(save_data.get("version", "0.1.0")):
		push_error("[SaveManager] 存档版本不兼容")
		return false
	_restore_game_state(save_data)
	refresh_save_slots()
	print("[SaveManager] 读档成功: %s" % slot)
	return true


func delete_save(slot: String) -> bool:
	var file_path = SAVE_DIR + slot + SAVE_EXTENSION
	if FileAccess.file_exists(file_path):
		var err = DirAccess.remove_absolute(file_path)
		if err == OK:
			refresh_save_slots()
			print("[SaveManager] 删除存档: %s" % slot)
			return true
		else:
			push_error("[SaveManager] 删除存档失败")
			return false
	return false


func auto_save() -> void:
	save_game(AUTO_SAVE_SLOT)


func refresh_save_slots() -> void:
	_save_slots.clear()
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(SAVE_EXTENSION):
				var slot_name = file_name.replace(SAVE_EXTENSION, "")
				var info = get_save_info(slot_name)
				if not info.is_empty():
					_save_slots.append(info)
			file_name = dir.get_next()
		dir.list_dir_end()
	_save_slots.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))


func get_save_info(slot: String) -> Dictionary:
	var file_path = SAVE_DIR + slot + SAVE_EXTENSION
	if not FileAccess.file_exists(file_path):
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	var data = json.data
	return {
		"slot": slot,
		"version": data.get("version", "unknown"),
		"timestamp": data.get("timestamp", 0),
		"time_text": data.get("time_text", ""),
		"game_time": data.get("game_time", {}),
		"family_name": data.get("family_name", ""),
		"character_count": data.get("character_count", 0)
	}


func get_save_slots() -> Array[Dictionary]:
	return _save_slots


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(SAVE_DIR + slot + SAVE_EXTENSION)


func _check_version_compatibility(version: String) -> bool:
	var current = ProjectSettings.get_setting("application/config/version", "0.1.0")
	var current_parts = current.split(".")
	var save_parts = version.split(".")
	if current_parts.size() >= 1 and save_parts.size() >= 1:
		return current_parts[0] == save_parts[0]
	return true


# ==================== 子系统数据存储（供各系统使用）====================

# 临时存储各系统数据（实际存储在存档中）
var _subsystem_data: Dictionary = {}


func set_data(key: String, value) -> void:
	_subsystem_data[key] = value


func get_data(key: String):
	return _subsystem_data.get(key, null)


func has_data(key: String) -> bool:
	return _subsystem_data.has(key)


func clear_data(key: String) -> void:
	_subsystem_data.erase(key)


func _build_save_data() -> Dictionary:
	var player_family = GameManager.get_player_family()
	return {
		"version": ProjectSettings.get_setting("application/config/version", "0.1.0"),
		"timestamp": Time.get_unix_time_from_system(),
		"time_text": GameManager.get_formatted_time(),
		"game_time": GameManager.game_time.duplicate(),
		"game_speed": GameManager.game_speed,
		"family_name": player_family.get("name", "") if player_family else "",
		"player_family_id": GameManager.player_family_id,
		"character_count": GameManager.all_characters.size(),
		"characters": _serialize_characters(),
		"families": _serialize_families(),
		"world_state": _serialize_world(),
		"subsystems": _subsystem_data.duplicate(),
	}


func _serialize_characters() -> Array:
	var result: Array = []
	for char_id in GameManager.all_characters:
		result.append(GameManager.all_characters[char_id].duplicate())
	return result


func _serialize_families() -> Array:
	var result: Array = []
	for family_id in GameManager.all_families:
		result.append(GameManager.all_families[family_id].duplicate())
	return result


func _serialize_world() -> Dictionary:
	var map = GameManager.map_data
	if map is Dictionary:
		return {"map_data": map.duplicate()}
	return {"map_data": {}}


func _restore_game_state(data: Dictionary) -> void:
	GameManager.game_time = data.get("game_time", {"year": 1, "month": 1, "day": 1}).duplicate()
	GameManager.game_speed = data.get("game_speed", 1.0)
	GameManager.player_family_id = data.get("player_family_id", "")

	GameManager.all_characters.clear()
	GameManager.all_families.clear()

	for char_data in data.get("characters", []):
		if char_data is Dictionary and char_data.get("id", ""):
			GameManager.all_characters[char_data["id"]] = char_data

	for family_data in data.get("families", []):
		if family_data is Dictionary and family_data.get("id", ""):
			GameManager.all_families[family_data["id"]] = family_data

	var world_data = data.get("world_state", {})
	if world_data is Dictionary and not world_data.is_empty():
		GameManager.map_data = world_data.get("map_data", {})

	# 恢复子系统数据
	_subsystem_data = data.get("subsystems", {}).duplicate()