## 功法数据 - 定义修炼功法
class_name TechniqueData extends Resource

enum TechniqueType {
	CULTIVATION,     # 修炼功法（主功法）
	COMBAT,          # 战斗功法
	AUXILIARY,       # 辅助功法
	BODY_REFINING,   # 炼体功法
	SOUL_REFINING    # 炼神功法
}

enum TechniqueRank {
	MORTAL,          # 凡级（灰白）
	SPIRIT,          # 灵级（绿）
	IMMORTAL,        # 仙级（蓝）
	DIVINE           # 神级（金）
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var type: TechniqueType = TechniqueType.CULTIVATION
@export var rank: TechniqueRank = TechniqueRank.MORTAL
@export var icon: Texture2D

# 学习条件
@export_group("学习条件")
@export var required_realm: String = ""         # 需要境界ID
@export var required_spirit_root: Dictionary = {}  # 灵根要求 {"fire": 0.5}
@export var required_techniques: Array[String] = []  # 前置功法
@export var required_bloodline: String = ""    # 血脉要求

# 修炼效果
@export_group("修炼效果")
@export var max_level: int = 10                 # 最高层数
@export var exp_per_level: int = 1000          # 每层所需经验
@export var cultivation_speed: float = 1.0     # 修炼速度加成（倍数）
@export var stat_bonuses_per_level: Dictionary = {}  # 每层属性加成

# 技能解锁
@export_group("技能解锁")
@export var skills_unlocked: Array = []  # 解锁技能
@export var skill_unlock_levels: Array[int] = []    # 技能解锁等级

# 特殊效果
@export_group("特殊效果")
@export var passive_effects: Array[Dictionary] = []  # 被动效果列表
@export var special_abilities: Array[String] = []    # 特殊能力


func get_rank_color() -> Color:
	match rank:
		TechniqueRank.MORTAL:
			return Color(0.7, 0.7, 0.7)      # 灰白
		TechniqueRank.SPIRIT:
			return Color(0.3, 0.8, 0.3)      # 绿色
		TechniqueRank.IMMORTAL:
			return Color(0.3, 0.5, 1.0)      # 蓝色
		TechniqueRank.DIVINE:
			return Color(1.0, 0.8, 0.2)      # 金色
		_:
			return Color.WHITE


func get_rank_name() -> String:
	match rank:
		TechniqueRank.MORTAL:
			return "凡级"
		TechniqueRank.SPIRIT:
			return "灵级"
		TechniqueRank.IMMORTAL:
			return "仙级"
		TechniqueRank.DIVINE:
			return "神级"
		_:
			return "未知"


func get_type_name() -> String:
	match type:
		TechniqueType.CULTIVATION:
			return "修炼功法"
		TechniqueType.COMBAT:
			return "战斗功法"
		TechniqueType.AUXILIARY:
			return "辅助功法"
		TechniqueType.BODY_REFINING:
			return "炼体功法"
		TechniqueType.SOUL_REFINING:
			return "炼神功法"
		_:
			return "未知"


func get_stat_bonus_at_level(level: int) -> Dictionary:
	var bonus = {}
	for stat_name in stat_bonuses_per_level:
		var values = stat_bonuses_per_level[stat_name]
		if values is Array and values.size() > 0:
			var idx = mini(level - 1, values.size() - 1)
			bonus[stat_name] = values[idx]
		elif values is int or values is float:
			bonus[stat_name] = values * level
	return bonus


func can_learn(character) -> bool:
	# 检查境界要求
	if required_realm != "":
		var char_realm = DataManager.get_realm(character.realm_id)
		var req_realm = DataManager.get_realm(required_realm)
		if char_realm and req_realm:
			if char_realm.tier < req_realm.tier:
				return false
	
	# 检查灵根要求
	for element in required_spirit_root:
		if character.spirit_root.get(element, 0) < required_spirit_root[element]:
			return false
	
	# 检查前置功法
	for pre_tech in required_techniques:
		if not character.has_technique(pre_tech):
			return false
	
	# 检查血脉要求
	if required_bloodline != "" and character.bloodline != required_bloodline:
		return false
	
	return true
