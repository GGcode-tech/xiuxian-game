## 灵兽/宠物系统 - 小说人物作为战斗伙伴、捕捉契约、资质评级
extends Node

## 灵兽数据类
class SpiritBeastData extends RefCounted:
	var id: String
	var name: String
	var novel_source: String        # 所属小说
	var character_id: String         # 对应的novel人物ID
	var beast_type: BeastType
	var grade: BeastGrade
	var description: String
	var base_stats: Dictionary       # 基础属性
	var skills: Array[String]       # 天生技能列表
	var growth_rate: Dictionary     # 属性成长率
	var evolution_stage: int = 1    # 进化阶段


## 灵兽实例（玩家契约的灵兽）
class SpiritBeastInstance extends RefCounted:
	var id: String
	var beast_data_id: String        # 灵兽配置ID
	var name: String
	var beast_type: BeastType
	var grade: BeastGrade
	var level: int = 1
	var experience: int = 0
	var contract_status: ContractStatus = ContractStatus.WILD

	# 当前属性（受等级和资质影响）
	var stats: Dictionary = {
		"max_hp": 100,
		"attack": 10,
		"defense": 5,
		"spirit": 10,
		"speed": 10,
		"luck": 0
	}

	var skills: Array[String] = []          # 已学会技能
	var innate_skills: Array[String] = []   # 天生技能
	var equip_slots: Dictionary = {          # 灵兽装备槽
		"collar": null,
		"artifact": null
	}

	var loyalty: int = 50       # 忠诚度 0-100
	var owner_id: String = ""  # 主人角色ID


## 信号
signal beast_contracted(beast_instance: SpiritBeastInstance)
signal beast_evolution(beast_id: String, new_stage: int)
signal beast_level_up(beast_id: String, new_level: int)
## 信号
signal beast_fed(beast_id: String)

enum BeastType {
	BATTLE,    # 战斗型（输出）
	SUPPORT,   # 辅助型（治疗/buff）
	CONTROL    # 控制型
}

## 灵兽资质等级
enum BeastGrade {
	S = 0,     # S级 - 天赋异禀
	A = 1,     # A级 - 卓越
	B = 2,     # B级 - 优秀
	C = 3      # C级 - 普通
}

## 契约状态
enum ContractStatus {
	WILD,      # 野生未契约
	CONTRACTED,# 已契约
	BONDED     # 深度绑定
}


## 灵兽配置数据（从novel_database读取）
var beasts_data: Dictionary = {}
var player_beasts: Array[SpiritBeastInstance] = []
var captured_beasts: Array[SpiritBeastInstance] = []  # 野外捕捉的灵兽


func _init() -> void:
	_init_default_beasts()


func _init_default_beasts() -> void:
	# 初始化默认灵兽数据（基于小说人物）
	var default_beasts: Array = [
		{
			"id": "beast_hanli",
			"name": "韩立灵体",
			"novel_source": "凡人修仙传",
			"character_id": "char_hanli",
			"beast_type": BeastType.BATTLE,
			"grade": BeastGrade.S,
			"description": "韩立的一缕神识所化，擅长隐匿和突袭",
			"base_stats": {
				"max_hp": 200, "attack": 35, "defense": 15,
				"spirit": 25, "speed": 30, "luck": 10
			},
			"skills": ["skill_hanli_invisible", "skill_hanli_punch"],
			"growth_rate": {"max_hp": 15, "attack": 3.5, "defense": 1.5, "spirit": 2.5, "speed": 3.0}
		},
		{
			"id": "beast_yinyue",
			"name": "银月狼魂",
			"novel_source": "凡人修仙传",
			"character_id": "char_yinyue",
			"beast_type": BeastType.SUPPORT,
			"grade": BeastGrade.A,
			"description": "银月天狼的一丝精魄，辅助能力强大",
			"base_stats": {"max_hp": 150, "attack": 20, "defense": 20, "spirit": 35, "speed": 25, "luck": 5},
			"skills": ["skill_moon_heal", "skill_moon_shield"],
			"growth_rate": {"max_hp": 12, "attack": 2.0, "defense": 2.0, "spirit": 3.5, "speed": 2.5}
		},
		{
			"id": "beast_qinyu",
			"name": "秦羽灵兽",
			"novel_source": "星辰变",
			"character_id": "char_qinyu",
			"beast_type": BeastType.BATTLE,
			"grade": BeastGrade.S,
			"description": "秦羽的伴生灵兽，紫爪火狼",
			"base_stats": {
				"max_hp": 250, "attack": 40, "defense": 20,
				"spirit": 20, "speed": 35, "luck": 15
			},
			"skills": ["skill_fire_bite", "skill_wolf_pack"],
			"growth_rate": {"max_hp": 18, "attack": 4.0, "defense": 2.0, "spirit": 2.0, "speed": 3.5}
		},
		{
			"id": "beast_houfei",
			"name": "侯费猿魂",
			"novel_source": "星辰变",
			"character_id": "char_houfei",
			"beast_type": BeastType.BATTLE,
			"grade": BeastGrade.A,
			"description": "侯费的魔猿血脉，力量惊人",
			"base_stats": {"max_hp": 300, "attack": 45, "defense": 25, "spirit": 15, "speed": 20, "luck": 5},
			"skills": ["skill_power_strike", "skill_giant_ape"],
			"growth_rate": {"max_hp": 20, "attack": 4.5, "defense": 2.5, "spirit": 1.5, "speed": 2.0}
		},
		{
			"id": "beast_xiaofan",
			"name": "小凡灵体",
			"novel_source": "诛仙",
			"character_id": "char_xiaofan",
			"beast_type": BeastType.CONTROL,
			"grade": BeastGrade.B,
			"description": "张小凡的执念所化，擅长困敌",
			"base_stats": {"max_hp": 180, "attack": 25, "defense": 18, "spirit": 30, "speed": 22, "luck": 8},
			"skills": ["skill_trap", "skill_drain"],
			"growth_rate": {"max_hp": 14, "attack": 2.5, "defense": 1.8, "spirit": 3.0, "speed": 2.2}
		},
		{
			"id": "beast_biyao",
			"name": "碧瑶灵狐",
			"novel_source": "诛仙",
			"character_id": "char_biyao",
			"beast_type": BeastType.SUPPORT,
			"grade": BeastGrade.A,
			"description": "碧瑶的一缕精魂，化作灵狐形态",
			"base_stats": {
				"max_hp": 160, "attack": 22, "defense": 15,
				"spirit": 40, "speed": 28, "luck": 12
			},
			"skills": ["skill_charm", "skill_heal_aura"],
			"growth_rate": {"max_hp": 13, "attack": 2.2, "defense": 1.5, "spirit": 4.0, "speed": 2.8}
		},
		{
			"id": "beast_default",
			"name": "灵兽卵",
			"novel_source": "通用",
			"character_id": "",
			"beast_type": BeastType.BATTLE,
			"grade": BeastGrade.C,
			"description": "一只还未孵化的灵兽卵，可契约",
			"base_stats": {"max_hp": 80, "attack": 8, "defense": 5, "spirit": 8, "speed": 8, "luck": 3},
			"skills": [],
			"growth_rate": {"max_hp": 8, "attack": 0.8, "defense": 0.5, "spirit": 0.8, "speed": 0.8}
		}
	]

	for beast in default_beasts:
		beasts_data[beast["id"]] = beast


## 从novel_database读取灵兽数据
func load_beasts_from_novel_db() -> void:
	var novel_chars = DataManager.get_all_characters()
	for char in novel_chars:
		var char_novel = char.get("novel_source", "")
		if char_novel == "":
			continue

		# 根据角色特性确定灵兽类型
		var beast_type: BeastType = BeastType.BATTLE
		var skills: Array = []

		# 自动生成灵兽配置
		var beast_id = "beast_novel_" + char.get("id", "")
		if not beasts_data.has(beast_id):
			beasts_data[beast_id] = {
				"id": beast_id,
				"name": char.get("name", "") + "灵体",
				"novel_source": char_novel,
				"character_id": char.get("id", ""),
				"beast_type": beast_type,
				"grade": BeastGrade.C,
				"description": "由%s的精魄所化" % char.get("name", ""),
				"base_stats": _generate_stats_from_character(char),
				"skills": skills,
				"growth_rate": _generate_growth_rate(BeastGrade.C)
			}


func _generate_stats_from_character(char: Dictionary) -> Dictionary:
	return {
		"max_hp": 100 + char.get("realm_tier", 1) * 20,
		"attack": 10 + char.get("realm_tier", 1) * 5,
		"defense": 5 + char.get("realm_tier", 1) * 3,
		"spirit": 10 + char.get("realm_tier", 1) * 4,
		"speed": 10 + char.get("realm_tier", 1) * 4,
		"luck": char.get("luck", 0)
	}


func _generate_growth_rate(grade: BeastGrade) -> Dictionary:
	var multiplier = [1.5, 1.2, 1.0, 0.8][grade]
	return {
		"max_hp": 10 * multiplier,
		"attack": 1.0 * multiplier,
		"defense": 0.5 * multiplier,
		"spirit": 1.0 * multiplier,
		"speed": 1.0 * multiplier
	}


## 获取灵兽配置
func get_beast_data(beast_id: String) -> SpiritBeastData:
	if beasts_data.has(beast_id):
		return _create_beast_data(beasts_data[beast_id])
	return null


func get_all_beasts() -> Array:
	var result: Array = []
	for bid in beasts_data:
		result.append(_create_beast_data(beasts_data[bid]))
	return result


func get_beasts_by_grade(grade: BeastGrade) -> Array:
	var result: Array = []
	for beast in beasts_data.values():
		if beast.get("grade", BeastGrade.C) == grade:
			result.append(_create_beast_data(beast))
	return result


func get_beasts_by_novel(novel_name: String) -> Array:
	var result: Array = []
	for beast in beasts_data.values():
		if beast.get("novel_source", "") == novel_name:
			result.append(_create_beast_data(beast))
	return result


func _create_beast_data(data: Dictionary) -> SpiritBeastData:
	var bd = SpiritBeastData.new()
	bd.id = data.get("id", "")
	bd.name = data.get("name", "")
	bd.novel_source = data.get("novel_source", "")
	bd.character_id = data.get("character_id", "")
	bd.beast_type = data.get("beast_type", BeastType.BATTLE)
	bd.grade = data.get("grade", BeastGrade.C)
	bd.description = data.get("description", "")
	bd.base_stats = data.get("base_stats", {})
	bd.skills = data.get("skills", [])
	bd.growth_rate = data.get("growth_rate", {})
	return bd


## 野外捕捉（消耗道具契约灵兽）
func capture_beast(beast_id: String,
		contract_item_id: String = "item_contract_talisman") -> SpiritBeastInstance:
	var beast_data = get_beast_data(beast_id)
	if not beast_data:
		return null

	# 检查是否有契约道具
	var player = _get_current_player()
	if not player:
		return null

	if not player.has_item(contract_item_id, 1):
		return null

	# 消耗道具
	player.remove_item(contract_item_id, 1)

	# 创建灵兽实例
	var instance = _create_beast_instance(beast_data)
	instance.contract_status = ContractStatus.CONTRACTED
	instance.owner_id = player.id

	player_beasts.append(instance)
	beast_contracted.emit(instance)
	_save_to_game_db()

	return instance


func _create_beast_instance(data: SpiritBeastData) -> SpiritBeastInstance:
	var inst = SpiritBeastInstance.new()
	inst.id = "beast_%d_%s" % [Time.get_ticks_msec(), data.id]
	inst.beast_data_id = data.id
	inst.name = data.name
	inst.beast_type = data.beast_type
	inst.grade = data.grade
	inst.level = 1
	inst.experience = 0
	inst.innate_skills = data.skills.duplicate()
	inst.skills = data.skills.duplicate()

	# 应用基础属性
	inst.stats = data.base_stats.duplicate()

	return inst


## 契约已有灵兽
func contract_beast(beast_id: String) -> SpiritBeastInstance:
	for beast in captured_beasts:
		if beast.id == beast_id:
			beast.contract_status = ContractStatus.CONTRACTED
			player_beasts.append(beast)
			captured_beasts.erase(beast)
			beast_contracted.emit(beast)
			_save_to_game_db()
			return beast
	return null


## 放生灵兽
func release_beast(beast_id: String) -> void:
	for beast in player_beasts:
		if beast.id == beast_id:
			beast.contract_status = ContractStatus.WILD
			beast.owner_id = ""
			player_beasts.erase(beast)
			_save_to_game_db()
			return


## 灵兽升级
func add_beast_exp(beast_id: String, amount: int) -> bool:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return false

	beast.experience += amount
	var exp_needed = _calculate_exp_for_next_level(beast.level)

	while beast.experience >= exp_needed:
		beast.experience -= exp_needed
		beast.level += 1
		_apply_level_up_stats(beast)
		beast_level_up.emit(beast.id, beast.level)

	_save_to_game_db()
	return true


func _calculate_exp_for_next_level(current_level: int) -> int:
	return int(100 * pow(1.5, current_level - 1))


func _apply_level_up_stats(beast: SpiritBeastInstance) -> void:
	var beast_data = get_beast_data(beast.beast_data_id)
	if not beast_data:
		return

	var growth = beast_data.growth_rate
	for stat in growth:
		if beast.stats.has(stat):
			beast.stats[stat] += growth[stat]


## 进化灵兽
func evolve_beast(beast_id: String) -> bool:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return false

	var max_evolutions = {BeastGrade.S: 5, BeastGrade.A: 4, BeastGrade.B: 3, BeastGrade.C: 2}
	var max_evo = max_evolutions.get(beast.grade, 2)

	if beast.evolution_stage >= max_evo:
		return false

	var exp_required = beast.level * 1000
	if beast.experience < exp_required:
		return false

	beast.experience -= exp_required
	beast.evolution_stage += 1

	# 进化后属性提升
	var beast_data = get_beast_data(beast.beast_data_id)
	if beast_data:
		for stat in beast_data.growth_rate:
			beast.stats[stat] += beast_data.growth_rate[stat] * 2

	beast_evolution.emit(beast.id, beast.evolution_stage)
	_save_to_game_db()
	return true


## 深度绑定（提升忠诚度和战斗力）
func bond_beast(beast_id: String) -> bool:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return false

	if beast.contract_status != ContractStatus.CONTRACTED:
		return false

	if beast.loyalty < 80:
		return false

	beast.contract_status = ContractStatus.BONDED
	beast_bonded.emit(beast.id)
	_save_to_game_db()
	return true


## 喂食灵兽（增加忠诚度）
func feed_beast(beast_id: String, food_id: String = "item_beast_food") -> bool:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return false

	var player = _get_current_player()
	if not player:
		return false

	if not player.has_item(food_id, 1):
		return false

	player.remove_item(food_id, 1)
	beast.loyalty = mini(beast.loyalty + 10, 100)
	beast_fed.emit(beast.id)
	_save_to_game_db()
	return true


## 学习技能
func teach_skill(beast_id: String, skill_id: String) -> bool:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return false

	if skill_id in beast.skills:
		return false

	beast.skills.append(skill_id)
	return true


## 获取玩家所有灵兽
func get_player_beasts() -> Array[SpiritBeastInstance]:
	return player_beasts.duplicate()


## 获取灵兽战斗力评估
func evaluate_beast_power(beast_id: String) -> int:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return 0

	var power = 0
	power += beast.stats.max_hp * 0.5
	power += beast.stats.attack * 2
	power += beast.stats.defense * 1.5
	power += beast.stats.spirit * 1.5
	power += beast.stats.speed * 1
	power += beast.evolution_stage * 50
	power += beast.loyalty * 2

	return int(power)


## 获取资质名称
func get_grade_name(grade: BeastGrade) -> String:
	match grade:
		BeastGrade.S: return "S级 - 天赋异禀"
		BeastGrade.A: return "A级 - 卓越"
		BeastGrade.B: return "B级 - 优秀"
		BeastGrade.C: return "C级 - 普通"
		_: return "未知"


## 获取灵兽类型名称
func get_beast_type_name(beast_type: BeastType) -> String:
	match beast_type:
		BeastType.BATTLE: return "战斗型"
		BeastType.SUPPORT: return "辅助型"
		BeastType.CONTROL: return "控制型"
		_: return "未知"


## 获取当前玩家角色（简化实现）
func _get_current_player() -> Character:
	var family = GameManager.get_player_family()
	if family.is_empty():
		return null
	var members = GameManager.get_family_characters(family.get("id", ""))
	if members.is_empty():
		return null
	# 返回第一个活着的角色
	for m in members:
		if m.get("is_alive", false):
			return m
	return null


func _get_beast_by_id(beast_id: String) -> SpiritBeastInstance:
	for beast in player_beasts:
		if beast.id == beast_id:
			return beast
	for beast in captured_beasts:
		if beast.id == beast_id:
			return beast
	return null


## 保存数据到game_database.json
func _save_to_game_db() -> void:
	var save_data = {
		"player_beasts": [],
		"captured_beasts": []
	}

	for beast in player_beasts:
		save_data["player_beasts"].append(_serialize_beast(beast))

	for beast in captured_beasts:
		save_data["captured_beasts"].append(_serialize_beast(beast))

	SaveManager.set_data("spirit_beasts", save_data)


func _serialize_beast(beast: SpiritBeastInstance) -> Dictionary:
	return {
		"id": beast.id,
		"beast_data_id": beast.beast_data_id,
		"name": beast.name,
		"beast_type": beast.beast_type,
		"grade": beast.grade,
		"level": beast.level,
		"exp": beast.experience,
		"contract_status": beast.contract_status,
		"stats": beast.stats,
		"skills": beast.skills,
		"innate_skills": beast.innate_skills,
		"loyalty": beast.loyalty,
		"owner_id": beast.owner_id,
		"evolution_stage": beast.evolution_stage
	}


## 从存档加载
func load_from_save(data: Dictionary) -> void:
	player_beasts.clear()
	captured_beasts.clear()

	var player_beasts_data = data.get("player_beasts", [])
	var captured_data = data.get("captured_beasts", [])

	for beast_dict in player_beasts_data:
		var beast = _deserialize_beast(beast_dict)
		if beast:
			player_beasts.append(beast)

	for beast_dict in captured_data:
		var beast = _deserialize_beast(beast_dict)
		if beast:
			captured_beasts.append(beast)


func _deserialize_beast(data: Dictionary) -> SpiritBeastInstance:
	var inst = SpiritBeastInstance.new()
	inst.id = data.get("id", "")
	inst.beast_data_id = data.get("beast_data_id", "")
	inst.name = data.get("name", "")
	inst.beast_type = data.get("beast_type", BeastType.BATTLE)
	inst.grade = data.get("grade", BeastGrade.C)
	inst.level = data.get("level", 1)
	inst.experience = data.get("exp", 0)
	inst.contract_status = data.get("contract_status", ContractStatus.CONTRACTED)
	inst.stats = data.get("stats", {})
	inst.skills = data.get("skills", [])
	inst.innate_skills = data.get("innate_skills", [])
	inst.loyalty = data.get("loyalty", 50)
	inst.owner_id = data.get("owner_id", "")
	inst.evolution_stage = data.get("evolution_stage", 1)
	return inst


## 在战斗中作为伙伴出战
func get_beast_for_combat(beast_id: String) -> Character:
	var beast = _get_beast_by_id(beast_id)
	if not beast:
		return null

	# 创建临时Character对象用于战斗
	var char_data = {
		"id": "combat_beast_" + beast.id,
		"name": beast.name,
		"hp": beast.stats.max_hp,
		"max_hp": beast.stats.max_hp,
		"mp": beast.stats.spirit * 5,
		"max_mp": beast.stats.spirit * 5,
		"attack": beast.stats.attack,
		"defense": beast.stats.defense,
		"speed": beast.stats.speed,
		"spirit": beast.stats.spirit,
		"is_alive": true,
		"role": "spirit_beast"
	}

	# 返回一个简单的字典（战斗系统需要Character对象）
	# 实际使用时需要适配combat_system的接口
	return char_data
