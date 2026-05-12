## 角色类 - 运行时角色数据
class_name Character extends Resource

# ==================== 基础信息 ====================
var id: String = ""
var char_name: String = ""
var gender: int = 0        # 0=男, 1=女
var age: int = 0
var birthday: Dictionary = {}  # {year, month, day}

# ==================== 血脉 ====================
var bloodline: String = ""           # 血脉类型
var bloodline_purity: float = 0.0    # 血脉纯度 (0.0-1.0)

# ==================== 修炼 ====================
var realm_id: String = "mortal"      # 当前境界ID
var realm_exp: int = 0               # 境界经验
var spirit_root: Dictionary = {      # 五行灵根
	"gold": 0.0,
	"wood": 0.0,
	"water": 0.0,
	"fire": 0.0,
	"earth": 0.0
}
var main_technique_id: String = ""   # 主功法ID
var techniques: Dictionary = {}      # {technique_id: {level: 1, exp: 0}}

# ==================== 属性 ====================
var base_stats: Dictionary = {
	"max_hp": 100,
	"max_mp": 50,
	"attack": 10,
	"defense": 5,
	"spirit": 10,
	"speed": 10,
	"luck": 0
}
var derived_stats: Dictionary = {}   # 计算后的属性

# ==================== 家族 ====================
var family_id: String = ""
var generation: int = 1
var parent_ids: Array[String] = []
var spouse_id: String = ""
var children_ids: Array[String] = []

# ==================== 状态 ====================
var is_alive: bool = true
var hp: int = 100
var mp: int = 50
var lifespan: int = 80               # 当前寿命上限
var breakthrough_boost: float = 0.0  # 突破加成（临时）

# ==================== 物品 ====================
var inventory: Array = []
var equipment: Dictionary = {        # 装备槽位
	"weapon": null,
	"armor": null,
	"accessory1": null,
	"accessory2": null
}

# ==================== 状态效果 ====================
var status_effects: Array = []
var traits: Array[String] = []       # 特质列表
var cooldowns: Dictionary = {}       # 技能冷却

# ==================== AI/行为 ====================
var current_task: String = ""
var task_progress: float = 0.0
var personality: Dictionary = {      # 性格特质
	"ambition": 0.5,
	"social": 0.5,
	"aggressive": 0.5
}

# ==================== 位置 ====================
var position: Vector3 = Vector3.ZERO
var location_id: String = ""         # 当前所在地点ID


var _inventory = preload("res://scripts/systems/character_inventory.gd").new()


# ==================== 初始化 ====================

func _init() -> void:
	hp = base_stats.max_hp
	mp = base_stats.max_mp
	recalculate_stats()
	_inventory.init(self)


# ==================== 每日处理 ====================

func process_daily() -> void:
	if not is_alive:
		return

	# 修炼获得经验
	_process_cultivation()

	# 状态效果处理
	_process_status_effects()

	# 冷却刷新
	_process_cooldowns()

	# 检查寿命
	_check_lifespan()


func _process_cultivation() -> void:
	var base_exp = DataManager.constants.get("base_cultivation_exp", 10)
	var realm = DataManager.get_realm(realm_id)
	if not realm.is_empty():
		base_exp += realm.get("spirit_bonus", 0) * 0.5

	# 主功法加成
	var main_tech = DataManager.get_technique(main_technique_id)
	if not main_tech.is_empty():
		base_exp = int(base_exp * main_tech.get("cultivation_speed", 1.0))

	# 灵根加成
	var spirit_bonus = 0.0
	for element in spirit_root:
		spirit_bonus += spirit_root[element]
	spirit_bonus /= 5.0  # 平均值
	base_exp = int(base_exp * (1.0 + spirit_bonus * 0.5))

	# 血脉加成
	base_exp = int(base_exp * (1.0 + bloodline_purity * 0.3))

	realm_exp += base_exp

	# 功法经验增加
	for tech_id in techniques:
		var tech_info = techniques[tech_id]
		if tech_info is Dictionary:
			tech_info["exp"] = tech_info.get("exp", 0) + base_exp
		else:
			techniques[tech_id] = {"level": 1, "exp": base_exp}
		_check_technique_level_up(tech_id)


func _process_status_effects() -> void:
	var effects_to_remove = []

	for i in range(status_effects.size()):
		var effect = status_effects[i]
		effect.apply_effect(self)
		effect.remaining_duration -= 1

		if effect.remaining_duration <= 0:
			effects_to_remove.append(i)

	# 移除过期效果（倒序删除）
	for i in effects_to_remove:
		status_effects.remove_at(i)


func _process_cooldowns() -> void:
	var skills_to_clear = []
	for skill_id in cooldowns:
		cooldowns[skill_id] -= 1
		if cooldowns[skill_id] <= 0:
			skills_to_clear.append(skill_id)

	for skill_id in skills_to_clear:
		cooldowns.erase(skill_id)


func _check_lifespan() -> void:
	# 使用年龄调整算法
	var actual_age = _calculate_actual_age()

	if actual_age >= lifespan:
		# 判断是否寿命到期
		var death_chance = (actual_age - lifespan) * 0.1
		if randf() < death_chance:
			die("寿元耗尽")


func _calculate_actual_age() -> int:
	# 计算实际年龄（考虑时间流逝）
	return age


func _check_technique_level_up(tech_id: String) -> void:
	if not techniques.has(tech_id):
		return

	var tech_data = DataManager.get_technique(tech_id)
	if tech_data.is_empty():
		return

	var tech_info = techniques[tech_id]
	var tech_level = tech_info.get("level", 1) if tech_info is Dictionary else 1
	var tech_exp = tech_info.get("exp", 0) if tech_info is Dictionary else 0
	var max_level = tech_data.get("max_level", 10)
	if tech_level >= max_level:
		return

	var exp_per_level = tech_data.get("exp_per_level", 1000)
	if tech_exp >= exp_per_level:
		var new_exp = tech_exp - exp_per_level
		var new_level = tech_level + 1
		if tech_info is Dictionary:
			tech_info["exp"] = new_exp
			tech_info["level"] = new_level

		# 触发技能解锁
		_check_skill_unlock(tech_id, new_level)

		EventManager.add_notification(
			"功法突破",
			"%s 的 %s 突破至第%d层" % [char_name, tech_data.get("name", ""), new_level],
			"success"
		)


func _check_skill_unlock(tech_id: String, level: int) -> void:
	var tech_data = DataManager.get_technique(tech_id)
	if tech_data.is_empty():
		return

	var unlock_levels = tech_data.get("skill_unlock_levels", [])
	for i in range(unlock_levels.size()):
		if level >= unlock_levels[i]:
			# 解锁技能逻辑
			pass


# ==================== 突破 ====================

func attempt_breakthrough() -> Dictionary:
	var next_realm = DataManager.get_next_realm(realm_id)

	if next_realm.is_empty():
		return {"success": false, "reason": "已达最高境界"}

	# 检查经验是否足够
	if realm_exp < next_realm.get("required_exp", 0):
		return {"success": false, "reason": "修炼经验不足"}

	# 检查资源
	var required_resources = next_realm.get("required_resources", {})
	for resource_id in required_resources:
		var required = required_resources[resource_id]
		if not _check_resource(resource_id, required):
			return {"success": false, "reason": "资源不足: %s" % resource_id}

	# 计算成功率
	var success_rate = next_realm.get("base_breakthrough_rate", 0.1)
	success_rate += bloodline_purity * 0.1
	success_rate += _get_spirit_root_bonus_for_realm(next_realm)
	success_rate += breakthrough_boost
	success_rate = clamp(success_rate,
		DataManager.constants.get("min_breakthrough_rate", 0.01),
		DataManager.constants.get("max_breakthrough_rate", 0.95)
	)

	# 消耗资源
	for resource_id in required_resources:
		_consume_resource(resource_id, required_resources[resource_id])

	# 消耗经验
	realm_exp = 0

	# 判断突破结果
	if randf() <= success_rate:
		_apply_realm(next_realm)
		breakthrough_boost = 0.0

		GameManager.realm_breakthrough.emit(self, next_realm)
		EventManager.add_notification(
			"突破成功",
			"%s 成功突破至 %s！" % [char_name, next_realm.get("name", "")],
			"success"
		)

		return {"success": true, "realm": next_realm}

	# 应用失败惩罚
	_apply_breakthrough_failure(next_realm)
	breakthrough_boost = 0.0

	return {"success": false, "reason": "突破失败", "rate": success_rate}


func _get_spirit_root_bonus_for_realm(_realm) -> float:
	# 根据境界属性和灵根计算加成
	return 0.05 * spirit_root.values().reduce(func(a, b): return max(a, b), 0.0)


func _apply_realm(realm) -> void:
	realm_id = realm.get("id", realm_id)

	# 应用属性加成
	base_stats["max_hp"] = base_stats.get("max_hp", 100) + realm.get("max_hp_bonus", 0)
	base_stats["max_mp"] = base_stats.get("max_mp", 50) + realm.get("max_mp_bonus", 0)
	base_stats["attack"] = base_stats.get("attack", 10) + realm.get("attack_bonus", 0)
	base_stats["defense"] = base_stats.get("defense", 5) + realm.get("defense_bonus", 0)
	base_stats["spirit"] = base_stats.get("spirit", 10) + realm.get("spirit_bonus", 0)
	base_stats["speed"] = base_stats.get("speed", 10) + realm.get("speed_bonus", 0)
	lifespan += realm.get("lifespan_bonus", 0)

	# 恢复满状态
	hp = base_stats.max_hp
	mp = base_stats.max_mp

	recalculate_stats()


## 获取境界层级（从realm_id推算）
func get_realm_tier() -> int:
	var realm = DataManager.get_realm(realm_id)
	if not realm.is_empty():
		return realm.get("tier", 1)
	return 1


func _apply_breakthrough_failure(realm) -> void:
	var penalty = realm.get("failure_penalty", {})

	# 经验损失
	var exp_loss_rate = penalty.get("exp_loss_rate", 0.3)
	# 已经清零了经验，这里可以记录损失

	# 受伤概率
	if randf() < penalty.get("injury_chance", 0.2):
		take_damage(int(base_stats.max_hp * 0.3))
		EventManager.add_notification(
			"突破受伤",
			"%s 突破失败，身受重伤！" % char_name,
			"warning"
		)

	# 死亡概率（极高境界突破失败可能死亡）
	if randf() < penalty.get("death_chance", 0.0):
		die("突破失败，走火入魔")


# ==================== 战斗相关 ====================

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		hp = 0
		die("受到致命伤害")


func heal(amount: int) -> void:
	hp = mini(hp + amount, base_stats.max_hp)


func use_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		return true
	return false


func restore_mp(amount: int) -> void:
	mp = mini(mp + amount, base_stats.max_mp)


func die(reason: String) -> void:
	is_alive = false

	# 通知家族
	var family = GameManager.get_family(family_id)
	if not family.is_empty():
		# 家族是Dictionary，移除已死亡成员
		var members: Array = family.get("members", [])
		members.erase(id)
		family["members"] = members

	GameManager.character_died.emit(self)
	EventManager.add_notification(
		"角色死亡",
		"%s %s，享年%d岁" % [char_name, reason, age],
		"danger"
	)


# ==================== 属性计算 ====================

func recalculate_stats() -> void:
	derived_stats = base_stats.duplicate()

	# 装备加成
	for slot in equipment:
		var equipped = equipment[slot]
		if equipped and equipped is Dictionary:
			var item_data = equipped.get("effect", {})
			if not item_data.is_empty():
				for stat in item_data:
					derived_stats[stat] = derived_stats.get(stat, 0) + item_data[stat]

	# 功法加成
	for tech_id in techniques:
		var tech_data = DataManager.get_technique(tech_id)
		if not tech_data.is_empty():
			var tech_info = techniques[tech_id]
			var level = tech_info.get("level", 1) if tech_info is Dictionary else 1
			var bonuses = tech_data.get("effect", {})
			for stat in bonuses:
				derived_stats[stat] = derived_stats.get(stat, 0) + bonuses[stat]

	# 血脉加成
	if bloodline_purity > 0:
		derived_stats["attack"] = derived_stats.get(
			"attack", 0) + int(base_stats.get(
			"attack", 0) * bloodline_purity * 0.2)
		derived_stats["defense"] = derived_stats.get(
			"defense", 0) + int(base_stats.get(
			"defense", 0) * bloodline_purity * 0.2)


# ==================== 物品相关 ====================

# ==================== 物品相关（委托给CharacterInventory） ====================

func add_item(item) -> bool:
	return _inventory.add_item(item)


func remove_item(item_id: String, amount: int = 1) -> bool:
	return _inventory.remove_item(item_id, amount)


func has_item(item_id: String, amount: int = 1) -> bool:
	return _inventory.has_item(item_id, amount)


func get_item_count(item_id: String) -> int:
	return _inventory.get_item_count(item_id)


# ==================== 功法相关 ====================

func learn_technique(tech_id: String) -> bool:
	var tech_data = DataManager.get_technique(tech_id)
	if tech_data.is_empty():
		return false

	if _has_technique(tech_id):
		return false

	# 检查境界需求（简化版）
	var required_realm = tech_data.get("required_realm", "")
	if required_realm != "" and realm_id != required_realm:
		# 检查当前境界是否足够
		var current = DataManager.get_realm(realm_id)
		var required = DataManager.get_realm(required_realm)
		if not current.is_empty() and not required.is_empty():
			if current.get("order", 0) < required.get("order", 0):
				return false

	techniques[tech_id] = {"level": 1, "exp": 0}

	# 如果没有主功法，设为主功法
	if main_technique_id == "" and tech_data.get("type", "") == "cultivation":
		main_technique_id = tech_id

	recalculate_stats()
	return true


func _has_technique(tech_id: String) -> bool:
	return techniques.has(tech_id)


func _get_technique_level(tech_id: String) -> int:
	if techniques.has(tech_id):
		var info = techniques[tech_id]
		return info.get("level", 1) if info is Dictionary else 1
	return 0


# ==================== 特质相关 ====================

func _add_trait(trait_id: String) -> void:
	if not _has_trait(trait_id):
		traits.append(trait_id)


func _remove_trait(trait_id: String) -> void:
	traits.erase(trait_id)


func _has_trait(trait_id: String) -> bool:
	return trait_id in traits


# ==================== 资源检查辅助 ====================

func _check_resource(resource_id: String, amount: int) -> bool:
	# 检查家族资源
	var family = GameManager.get_family(family_id)
	if family:
		return family.get_resource(resource_id) >= amount
	return false


func _consume_resource(resource_id: String, amount: int) -> void:
	var family = GameManager.get_family(family_id)
	if family:
		family.consume_resource(resource_id, amount)


# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {
		"id": id,
		"name": char_name,
		"gender": gender,
		"age": age,
		"birthday": birthday,

		"bloodline": bloodline,
		"bloodline_purity": bloodline_purity,

		"realm_id": realm_id,
		"realm_exp": realm_exp,
		"spirit_root": spirit_root.duplicate(),
		"main_technique_id": main_technique_id,
		"techniques": techniques.duplicate(),

		"base_stats": base_stats.duplicate(),

		"family_id": family_id,
		"generation": generation,
		"parent_ids": parent_ids,
		"spouse_id": spouse_id,
		"children_ids": children_ids,

		"is_alive": is_alive,
		"hp": hp,
		"mp": mp,
		"lifespan": lifespan,

		"traits": traits.duplicate(),
		"personality": personality.duplicate(),

		"location_id": location_id,

		"inventory": _serialize_inventory(),
		"equipment": _serialize_equipment()
	}


func deserialize(data: Dictionary) -> void:
	id = data.get("id", "")
	char_name = data.get("name", "")
	gender = data.get("gender", 0)
	age = data.get("age", 0)
	birthday = data.get("birthday", {})

	bloodline = data.get("bloodline", "")
	bloodline_purity = data.get("bloodline_purity", 0.0)

	realm_id = data.get("realm_id", "mortal")
	realm_exp = data.get("realm_exp", 0)
	spirit_root = data.get("spirit_root", {})
	main_technique_id = data.get("main_technique_id", "")
	techniques = data.get("techniques", {})

	base_stats = data.get("base_stats", {})

	family_id = data.get("family_id", "")
	generation = data.get("generation", 1)
	parent_ids = data.get("parent_ids", [])
	spouse_id = data.get("spouse_id", "")
	children_ids = data.get("children_ids", [])

	is_alive = data.get("is_alive", true)
	hp = data.get("hp", base_stats.max_hp)
	mp = data.get("mp", base_stats.max_mp)
	lifespan = data.get("lifespan", 80)

	traits = data.get("traits", [])
	personality = data.get("personality", {})

	location_id = data.get("location_id", "")

	_deserialize_inventory(data.get("inventory", []))
	_deserialize_equipment(data.get("equipment", {}))

	recalculate_stats()


func _serialize_inventory() -> Array:
	var result = []
	for item in inventory:
		result.append(item.serialize())
	return result


func _deserialize_inventory(data: Array) -> void:
	inventory.clear()
	for item_data in data:
		var item = ItemInstance.new()
		item.deserialize(item_data)
		inventory.append(item)


func _serialize_equipment() -> Dictionary:
	var result = {}
	for slot in equipment:
		if equipment[slot]:
			result[slot] = equipment[slot].serialize()
		else:
			result[slot] = null
	return result


func _deserialize_equipment(data: Dictionary) -> void:
	equipment.clear()
	for slot in data:
		if data[slot]:
			var item = ItemInstance.new()
			item.deserialize(data[slot])
			equipment[slot] = item
		else:
			equipment[slot] = null
