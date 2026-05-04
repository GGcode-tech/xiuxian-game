## 装备系统 - 装备槽位、品质等级、强化、宝石、套装
extends Node

## 套装效果
class SetBonus extends RefCounted:
	var required_count: int  # 需要的装备件数
	var stat_bonus: Dictionary  # 属性加成
	var special_effect: String = ""  # 特殊效果描述


## 装备数据类
class EquipmentData extends RefCounted:
	var id: String
	var name: String
	var equipment_type: EquipmentType
	var slot: EquipmentSlot
	var quality: EquipmentQuality
	var level_requirement: int = 1
	var base_stats: Dictionary = {}  # 基础属性
	var gem_slots: int = 0           # 宝石孔数量（0-4）
	var set_id: String = ""          # 所属套装ID
	var description: String = ""


## 装备实例（玩家拥有的装备）
class EquipmentInstance extends RefCounted:
	var id: String
	var equipment_data_id: String
	var name: String
	var quality: EquipmentQuality
	var slot: EquipmentSlot
	
	var enhancement_level: int = 0   # 强化等级 +1~+15
	var gems: Array[int] = []        # 已镶嵌的宝石 [GemType, ...]，最多4个
	
	# 属性
	var stats: Dictionary = {}
	var set_id: String = ""
	var equipped_by: String = ""  # 装备角色ID
	
	func _init() -> void:
		gems.resize(4)  # 4个宝石孔


## 装备槽位类型
enum EquipmentSlot {
	WEAPON = 0,    # 武器
	ARMOR = 1,     # 防具
	ACCESSORY = 2, # 饰品（可装备2个）
}

## 装备品质
enum EquipmentQuality {
	WHITE = 0,   # 白装 - 普通
	GREEN = 1,   # 绿装 - 优秀
	BLUE = 2,    # 蓝装 - 精良
	PURPLE = 3,  # 紫装 - 史诗
	ORANGE = 4,  # 橙装 - 传说
	RED = 5,     # 红装 - 神话
}

## 装备类型
enum EquipmentType {
	SWORD,       # 剑
	BLADE,       # 刀
	STAFF,       # 法杖
	ARMOR_HEAVY, # 重甲
	ARMOR_LIGHT, # 轻甲
	RING,        # 戒指
	NECKLACE,    # 项链
	BRACELET,    # 手镯
}

## 宝石类型
enum GemType {
	ATTACK,     # 攻击宝石
	DEFENSE,    # 防御宝石
	HP,         # 生命宝石
	MP,         # 法力宝石
	SPIRIT,     # 精魂宝石
	SPEED,      # 速度宝石
	LUCK,       # 幸运宝石
}

## 信号
signal equipment_equipped(equipment: EquipmentInstance, slot: EquipmentSlot)
signal equipment_unequipped(equipment: EquipmentInstance)
signal enhancement_success(equipment_id: String, new_level: int)
signal enhancement_failed(equipment_id: String)
signal gem_inserted(equipment_id: String, gem_type: GemType, slot_index: int)
signal gem_removed(equipment_id: String, gem_type: GemType)
signal set_completed(set_id: String, bonus: SetBonus)


## 装备配置数据
var equipment_templates: Dictionary = {}
var equipment_sets: Dictionary = {}
var gem_templates: Dictionary = {}

## 玩家装备实例
var player_equipment: Array[EquipmentInstance] = []


func _init() -> void:
	_init_default_equipment()


func _init_default_equipment() -> void:
	_init_gem_templates()
	_init_equipment_sets()
	_init_default_equipment_templates()


func _init_gem_templates() -> void:
	gem_templates = {
		"gem_attack_1": {"id": "gem_attack_1", "name": "攻击宝石", "type": GemType.ATTACK, "value": 10, "quality": EquipmentQuality.GREEN},
		"gem_attack_2": {"id": "gem_attack_2", "name": "精致攻击宝石", "type": GemType.ATTACK, "value": 25, "quality": EquipmentQuality.BLUE},
		"gem_attack_3": {"id": "gem_attack_3", "name": "极品攻击宝石", "type": GemType.ATTACK, "value": 50, "quality": EquipmentQuality.PURPLE},
		"gem_defense_1": {"id": "gem_defense_1", "name": "防御宝石", "type": GemType.DEFENSE, "value": 10, "quality": EquipmentQuality.GREEN},
		"gem_hp_1": {"id": "gem_hp_1", "name": "生命宝石", "type": GemType.HP, "value": 100, "quality": EquipmentQuality.GREEN},
		"gem_hp_2": {"id": "gem_hp_2", "name": "精致生命宝石", "type": GemType.HP, "value": 250, "quality": EquipmentQuality.BLUE},
		"gem_speed_1": {"id": "gem_speed_1", "name": "速度宝石", "type": GemType.SPEED, "value": 5, "quality": EquipmentQuality.GREEN},
		"gem_luck_1": {"id": "gem_luck_1", "name": "幸运宝石", "type": GemType.LUCK, "value": 3, "quality": EquipmentQuality.BLUE},
	}


func _init_equipment_sets() -> void:
	equipment_sets = {
		"set_xuanwu": {
			"id": "set_xuanwu",
			"name": "玄武套装",
			"description": "玄武神甲，防御无双",
			"pieces": {
				"armor": ["equip_xuanwu_armor"],
				"helmet": ["equip_xuanwu_helmet"],
				"boots": ["equip_xuanwu_boots"]
			},
			"bonuses": [
				{"required": 2, "stat_bonus": {"defense": 50, "max_hp": 500}, "special_effect": "玄武护体：受到伤害减少10%"},
				{"required": 3, "stat_bonus": {"defense": 150, "max_hp": 1500}, "special_effect": "玄武真身：免疫控制效果"}
			]
		},
		"set_feijian": {
			"id": "set_feijian",
			"name": "飞剑套装",
			"description": "御剑飞行，剑去如虹",
			"pieces": {
				"weapon": ["equip_feijian_sword"],
				"accessory": ["equip_feijian_charm"]
			},
			"bonuses": [
				{"required": 2, "stat_bonus": {"attack": 80, "speed": 30}, "special_effect": "剑意：攻击速度+20%"}
			]
		}
	}


func _init_default_equipment_templates() -> void:
	var templates: Array = [
		{
			"id": "equip_jinshi_sword",
			"name": "金丝剑",
			"equipment_type": EquipmentType.SWORD,
			"slot": EquipmentSlot.WEAPON,
			"quality": EquipmentQuality.GREEN,
			"level_requirement": 5,
			"base_stats": {"attack": 15, "speed": 5},
			"gem_slots": 1,
			"set_id": "",
			"description": "金丝编织的剑，较为锋利"
		},
		{
			"id": "equip_xuanwu_armor",
			"name": "玄武甲",
			"equipment_type": EquipmentType.ARMOR_HEAVY,
			"slot": EquipmentSlot.ARMOR,
			"quality": EquipmentQuality.PURPLE,
			"level_requirement": 30,
			"base_stats": {"defense": 50, "max_hp": 200},
			"gem_slots": 2,
			"set_id": "set_xuanwu",
			"description": "玄武神甲，防御惊人"
		},
		{
			"id": "equip_feijian_sword",
			"name": "飞剑",
			"equipment_type": EquipmentType.SWORD,
			"slot": EquipmentSlot.WEAPON,
			"quality": EquipmentQuality.BLUE,
			"level_requirement": 20,
			"base_stats": {"attack": 35, "speed": 15},
			"gem_slots": 2,
			"set_id": "set_feijian",
			"description": "可远程攻击的飞剑"
		},
		{
			"id": "equip_ring_attack",
			"name": "攻击戒指",
			"equipment_type": EquipmentType.RING,
			"slot": EquipmentSlot.ACCESSORY,
			"quality": EquipmentQuality.BLUE,
			"level_requirement": 15,
			"base_stats": {"attack": 20},
			"gem_slots": 1,
			"set_id": "",
			"description": "增强攻击力的戒指"
		},
		{
			"id": "equip_necklace_hp",
			"name": "生命项链",
			"equipment_type": EquipmentType.NECKLACE,
			"slot": EquipmentSlot.ACCESSORY,
			"quality": EquipmentQuality.BLUE,
			"level_requirement": 15,
			"base_stats": {"max_hp": 300},
			"gem_slots": 1,
			"set_id": "",
			"description": "增加生命值的项链"
		},
		{
			"id": "equip_default_sword",
			"name": "新手剑",
			"equipment_type": EquipmentType.SWORD,
			"slot": EquipmentSlot.WEAPON,
			"quality": EquipmentQuality.WHITE,
			"level_requirement": 1,
			"base_stats": {"attack": 5},
			"gem_slots": 0,
			"set_id": "",
			"description": "新手入门的简单武器"
		}
	]
	
	for tpl in templates:
		equipment_templates[tpl["id"]] = tpl


## 获取装备模板
func get_equipment_template(equip_id: String) -> EquipmentData:
	if equipment_templates.has(equip_id):
		return _create_equipment_data(equipment_templates[equip_id])
	return null


func get_all_equipment_templates() -> Array:
	var result: Array = []
	for tid in equipment_templates:
		result.append(_create_equipment_data(equipment_templates[tid]))
	return result


func _create_equipment_data(data: Dictionary) -> EquipmentData:
	var ed = EquipmentData.new()
	ed.id = data.get("id", "")
	ed.name = data.get("name", "")
	ed.equipment_type = data.get("equipment_type", EquipmentType.SWORD)
	ed.slot = data.get("slot", EquipmentSlot.WEAPON)
	ed.quality = data.get("quality", EquipmentQuality.WHITE)
	ed.level_requirement = data.get("level_requirement", 1)
	ed.base_stats = data.get("base_stats", {})
	ed.gem_slots = data.get("gem_slots", 0)
	ed.set_id = data.get("set_id", "")
	ed.description = data.get("description", "")
	return ed


## 创建装备实例
func create_equipment(equip_id: String) -> EquipmentInstance:
	var template = get_equipment_template(equip_id)
	if not template:
		return null
	
	var inst = EquipmentInstance.new()
	inst.id = "equip_%d" % Time.get_ticks_msec()
	inst.equipment_data_id = equip_id
	inst.name = template.name
	inst.quality = template.quality
	inst.slot = template.slot
	inst.enhancement_level = 0
	inst.stats = template.base_stats.duplicate()
	inst.set_id = template.set_id
	inst.gem_slots = template.gem_slots
	
	player_equipment.append(inst)
	return inst


## 强化装备
func enhance_equipment(equip_id: String) -> Dictionary:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return {"success": false, "reason": "装备不存在"}
	
	if equip.enhancement_level >= 15:
		return {"success": false, "reason": "已达最大强化等级"}
	
	# 强化消耗
	var cost = _calculate_enhance_cost(equip)
	var player = _get_current_player()
	if not player:
		return {"success": false, "reason": "玩家不存在"}
	
	# 消耗灵石
	if player.get_item_count("item_lingshi") < cost:
		return {"success": false, "reason": "灵石不足"}
	
	player.remove_item("item_lingshi", cost)
	
	# 强化成功率（保底机制）
	var base_success_rate = 0.5 + equip.enhancement_level * 0.03
	var success_rate = minf(base_success_rate, 0.95)  # 最高95%
	
	if randf() < success_rate:
		equip.enhancement_level += 1
		_apply_enhancement_bonus(equip)
		enhancement_success.emit(equip_id, equip.enhancement_level)
		_save_to_game_db()
		return {"success": true, "new_level": equip.enhancement_level}
	else:
		# 保底：强化等级不降
		enhancement_failed.emit(equip_id)
		return {"success": false, "reason": "强化失败（保底机制：等级不降）"}


func _calculate_enhance_cost(equip: EquipmentInstance) -> int:
	var base_cost = 50
	var quality_multiplier = [1.0, 1.5, 2.0, 3.0, 5.0, 8.0][equip.quality]
	var level_multiplier = pow(1.5, equip.enhancement_level)
	return int(base_cost * quality_multiplier * level_multiplier)


func _apply_enhancement_bonus(equip: EquipmentInstance) -> void:
	# 每级强化增加基础属性5%
	var multiplier = 1.0 + equip.enhancement_level * 0.05
	for stat in equip.stats:
		equip.stats[stat] = int(equip.stats[stat] * multiplier)


## 镶嵌宝石
func insert_gem(equip_id: String, gem_type: GemType, slot_index: int = -1) -> bool:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return false
	
	# 检查宝石孔数量
	var max_slots = minf(equip.gem_slots, 4) if equip.gem_slots > 0 else 4
	if max_slots == 0:
		max_slots = 4  # 默认4孔
	
	# 找到空槽位
	if slot_index < 0:
		slot_index = _find_empty_gem_slot(equip)
	
	if slot_index < 0 or slot_index >= max_slots:
		return false
	
	# 检查宝石是否已存在
	if equip.gems[slot_index] >= 0:
		return false
	
	equip.gems[slot_index] = gem_type
	gem_inserted.emit(equip_id, gem_type, slot_index)
	_apply_gem_bonus(equip)
	_save_to_game_db()
	return true


func _find_empty_gem_slot(equip: EquipmentInstance) -> int:
	for i in range(mini(equip.gems.size(), 4)):
		if equip.gems[i] < 0:
			return i
	return -1


func _apply_gem_bonus(equip: EquipmentInstance) -> void:
	# 重新计算属性
	var template = get_equipment_template(equip.equipment_data_id)
	if template:
		equip.stats = template.base_stats.duplicate()
		_apply_enhancement_bonus(equip)
	
	# 应用宝石加成
	for gem_type in equip.gems:
		if gem_type >= 0:
			var gem_data = _get_gem_data(gem_type)
			if gem_data:
				var stat_type = _get_stat_for_gem_type(gem_type)
				if not equip.stats.has(stat_type):
					equip.stats[stat_type] = 0
				equip.stats[stat_type] += gem_data.get("value", 0)


func _get_gem_data(gem_type: GemType) -> Dictionary:
	for gem in gem_templates.values():
		if gem.get("type", -1) == gem_type:
			return gem
	return {}


func _get_stat_for_gem_type(gem_type: GemType) -> String:
	match gem_type:
		GemType.ATTACK: return "attack"
		GemType.DEFENSE: return "defense"
		GemType.HP: return "max_hp"
		GemType.MP: return "max_mp"
		GemType.SPIRIT: return "spirit"
		GemType.SPEED: return "speed"
		GemType.LUCK: return "luck"
		_: return "attack"


## 卸下宝石
func remove_gem(equip_id: String, slot_index: int) -> GemType:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return GemType.ATTACK  # 默认
	
	var gem_type = equip.gems[slot_index]
	if gem_type >= 0:
		equip.gems[slot_index] = -1
		gem_removed.emit(equip_id, gem_type)
		_save_to_game_db()
	
	return gem_type


## 装备装备
func equip_item(equip_id: String, character_id: String) -> bool:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return false
	
	var character = GameManager.get_character(character_id)
	if character.is_empty():
		return false
	
	# 检查等级要求
	var template = get_equipment_template(equip.equipment_data_id)
	if template and character.get("realm_tier", 1) < template.level_requirement / 10:
		return false
	
	# 装备到对应槽位
	equip.equipped_by = character_id
	equipment_equipped.emit(equip, equip.slot)
	_save_to_game_db()
	return true


## 卸下装备
func unequip_item(equip_id: String) -> bool:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return false
	
	equip.equipped_by = ""
	equipment_unequipped.emit(equip)
	_save_to_game_db()
	return true


## 获取角色装备
func get_character_equipment(character_id: String) -> Dictionary:
	var result = {
		"weapon": null,
		"armor": null,
		"accessory1": null,
		"accessory2": null
	}
	
	for equip in player_equipment:
		if equip.equipped_by == character_id:
			match equip.slot:
				EquipmentSlot.WEAPON:
					result["weapon"] = equip
				EquipmentSlot.ARMOR:
					result["armor"] = equip
				EquipmentSlot.ACCESSORY:
					if result["accessory1"] == null:
						result["accessory1"] = equip
					else:
						result["accessory2"] = equip
	
	return result


## 计算套装加成
func calculate_set_bonus(character_id: String) -> Dictionary:
	var char_equipment = get_character_equipment(character_id)
	var equipped_sets: Dictionary = {}  # set_id -> count
	
	# 统计套装件数
	for slot in char_equipment:
		var equip = char_equipment[slot]
		if equip and equip.set_id != "":
			if not equipped_sets.has(equip.set_id):
				equipped_sets[equip.set_id] = 0
			equipped_sets[equip.set_id] += 1
	
	var bonuses: Array = []
	var completed_sets: Array = []
	
	for set_id in equipped_sets:
		var set_data = equipment_sets.get(set_id, {})
		var count = equipped_sets[set_id]
		var set_bonuses = set_data.get("bonuses", [])
		
		for bonus in set_bonuses:
			if count >= bonus.get("required", 0):
				bonuses.append(bonus)
				if bonus.get("required", 0) == count:
					completed_sets.append(set_id)
					set_completed.emit(set_id, bonus)
	
	return {
		"bonuses": bonuses,
		"completed_sets": completed_sets,
		"total_bonus_stats": _aggregate_bonus_stats(bonuses)
	}


func _aggregate_bonus_stats(bonuses: Array) -> Dictionary:
	var stats: Dictionary = {}
	for bonus in bonuses:
		var stat_bonus = bonus.get("stat_bonus", {})
		for stat in stat_bonus:
			if not stats.has(stat):
				stats[stat] = 0
			stats[stat] += stat_bonus[stat]
	return stats


## 副本掉落/商店购买装备
func generate_random_equipment(quality: EquipmentQuality, level: int) -> EquipmentInstance:
	var candidates: Array = []
	
	for tid in equipment_templates:
		var tpl = equipment_templates[tid]
		if tpl.get("quality", EquipmentQuality.WHITE) == quality:
			if absf(tpl.get("level_requirement", 1) - level) <= 5:
				candidates.append(tid)
	
	if candidates.is_empty():
		# 降级选择
		for tid in equipment_templates:
			var tpl = equipment_templates[tid]
			if absf(tpl.get("level_requirement", 1) - level) <= 10:
				candidates.append(tid)
	
	if candidates.is_empty():
		return null
	
	var selected_id = candidates[randi() % candidates.size()]
	return create_equipment(selected_id)


## 获取装备品质名称
func get_quality_name(quality: EquipmentQuality) -> String:
	match quality:
		EquipmentQuality.WHITE: return "白色"
		EquipmentQuality.GREEN: return "绿色"
		EquipmentQuality.BLUE: return "蓝色"
		EquipmentQuality.PURPLE: return "紫色"
		EquipmentQuality.ORANGE: return "橙色"
		EquipmentQuality.RED: return "红色"
		_: return "未知"


func get_quality_color(quality: EquipmentQuality) -> String:
	match quality:
		EquipmentQuality.WHITE: return "#FFFFFF"
		EquipmentQuality.GREEN: return "#00FF00"
		EquipmentQuality.BLUE: return "#0000FF"
		EquipmentQuality.PURPLE: return "#9900FF"
		EquipmentQuality.ORANGE: return "#FF9900"
		EquipmentQuality.RED: return "#FF0000"
		_: return "#FFFFFF"


func get_slot_name(slot: EquipmentSlot) -> String:
	match slot:
		EquipmentSlot.WEAPON: return "武器"
		EquipmentSlot.ARMOR: return "防具"
		EquipmentSlot.ACCESSORY: return "饰品"
		_: return "未知"


func get_gem_name(gem_type: GemType) -> String:
	match gem_type:
		GemType.ATTACK: return "攻击宝石"
		GemType.DEFENSE: return "防御宝石"
		GemType.HP: return "生命宝石"
		GemType.MP: return "法力宝石"
		GemType.SPIRIT: return "精魂宝石"
		GemType.SPEED: return "速度宝石"
		GemType.LUCK: return "幸运宝石"
		_: return "未知宝石"


## 工具函数
func _get_equipment_by_id(equip_id: String) -> EquipmentInstance:
	for equip in player_equipment:
		if equip.id == equip_id:
			return equip
	return null


func _get_current_player() -> Character:
	var family = GameManager.get_player_family()
	if family.is_empty():
		return null
	var members = GameManager.get_family_characters(family.get("id", ""))
	if members.is_empty():
		return null
	for m in members:
		if m.get("is_alive", false):
			return m
	return null


## 保存/加载
func _save_to_game_db() -> void:
	var save_data = {
		"player_equipment": []
	}
	
	for equip in player_equipment:
		save_data["player_equipment"].append(_serialize_equipment(equip))
	
	SaveManager.set_data("equipment", save_data)


func _serialize_equipment(equip: EquipmentInstance) -> Dictionary:
	return {
		"id": equip.id,
		"equipment_data_id": equip.equipment_data_id,
		"name": equip.name,
		"quality": equip.quality,
		"slot": equip.slot,
		"enhancement_level": equip.enhancement_level,
		"gems": Array(equip.gems),
		"stats": equip.stats,
		"set_id": equip.set_id,
		"equipped_by": equip.equipped_by
	}


func load_from_save(data: Dictionary) -> void:
	player_equipment.clear()
	
	var equip_list = data.get("player_equipment", [])
	for equip_dict in equip_list:
		var equip = _deserialize_equipment(equip_dict)
		if equip:
			player_equipment.append(equip)


func _deserialize_equipment(data: Dictionary) -> EquipmentInstance:
	var inst = EquipmentInstance.new()
	inst.id = data.get("id", "")
	inst.equipment_data_id = data.get("equipment_data_id", "")
	inst.name = data.get("name", "")
	inst.quality = data.get("quality", EquipmentQuality.WHITE)
	inst.slot = data.get("slot", EquipmentSlot.WEAPON)
	inst.enhancement_level = data.get("enhancement_level", 0)
	inst.gems = Array(data.get("gems", [-1, -1, -1, -1]))
	inst.stats = data.get("stats", {})
	inst.set_id = data.get("set_id", "")
	inst.equipped_by = data.get("equipped_by", "")
	return inst


## 获取玩家所有装备
func get_player_equipment() -> Array[EquipmentInstance]:
	return player_equipment.duplicate()


## 出售装备
func sell_equipment(equip_id: String) -> int:
	var equip = _get_equipment_by_id(equip_id)
	if not equip:
		return 0
	
	var template = get_equipment_template(equip.equipment_data_id)
	if not template:
		return 0
	
	# 装备价值 = 基础价值 * 品质系数
	var base_value = template.base_stats.values().reduce(func(a, b): return a + b, 0) * 10
	var quality_multiplier = [1.0, 1.5, 2.5, 4.0, 7.0, 12.0][equip.quality]
	var sell_value = int(base_value * quality_multiplier)
	
	# 强化等级加成
	sell_value *= (1 + equip.enhancement_level * 0.1)
	
	player_equipment.erase(equip)
	_save_to_game_db()
	
	return int(sell_value)