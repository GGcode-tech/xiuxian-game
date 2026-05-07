## 家族类 - 运行时家族数据
class_name FamilyData extends Resource

# ==================== 基础信息 ====================
var id: String = ""
var name: String = ""
var founder_id: String = ""
var founded_year: int = 1

# ==================== 成员 ====================
var members: Array[String] = []        # 成员ID列表
var dead_members: Array[String] = []   # 已故成员ID列表

# ==================== 资源 ====================
var resources: Dictionary = {
	"spirit_stone": 1000,      # 灵石
	"spirit_grass": 0,         # 灵草
	"spirit_ore": 0,           # 灵矿
	"blood_essence": 0,        # 精血
	"contribution": 0          # 贡献点
}

# ==================== 领地 ====================
var territories: Array[String] = []    # 拥有的领地ID
var main_territory_id: String = ""     # 主领地ID

# ==================== 等级与声望 ====================
var level: int = 1                     # 家族等级
var reputation: int = 0                # 声望
var prestige: int = 0                  # 威望

# ==================== 科技/传承 ====================
var unlocked_buildings: Array[String] = ["basic_house", "training_ground"]
var unlocked_techniques: Array[String] = []  # 已传承的功法
var special_bloodline: String = ""     # 特殊血脉

# ==================== 关系 ====================
var relations: Dictionary = {}         # {other_family_id: relation_value}
var allies: Array[String] = []
var enemies: Array[String] = []


# ==================== 初始化 ====================

func _init() -> void:
	pass


# ==================== 成员管理 ====================

func add_member(member_id: String) -> void:
	if not members.has(member_id):
		members.append(member_id)


func remove_member(member_id: String) -> void:
	members.erase(member_id)


func on_member_death(character) -> void:
	members.erase(character.id)
	dead_members.append(character.id)
	
	# 威望损失
	prestige -= 10


func get_alive_members() -> Array:
	var result = []
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and character.is_alive:
			result.append(character)
	return result


func get_member_count() -> int:
	return members.size()


# ==================== 资源管理 ====================

func add_resource(resource_id: String, amount: int) -> void:
	if resources.has(resource_id):
		resources[resource_id] += amount
	else:
		resources[resource_id] = amount


func consume_resource(resource_id: String, amount: int) -> bool:
	if get_resource(resource_id) >= amount:
		resources[resource_id] -= amount
		return true
	return false


func get_resource(resource_id: String) -> int:
	return resources.get(resource_id, 0)


func can_afford(costs: Dictionary) -> bool:
	for resource_id in costs:
		if get_resource(resource_id) < costs[resource_id]:
			return false
	return true


# ==================== 月度处理 ====================

func process_monthly() -> void:
	# 资源增长
	_process_resource_growth()
	
	# 声望自然增长
	_process_reputation()
	
	# 检查家族等级
	_check_family_level()


func _process_resource_growth() -> void:
	# 基础增长
	resources.spirit_stone += level * 100
	
	# 领地产出
	for territory_id in territories:
		var territory = GameManager.map_data.get_territory(territory_id)
		if territory:
			for resource_id in territory.resources:
				add_resource(resource_id, territory.resources[resource_id])


func _process_reputation() -> void:
	# 活跃成员带来的声望
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and character.is_alive:
			var realm = DataManager.get_realm(character.realm_id)
			if realm:
				reputation += realm.tier
	
	# 声望上限
	reputation = mini(reputation, 10000)


func _check_family_level() -> void:
	# 根据成员数量和实力升级
	var total_power = calculate_total_power()
	var member_count = get_alive_members().size()
	
	var required_for_next = level * 1000
	if total_power >= required_for_next and member_count >= level * 2:
		level += 1
		EventManager.add_notification(
			"家族升级",
			"%s 升级为 %d 级家族！" % [name, level],
			"success"
		)


# ==================== 实力计算 ====================

func calculate_total_power() -> int:
	var power = 0
	
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and character.is_alive:
			power += calculate_member_power(character)
	
	# 领地加成
	for territory_id in territories:
		var territory = GameManager.map_data.get_territory(territory_id)
		if territory:
			power += territory.power_bonus
	
	return power


func calculate_member_power(character) -> int:
	var power = 0
	
	# 境界实力
	var realm = DataManager.get_realm(character.realm_id)
	if realm:
		power += realm.tier * 100
	
	# 属性实力
	power += character.get("derived_stats", {}).get("attack", 10)
	power += character.get("derived_stats", {}).get("defense", 5)
	power += int(character.get("derived_stats", {}).get("max_hp", 100) * 0.5)
	
	# 装备实力
	for slot in character.equipment:
		var equipped = character.equipment[slot]
		if equipped:
			var item_data = equipped.get_item_data()
			if item_data:
				power += item_data.quality * 20
	
	# 血脉加成
	power += int(power * character.bloodline_purity * 0.3)
	
	return power


# ==================== 关系管理 ====================

func update_relation(other_family_id: String, change: int) -> void:
	if not relations.has(other_family_id):
		relations[other_family_id] = 0
	
	relations[other_family_id] += change
	relations[other_family_id] = clamp(relations[other_family_id], -100, 100)
	
	# 更新同盟/敌对状态
	var relation = relations[other_family_id]
	
	if relation >= 70:
		if not allies.has(other_family_id):
			allies.append(other_family_id)
		enemies.erase(other_family_id)
	elif relation <= -50:
		if not enemies.has(other_family_id):
			enemies.append(other_family_id)
		allies.erase(other_family_id)
	else:
		allies.erase(other_family_id)
		enemies.erase(other_family_id)


func get_relation(other_family_id: String) -> int:
	return relations.get(other_family_id, 0)


func is_ally(other_family_id: String) -> bool:
	return allies.has(other_family_id)


func is_enemy(other_family_id: String) -> bool:
	return enemies.has(other_family_id)


# ==================== 继承 ====================

func get_heir() -> String:
	# 获取继承人（按辈分、能力排序）
	var candidates = []
	
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and character.is_alive:
			candidates.append({
				"id": member_id,
				"power": calculate_member_power(character),
				"generation": character.generation
			})
	
	if candidates.is_empty():
		return ""
	
	# 排序：辈分优先，然后实力
	candidates.sort_custom(func(a, b): 
		if a.generation != b.generation:
			return a.generation < b.generation
		return a.power > b.power
	)
	
	return candidates[0].id


# ==================== 序列化 ====================

func serialize() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"founder_id": founder_id,
		"founded_year": founded_year,
		
		"members": members.duplicate(),
		"dead_members": dead_members.duplicate(),
		
		"resources": resources.duplicate(),
		
		"territories": territories.duplicate(),
		"main_territory_id": main_territory_id,
		
		"level": level,
		"reputation": reputation,
		"prestige": prestige,
		
		"unlocked_buildings": unlocked_buildings.duplicate(),
		"unlocked_techniques": unlocked_techniques.duplicate(),
		"special_bloodline": special_bloodline,
		
		"relations": relations.duplicate(),
		"allies": allies.duplicate(),
		"enemies": enemies.duplicate()
	}


func deserialize(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	founder_id = data.get("founder_id", "")
	founded_year = data.get("founded_year", 1)
	
	members = data.get("members", [])
	dead_members = data.get("dead_members", [])
	
	resources = data.get("resources", {})
	
	territories = data.get("territories", [])
	main_territory_id = data.get("main_territory_id", "")
	
	level = data.get("level", 1)
	reputation = data.get("reputation", 0)
	prestige = data.get("prestige", 0)
	
	unlocked_buildings = data.get("unlocked_buildings", [])
	unlocked_techniques = data.get("unlocked_techniques", [])
	special_bloodline = data.get("special_bloodline", "")
	
	relations = data.get("relations", {})
	allies = data.get("allies", [])
	enemies = data.get("enemies", [])
