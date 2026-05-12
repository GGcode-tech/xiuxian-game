## 地图数据 - 运行时地图状态（Autoload版本）
extends Node

# 内部类
class Territory:
	var id: String = ""
	var name: String = ""
	var position: Vector2 = Vector2.ZERO
	var type: String = "plains"
	var owner_id: String = ""
	var resources: Dictionary = {}
	var buildings: Array[String] = []
	var power_bonus: int = 0
	var danger_level: int = 0

	func serialize() -> Dictionary:
		return {"id": id, "name": name, "position": {"x": position.x, "y": position.y},
			"type": type, "owner_id": owner_id, "resources": resources,
			"buildings": buildings, "power_bonus": power_bonus, "danger_level": danger_level}

	func deserialize(data: Dictionary) -> void:
		id = data.get("id", "")
		name = data.get("name", "")
		var pos = data.get("position", {})
		position = Vector2(pos.get("x", 0.0), pos.get("y", 0.0))
		type = data.get("type", "plains")
		owner_id = data.get("owner_id", "")
		resources = data.get("resources", {})
		buildings = data.get("buildings", [])
		power_bonus = data.get("power_bonus", 0)
		danger_level = data.get("danger_level", 0)


class Sect:
	var id: String = ""
	var name: String = ""
	var level: int = 1
	var relation_with_player: float = 0.0
	var specialties: Array[String] = []
	var quests: Array[Dictionary] = []

	func serialize() -> Dictionary:
		return {"id": id, "name": name, "level": level,
			"relation_with_player": relation_with_player,
			"specialties": specialties, "quests": quests}

	func deserialize(data: Dictionary) -> void:
		id = data.get("id", "")
		name = data.get("name", "")
		level = data.get("level", 1)
		relation_with_player = data.get("relation_with_player", 0.0)
		specialties = data.get("specialties", [])
		quests = data.get("quests", [])


class ResourceNode:
	var id: String = ""
	var territory_id: String = ""
	var type: String = ""
	var remaining: int = 100
	var max_amount: int = 500
	var regen_rate: int = 1

	func harvest(amount: int) -> int:
		var actual = mini(amount, remaining)
		remaining -= actual
		return actual

	func serialize() -> Dictionary:
		return {"id": id, "territory_id": territory_id, "type": type,
			"remaining": remaining, "max_amount": max_amount, "regen_rate": regen_rate}

	func deserialize(data: Dictionary) -> void:
		id = data.get("id", "")
		territory_id = data.get("territory_id", "")
		type = data.get("type", "")
		remaining = data.get("remaining", 100)
		max_amount = data.get("max_amount", 500)
		regen_rate = data.get("regen_rate", 1)


var territories_data: Dictionary = {}
var sects_data: Dictionary = {}
var resource_nodes_data: Dictionary = {}
var active_events: Array = []
var event_history: Array = []


func _ready() -> void:
	print("[MapData] 初始化")


func initialize() -> void:
	_generate_initial_territories()
	_generate_sects()
	_generate_resource_nodes()


func _generate_initial_territories() -> void:
	for i in range(5):
		for j in range(5):
			var t = Territory.new()
			t.id = "territory_%d_%d" % [i, j]
			t.position = Vector2(i * 100.0, j * 100.0)
			t.name = "区域 %d-%d" % [i + 1, j + 1]
			t.type = _get_random_type(["plains", "forest", "mountain", "lake", "desert"])
			t.resources = _gen_resources(t.type)
			territories_data[t.id] = t


func _get_random_type(types: Array) -> String:
	return types[randi() % types.size()]


func _gen_resources(type: String) -> Dictionary:
	match type:
		"plains": return {"spirit_grass": randi_range(5, 20)}
		"forest": return {"spirit_grass": randi_range(10, 30), "spirit_wood": randi_range(5, 15)}
		"mountain": return {"spirit_ore": randi_range(10, 40), "spirit_stone": randi_range(50, 200)}
		"lake": return {"water_essence": randi_range(5, 20), "fish": randi_range(20, 50)}
		"desert": return {"fire_essence": randi_range(5, 15), "spirit_sand": randi_range(10, 30)}
	return {}


func _generate_sects() -> void:
	var names = ["青云门", "天剑宗", "玄天阁", "丹鼎宗", "御兽门"]
	for i in names.size():
		var s = Sect.new()
		s.id = "sect_%d" % i
		s.name = names[i]
		s.level = randi_range(1, 5)
		s.relation_with_player = randf_range(-0.2, 0.2)
		sects_data[s.id] = s


func _generate_resource_nodes() -> void:
	for tid in territories_data:
		for k in range(randi_range(1, 3)):
			var n = ResourceNode.new()
			n.id = "node_%s_%d" % [tid, k]
			n.territory_id = tid
			n.type = _get_random_type([
			"spirit_grass_depot", "spirit_wood_depot",
			"spirit_mine", "spirit_spring", "fire_vein"
		])
			n.remaining = randi_range(100, 500)
			n.max_amount = n.remaining + 100
			resource_nodes_data[n.id] = n


func get_territory(id: String) -> Territory:
	return territories_data.get(id, null)


func get_sect(id: String) -> Sect:
	return sects_data.get(id, null)


func get_resource_node(id: String) -> ResourceNode:
	return resource_nodes_data.get(id, null)


func serialize() -> Dictionary:
	var td = {}
	for k in territories_data:
		td[k] = territories_data[k].serialize()
	var sd = {}
	for k in sects_data:
		sd[k] = sects_data[k].serialize()
	var nd = {}
	for k in resource_nodes_data:
		nd[k] = resource_nodes_data[k].serialize()
	return {"territories": td, "sects": sd, "resource_nodes": nd,
		"active_events": active_events, "event_history": event_history}
