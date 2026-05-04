## 角色类 - 运行时角色数据
class_name Character extends Resource

# ==================== 基础信息 ====================
var id: String = ""
var name: String = ""
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


# ==================== 初始化 ====================

func _init() -> void:
	hp = base_stats.max_hp
	mp = base_stats.max_mp
	recalculate_stats()


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
	var base_exp = DataManager.constants.base_cultivation_exp
	var realm = DataManager.get_realm(realm_id)
	if realm:
		base_exp += realm.spirit_bonus * 0.5
	
	# 主功法加成
	var main_tech = DataManager.get_technique(main_technique_id)
	if main_tech:
		base_exp = int(base_exp * main_tech.cultivation_speed)
	
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
		techniques[tech_id].exp += base_exp
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
	if not tech_data:
		return
	
	var tech_info = techniques[tech_id]
	if tech_info.level >= tech_data.max_level:
		return
	
	if tech_info.exp >= tech_data.exp_per_level:
		tech_info.exp -= tech_data.exp_per_level
		tech_info.level += 1
		
		# 触发技能解锁
		_check_skill_unlock(tech_id, tech_info.level)
		
		EventManager.add_notification(
			"功法突破",
			"%s 的 %s 突破至第%d层" % [name, tech_data.name, tech_info.level],
			"success"
		)


func _check_skill_unlock(tech_id: String, level: int) -> void:
	var tech_data = DataManager.get_technique(tech_id)
	if not tech_data:
		return
	
	for i in range(tech_data.skill_unlock_levels.size()):
		if level >= tech_data.skill_unlock_levels[i]:
			# 解锁技能逻辑
			pass


# ==================== 突破 ====================

func attempt_breakthrough() -> Dictionary:
	var next_realm = DataManager.get_next_realm(realm_id)
	
	if next_realm == null:
		return {"success": false, "reason": "已达最高境界"}
	
	# 检查经验是否足够
	if realm_exp < next_realm.required_exp:
		return {"success": false, "reason": "修炼经验不足"}
	
	# 检查资源
	for resource_id in next_realm.required_resources:
		var required = next_realm.required_resources[resource_id]
		if not _check_resource(resource_id, required):
			return {"success": false, "reason": "资源不足: %s" % resource_id}
	
	# 计算成功率
	var success_rate = next_realm.base_breakthrough_rate
	success_rate += bloodline_purity * 0.1
	success_rate += _get_spirit_root_bonus_for_realm(next_realm)
	success_rate += breakthrough_boost
	success_rate = clamp(success_rate, 
		DataManager.constants.min_breakthrough_rate,
		DataManager.constants.max_breakthrough_rate
	)
	
	# 消耗资源
	for resource_id in next_realm.required_resources:
		_consume_resource(resource_id, next_realm.required_resources[resource_id])
	
	# 消耗经验
	realm_exp = 0
	
	# 判断突破结果
	if randf() <= success_rate:
		_apply_realm(next_realm)
		breakthrough_boost = 0.0
		
		GameManager.realm_breakthrough.emit(self, next_realm)
		EventManager.add_notification(
			"突破成功",
			"%s 成功突破至 %s！" % [name, next_realm.name],
			"success"
		)
		
		return {"success": true, "realm": next_realm}
	else:
		# 应用失败惩罚
		_apply_breakthrough_failure(next_realm)
		breakthrough_boost = 0.0
		
		return {"success": false, "reason": "突破失败", "rate": success_rate}


func _get_spirit_root_bonus_for_realm(realm) -> float:
	# 根据境界属性和灵根计算加成
	return 0.05 * spirit_root.values().reduce(func(a, b): return max(a, b), 0.0)


func _apply_realm(realm) -> void:
	realm_id = realm.id
	
	# 应用属性加成
	base_stats.max_hp += realm.max_hp_bonus
	base_stats.max_mp += realm.max_mp_bonus
	base_stats.attack += realm.attack_bonus
	base_stats.defense += realm.defense_bonus
	base_stats.spirit += realm.spirit_bonus
	base_stats.speed += realm.speed_bonus
	lifespan += realm.lifespan_bonus
	
	# 恢复满状态
	hp = base_stats.max_hp
	mp = base_stats.max_mp
	
	recalculate_stats()


func _apply_breakthrough_failure(realm) -> void:
	var penalty = realm.failure_penalty
	
	# 经验损失
	var exp_loss_rate = penalty.get("exp_loss_rate", 0.3)
	# 已经清零了经验，这里可以记录损失
	
	# 受伤概率
	if randf() < penalty.get("injury_chance", 0.2):
		take_damage(int(base_stats.max_hp * 0.3))
		EventManager.add_notification(
			"突破受伤",
			"%s 突破失败，身受重伤！" % name,
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
	if family:
		family.on_member_death(self)
	
	GameManager.character_died.emit(self)
	EventManager.add_notification(
		"角色死亡",
		"%s %s，享年%d岁" % [name, reason, age],
		"danger"
	)


# ==================== 属性计算 ====================

func recalculate_stats() -> void:
	derived_stats = base_stats.duplicate()
	
	# 装备加成
	for slot in equipment:
		var equipped = equipment[slot]
		if equipped:
			var item_data = equipped.get_item_data()
			if item_data:
				for stat in item_data.equip_stats:
					derived_stats[stat] += item_data.equip_stats[stat]
	
	# 功法加成
	for tech_id in techniques:
		var tech_data = DataManager.get_technique(tech_id)
		if tech_data:
			var level = techniques[tech_id].level
			var bonuses = tech_data.get_stat_bonus_at_level(level)
			for stat in bonuses:
				derived_stats[stat] += bonuses[stat]
	
	# 血脉加成
	if bloodline_purity > 0:
		derived_stats.attack += int(base_stats.attack * bloodline_purity * 0.2)
		derived_stats.defense += int(base_stats.defense * bloodline_purity * 0.2)


# ==================== 物品相关 ====================

func add_item(item) -> bool:
	# 检查是否可堆叠
	var item_data = item.get_item_data()
	if item_data and item_data.stackable:
		# 查找同类物品
		for inv_item in inventory:
			if inv_item.item_id == item.item_id and inv_item.count < item_data.max_stack:
				var can_add = item_data.max_stack - inv_item.count
				var to_add = mini(can_add, item.count)
				inv_item.count += to_add
				item.count -= to_add
				if item.count <= 0:
					return true
	
	# 添加到背包
	if inventory.size() < DataManager.constants.max_inventory_slots:
		inventory.append(item)
		return true
	
	return false


func remove_item(item_id: String, amount: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i].item_id == item_id:
			if inventory[i].count <= amount:
				inventory.remove_at(i)
				return true
			else:
				inventory[i].count -= amount
				return true
	return false


func has_item(item_id: String, amount: int = 1) -> bool:
	for inv_item in inventory:
		if inv_item.item_id == item_id and inv_item.count >= amount:
			return true
	return false


func get_item_count(item_id: String) -> int:
	var count = 0
	for inv_item in inventory:
		if inv_item.item_id == item_id:
			count += inv_item.count
	return count


# ==================== 功法相关 ====================

func learn_technique(tech_id: String) -> bool:
	var tech_data = DataManager.get_technique(tech_id)
	if not tech_data:
		return false
	
	if has_technique(tech_id):
		return false
	
	if not tech_data.can_learn(self):
		return false
	
	techniques[tech_id] = {"level": 1, "exp": 0}
	
	# 如果没有主功法，设为主功法
	if main_technique_id == "" and tech_data.type == TechniqueData.TechniqueType.CULTIVATION:
		main_technique_id = tech_id
	
	recalculate_stats()
	return true


func has_technique(tech_id: String) -> bool:
	return techniques.has(tech_id)


func get_technique_level(tech_id: String) -> int:
	if techniques.has(tech_id):
		return techniques[tech_id].level
	return 0


# ==================== 特质相关 ====================

func add_trait(trait_id: String) -> void:
	if not has_trait(trait_id):
		traits.append(trait_id)


func remove_trait(trait_id: String) -> void:
	traits.erase(trait_id)


func has_trait(trait_id: String) -> bool:
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
		"name": name,
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
	name = data.get("name", "")
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
