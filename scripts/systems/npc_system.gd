## NPC系统 - 管理修仙世界中的所有NPC
## 原12部小说角色统一为世界NPC
extends Node

# NPC数据结构
# {
#   "id": "npc_xxx",
#   "name": "韩立",
#   "source": "凡人修仙传",
#   "realm_id": "realm_huashen",
#   "sect_id": "sect_chen",
#   "personality": "沉稳谨慎",
#   "dialogue_pool": [...],
#   "relationship": 0,  # -100~100
#   "is_alive": true,
#   "location": "world_main"
# }

var _npcs: Dictionary = {}
var _npc_by_source: Dictionary = {}  # 按来源分组

func _ready() -> void:
	_load_npcs()

func _load_npcs() -> void:
	# 从统一数据库加载所有NPC
	var db_path = "res://data/game_database.json"
	if not FileAccess.file_exists(db_path):
		push_warning("[NPCSystem] game_database.json not found")
		return
	
	var file = FileAccess.open(db_path, FileAccess.READ)
	if not file:
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json_obj = JSON.new()
	if json_obj.parse(json_text) != OK:
		push_warning("[NPCSystem] JSON parse error")
		return
	
	var db = json_obj.data
	var characters = db.get("characters", {})
	
	for source_name in characters:
		var char_list = characters[source_name]
		_npc_by_source[source_name] = []
		
		for char_data in char_list:
			var npc = _create_npc(char_data, source_name)
			_npcs[npc["id"]] = npc
			_npc_by_source[source_name].append(npc["id"])
	
	print("[NPCSystem] 加载完成，NPC总数: %d" % _npcs.size())

func _create_npc(data: Dictionary, source: String) -> Dictionary:
	return {
		"id": "npc_%s_%s" % [source, data.get("name", "unknown")],
		"name": data.get("name", "无名"),
		"source": source,
		"realm_id": data.get("realm_id", "realm_lianqi"),
		"realm_exp": data.get("realm_exp", 0),
		"sect_id": data.get("sect_id", ""),
		"personality": data.get("personality", ""),
		"description": data.get("description", ""),
		"dialogue_pool": data.get("dialogue", []),
		"relationship": 0,
		"is_alive": true,
		"location": data.get("location", "world_main"),
		"base_stats": data.get("base_stats", {}),
		"items": data.get("items", []),
		"techniques": data.get("techniques", []),
	}

# 获取所有NPC
func get_all_npcs() -> Dictionary:
	return _npcs

# 按ID获取NPC
func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {})

# 按来源获取NPC列表
func get_npcs_by_source(source: String) -> Array:
	var ids = _npc_by_source.get(source, [])
	var result = []
	for id in ids:
		if _npcs.has(id):
			result.append(_npcs[id])
	return result

# 按境界获取NPC列表
func get_npcs_by_realm(realm_id: String) -> Array:
	var result = []
	for npc in _npcs.values():
		if npc.get("realm_id", "") == realm_id:
			result.append(npc)
	return result

# 按门派获取NPC列表
func get_npcs_by_sect(sect_id: String) -> Array:
	var result = []
	for npc in _npcs.values():
		if npc.get("sect_id", "") == sect_id:
			result.append(npc)
	return result

# 搜索NPC（名字匹配）
func search_npcs(keyword: String) -> Array:
	var result = []
	for npc in _npcs.values():
		if npc.get("name", "").find(keyword) >= 0 or npc.get("description", "").find(keyword) >= 0:
			result.append(npc)
	return result

# 获取NPC对话
func get_npc_dialogue(npc_id: String) -> String:
	var npc = get_npc(npc_id)
	if npc.is_empty():
		return ""
	
	var pool = npc.get("dialogue_pool", [])
	if pool.is_empty():
		return "..."
	
	return pool[randi() % pool.size()]

# 修改与NPC的关系
func change_relationship(npc_id: String, amount: int) -> void:
	if _npcs.has(npc_id):
		_npcs[npc_id]["relationship"] = clampi(_npcs[npc_id]["relationship"] + amount, -100, 100)

# 获取NPC总数
func get_npc_count() -> int:
	return _npcs.size()

# 获取所有来源列表
func get_all_sources() -> Array:
	return _npc_by_source.keys()
