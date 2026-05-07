## 角色生成器 - 创建新角色
class_name CharacterGenerator extends Node

# 姓氏池
var surnames = ["韩", "林", "张", "李", "王", "刘", "陈", "杨", "赵", "黄",
				"周", "吴", "徐", "孙", "胡", "朱", "高", "林", "何", "郭"]

# 男性名字池
var male_names = ["立", "明", "天", "轩", "风", "雨", "辰", "宇", "霆", "翔",
				  "寒", "逸", "凡", "玄", "清", "峰", "尘", "凌", "炎", "冰"]

# 女性名字池
var female_names = ["婉", "月", "雪", "琳", "瑶", "如", "梦", "芸", "烟", "兰",
					"霜", "灵", "幽", "凝", "露", "晴", "雅", "慧", "芷", "馨"]

# 特质池
var positive_traits = ["天资聪颖", "悟性超凡", "心志坚定", "灵根纯净", "福缘深厚",
					   "修炼奇才", "炼丹天赋", "剑道天赋", "阵法天赋", "炼器天赋"]
var negative_traits = ["资质平庸", "心魔深重", "命运多舛", "灵根杂乱", "修炼缓慢"]
var rare_traits = ["先天道体", "至尊灵根", "不灭金身", "万毒不侵", "天命之人"]

# 血脉池
var bloodlines = [
	{"id": "azure_dragon", "name": "青龙血脉", "element": "wood", "rarity": 0.05, "bonus": {"attack": 0.15, "max_hp": 0.1}},
	{"id": "white_tiger", "name": "白虎血脉", "element": "gold", "rarity": 0.05, "bonus": {"attack": 0.2, "crit_rate": 0.05}},
	{"id": "vermillion_bird", "name": "朱雀血脉", "element": "fire", "rarity": 0.05, "bonus": {"attack": 0.15, "spirit": 0.1}},
	{"id": "black_tortoise", "name": "玄武血脉", "element": "water", "rarity": 0.05, "bonus": {"defense": 0.2, "max_hp": 0.15}},
	{"id": "qilin", "name": "麒麟血脉", "element": "earth", "rarity": 0.02, "bonus": {"attack": 0.1, "defense": 0.1, "spirit": 0.1, "max_hp": 0.1}}
]


func generate_character(
	family_id: String,
	generation: int = 1,
	parent_ids: Array[String] = [],
	forced_gender: int = -1
):
	
	var character = Character.new()
	
	# 基本信息
	character.id = _generate_id()
	character.gender = forced_gender if forced_gender >= 0 else (0 if randf() < 0.5 else 1)
	character.name = _generate_name(character.gender)
	character.age = 0
	character.birthday = {
		"year": GameManager.game_time.year,
		"month": GameManager.game_time.month,
		"day": GameManager.game_time.day
	}
	
	# 家族
	character.family_id = family_id
	character.generation = generation
	character.parent_ids = parent_ids
	
	# 灵根
	character.spirit_root = _generate_spirit_root(parent_ids)
	
	# 血脉（父母有血脉时概率继承）
	var bloodline_result = _inherit_bloodline(parent_ids)
	character.bloodline = bloodline_result[0]
	character.bloodline_purity = bloodline_result[1]
	
	# 初始属性
	character.base_stats = _generate_base_stats(character.spirit_root, character.bloodline_purity)
	character.hp = character.base_stats.max_hp
	character.mp = character.base_stats.max_mp
	character.realm_id = "mortal"
	character.lifespan = 80
	
	# 特质
	_assign_initial_traits(character)
	
	# 性格
	character.personality = {
		"ambition": randf(),
		"social": randf(),
		"aggressive": randf()
	}
	
	# 初始技能
	character.learn_technique("basic_cultivation")
	
	character.recalculate_stats()
	
	return character


func _generate_id() -> String:
	return "char_%d_%d" % [Time.get_ticks_msec(), randi()]


func _generate_name(gender: int) -> String:
	var surname = surnames[randi() % surnames.size()]
	var given_name = ""
	
	if gender == 0:  # 男
		given_name = male_names[randi() % male_names.size()]
		if randf() < 0.3:
			given_name += male_names[randi() % male_names.size()]
	else:  # 女
		given_name = female_names[randi() % female_names.size()]
		if randf() < 0.3:
			given_name += female_names[randi() % female_names.size()]
	
	return surname + given_name


func _generate_spirit_root(parent_ids: Array[String] = []) -> Dictionary:
	var root = {"gold": 0.0, "wood": 0.0, "water": 0.0, "fire": 0.0, "earth": 0.0}
	
	# 父母灵根影响
	var parent_influence = false
	for pid in parent_ids:
		var parent = GameManager.get_character(pid)
		if parent:
			for element in parent.spirit_root:
				root[element] += parent.spirit_root[element] * 0.3
			parent_influence = true
	
	if not parent_influence:
		# 随机生成灵根
		# 天灵根概率最低，五行灵根概率最高
		var num_roots = _weighted_random([0.05, 0.1, 0.2, 0.3, 0.35]) + 1  # 1-5个灵根
		var elements = ["gold", "wood", "water", "fire", "earth"]
		elements.shuffle()
		
		for i in range(num_roots):
			root[elements[i]] = randf_range(0.3, 1.0)
	
	return root


func _inherit_bloodline(parent_ids: Array[String]) -> Array:
	var bloodline_id = ""
	var purity = 0.0
	
	for pid in parent_ids:
		var parent = GameManager.get_character(pid)
		if parent and parent.bloodline != "":
			# 继承血脉
			if randf() < 0.5 + parent.bloodline_purity * 0.3:
				bloodline_id = parent.bloodline
				# 纯度随机变化
				purity = clamp(parent.bloodline_purity + randf_range(-0.1, 0.15), 0.1, 1.0)
			break
	
	# 随机觉醒血脉（极低概率）
	if bloodline_id == "" and randf() < 0.005:
		var bl = bloodlines[randi() % bloodlines.size()]
		bloodline_id = bl.id
		purity = randf_range(0.1, 0.5)
	
	return [bloodline_id, purity]


func _generate_base_stats(spirit_root: Dictionary, bloodline_purity: float) -> Dictionary:
	var stats = {
		"max_hp": 100 + randi_range(-10, 10),
		"max_mp": 50 + randi_range(-5, 5),
		"attack": 10 + randi_range(-2, 2),
		"defense": 5 + randi_range(-1, 1),
		"spirit": 10 + randi_range(-2, 2),
		"speed": 10 + randi_range(-2, 2),
		"luck": randi_range(0, 10)
	}
	
	# 灵根加成
	var total_root = 0.0
	for element in spirit_root:
		total_root += spirit_root[element]
	stats.spirit += int(total_root * 5)
	
	# 血脉加成
	if bloodline_purity > 0:
		stats.max_hp += int(stats.max_hp * bloodline_purity * 0.1)
		stats.attack += int(stats.attack * bloodline_purity * 0.1)
	
	return stats


func _assign_initial_traits(character) -> void:
	# 正面特质
	if randf() < 0.3:
		character.add_trait(positive_traits[randi() % positive_traits.size()])
	
	# 负面特质
	if randf() < 0.15:
		character.add_trait(negative_traits[randi() % negative_traits.size()])
	
	# 稀有特质
	if randf() < 0.02:
		character.add_trait(rare_traits[randi() % rare_traits.size()])
	
	# 灵根相关特质
	var root_values = character.spirit_root.values()
	var max_root = root_values.max()
	var active_roots = root_values.filter(func(v): return v > 0).size()
	
	match active_roots:
		1:
			character.add_trait("天灵根")
		2:
			character.add_trait("真灵根")
		3:
			character.add_trait("三灵根")
		4:
			character.add_trait("四灵根")
		5:
			character.add_trait("五灵根（杂灵根）")


func _weighted_random(weights: Array) -> int:
	var total = 0.0
	for w in weights:
		total += w
	
	var roll = randf() * total
	var cumulative = 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	
	return weights.size() - 1
