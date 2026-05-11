## 物品实例类 - 运行时物品实例
class_name ItemInstance extends Resource

var item_id: String = ""
var count: int = 1
var quality: int = 0           # 品质等级（随机生成时）
var durability: float = 100.0  # 耐久度（装备）
var enhanced: int = 0          # 强化等级
var modifiers: Array[Dictionary] = []  # 随机词缀


func _init(item_id: String = "", count: int = 1) -> void:
	self.item_id = item_id
	self.count = count


func get_item_data():
	return DataManager.get_item(item_id)


func get_item_name() -> String:
	var data = get_item_data()
	if data:
		return data.name
	return item_id


func get_display_name() -> String:
	var name = get_item_name()

	if enhanced > 0:
		name += " +%d" % enhanced

	return name


func get_total_stats() -> Dictionary:
	var data = get_item_data()
	if not data:
		return {}

	var stats = data.equip_stats.duplicate()

	# 强化加成
	if enhanced > 0:
		for stat in stats:
			stats[stat] = int(stats[stat] * (1 + enhanced * 0.1))

	# 词缀加成
	for modifier in modifiers:
		var stat = modifier.get("stat", "")
		var value = modifier.get("value", 0)
		if stats.has(stat):
			stats[stat] += value
		else:
			stats[stat] = value

	return stats


func damage(amount: float) -> bool:
	durability -= amount
	if durability <= 0:
		return true  # 物品损坏
	return false


func repair(amount: float) -> void:
	durability = mini(durability + amount, 100.0)


func enhance(success_rate: float) -> bool:
	if randf() <= success_rate:
		enhanced += 1
		return true

	# 强化失败，可能降级或损坏
	if randf() < 0.3:
		enhanced = maxi(0, enhanced - 1)
	return false


func serialize() -> Dictionary:
	return {
		"item_id": item_id,
		"count": count,
		"quality": quality,
		"durability": durability,
		"enhanced": enhanced,
		"modifiers": modifiers
	}


func deserialize(data: Dictionary) -> void:
	item_id = data.get("item_id", "")
	count = data.get("count", 1)
	quality = data.get("quality", 0)
	durability = data.get("durability", 100.0)
	enhanced = data.get("enhanced", 0)
	modifiers = data.get("modifiers", [])


static func create(item_id: String, count: int = 1):
	var instance = ItemInstance.new(item_id, count)

	# 随机生成词缀（高级装备）
	var data = instance.get_item_data()
	if data and data.quality >= ItemData.ItemQuality.RARE:
		instance._generate_modifiers(data)

	return instance


func _generate_modifiers(data) -> void:
	var modifier_count = 0
	match data.quality:
		ItemData.ItemQuality.RARE:
			modifier_count = randi_range(1, 2)
		ItemData.ItemQuality.EPIC:
			modifier_count = randi_range(2, 3)
		ItemData.ItemQuality.LEGENDARY:
			modifier_count = randi_range(3, 4)
		ItemData.ItemQuality.IMMORTAL:
			modifier_count = randi_range(4, 6)

	var possible_modifiers = [
		{"stat": "attack", "min": 5, "max": 20},
		{"stat": "defense", "min": 3, "max": 15},
		{"stat": "max_hp", "min": 50, "max": 200},
		{"stat": "max_mp", "min": 20, "max": 100},
		{"stat": "crit_rate", "min": 0.02, "max": 0.1},
		{"stat": "crit_damage", "min": 0.1, "max": 0.5},
		{"stat": "speed", "min": 5, "max": 20}
	]

	for i in range(modifier_count):
		if possible_modifiers.is_empty():
			break

		var idx = randi() % possible_modifiers.size()
		var mod_template = possible_modifiers[idx]
		possible_modifiers.remove_at(idx)

		var value = randf_range(mod_template.min, mod_template.max)
		if mod_template.stat in ["crit_rate", "crit_damage"]:
			value = snapped(value, 0.01)
		else:
			value = int(value)

		modifiers.append({
			"stat": mod_template.stat,
			"value": value
		})
