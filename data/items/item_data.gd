## 物品数据 - 定义游戏内物品
class_name ItemData extends Resource

enum ItemType {
	MATERIAL,        # 材料
	PILL,            # 丹药
	EQUIPMENT,       # 装备
	SCROLL,          # 功法秘籍
	TREASURE,        # 法宝
	CONSUMABLE       # 消耗品
}

enum ItemQuality {
	COMMON,          # 普通（白）
	UNCOMMON,        # 优秀（绿）
	RARE,            # 稀有（蓝）
	EPIC,            # 史诗（紫）
	LEGENDARY,       # 传说（金）
	IMMORTAL         # 仙器（红）
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var type: ItemType = ItemType.MATERIAL
@export var quality: ItemQuality = ItemQuality.COMMON
@export var icon: Texture2D
@export var stackable: bool = true
@export var max_stack: int = 99
@export var base_value: int = 100            # 基础价值（灵石）

# 丹药特有属性
@export_group("丹药属性")
@export var pill_effects: Array[Dictionary] = []  # [{"type": "exp", "value": 1000}]
@export var pill_toxicity: float = 0.0       # 丹毒（叠加会有惩罚）
@export var cooldown_days: int = 0           # 冷却时间（天）

# 装备特有属性
@export_group("装备属性")
@export var equip_slot: String = ""           # weapon/armor/accessory/ring/amulet
@export var equip_stats: Dictionary = {}      # {"attack": 50, "defense": 30}
@export var required_level: int = 0           # 需求等级
@export var required_realm: String = ""       # 需求境界
@export var set_id: String = ""               # 套装ID
@export var set_bonus: Dictionary = {}        # 套装奖励

# 法宝特有属性
@export_group("法宝属性")
@export var spirit_power: int = 0             # 灵力
@export var abilities: Array[Dictionary] = [] # 法宝技能
@export var growth_type: String = ""          # 成长类型

# 材料特有属性
@export_group("材料属性")
@export var material_type: String = ""        # 材料类型
@export var rarity: float = 1.0               # 稀有度
@export var spawn_locations: Array[String] = []  # 出现地点


func get_quality_color() -> Color:
	match quality:
		ItemQuality.COMMON:
			return Color(0.9, 0.9, 0.9)      # 白色
		ItemQuality.UNCOMMON:
			return Color(0.3, 0.9, 0.3)      # 绿色
		ItemQuality.RARE:
			return Color(0.3, 0.5, 1.0)      # 蓝色
		ItemQuality.EPIC:
			return Color(0.7, 0.3, 0.9)      # 紫色
		ItemQuality.LEGENDARY:
			return Color(1.0, 0.8, 0.2)      # 金色
		ItemQuality.IMMORTAL:
			return Color(1.0, 0.3, 0.3)      # 红色
		_:
			return Color.WHITE


func get_quality_name() -> String:
	match quality:
		ItemQuality.COMMON:
			return "普通"
		ItemQuality.UNCOMMON:
			return "优秀"
		ItemQuality.RARE:
			return "稀有"
		ItemQuality.EPIC:
			return "史诗"
		ItemQuality.LEGENDARY:
			return "传说"
		ItemQuality.IMMORTAL:
			return "仙器"
		_:
			return "未知"


func get_type_name() -> String:
	match type:
		ItemType.MATERIAL:
			return "材料"
		ItemType.PILL:
			return "丹药"
		ItemType.EQUIPMENT:
			return "装备"
		ItemType.SCROLL:
			return "秘籍"
		ItemType.TREASURE:
			return "法宝"
		ItemType.CONSUMABLE:
			return "消耗品"
		_:
			return "未知"


func get_effect_string() -> String:
	var parts = []
	
	for effect in pill_effects:
		var effect_type = effect.get("type", "")
		var value = effect.get("value", 0)
		
		match effect_type:
			"exp":
				parts.append("修炼经验+%d" % value)
			"hp":
				parts.append("恢复生命%d" % value)
			"mp":
				parts.append("恢复灵力%d" % value)
			"breakthrough_boost":
				parts.append("突破概率+%.0f%%" % (value * 100))
			"lifespan":
				parts.append("寿元+%d年" % value)
			_:
				parts.append(effect_type)
	
	return "\n".join(parts)


func get_stat_string() -> String:
	var parts = []
	
	for stat_name in equip_stats:
		var value = equip_stats[stat_name]
		match stat_name:
			"attack":
				parts.append("攻击+%d" % value)
			"defense":
				parts.append("防御+%d" % value)
			"max_hp":
				parts.append("生命+%d" % value)
			"max_mp":
				parts.append("灵力+%d" % value)
			"crit_rate":
				parts.append("暴击率+%.0f%%" % (value * 100))
			"crit_damage":
				parts.append("暴击伤害+%.0f%%" % (value * 100))
			_:
				parts.append("%s+%d" % [stat_name, value])
	
	return "\n".join(parts)
