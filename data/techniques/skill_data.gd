## 技能数据 - 定义功法技能
class_name SkillData extends Resource

enum SkillType {
	ACTIVE,          # 主动技能
	PASSIVE,         # 被动技能
	TOGGLE           # 切换技能
}

enum TargetType {
	SELF,            # 自身
	SINGLE_ENEMY,    # 单体敌人
	SINGLE_ALLY,     # 单体友方
	ALL_ENEMIES,     # 所有敌人
	ALL_ALLIES,      # 所有友方
	AREA,            # 区域
	POINT            # 点选
}

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var type: SkillType = SkillType.ACTIVE
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var icon: Texture2D

# 学习条件
@export_group("学习条件")
@export var required_technique_level: int = 1  # 需要功法层数

# 使用消耗
@export_group("使用消耗")
@export var mp_cost: int = 0
@export var hp_cost: int = 0
@export var cooldown: int = 0                 # 冷却回合数
@export var special_cost: Dictionary = {}     # 特殊消耗

# 效果
@export_group("效果")
@export var damage: Dictionary = {}           # {"base": 100, "scaling": 1.5}
@export var healing: Dictionary = {}          # {"base": 50, "scaling": 0.8}
@export var buffs: Array[Dictionary] = []     # 增益效果
@export var debuffs: Array[Dictionary] = []   # 减益效果
@export var special_effects: Array[Dictionary] = []  # 特殊效果

# 视觉效果
@export_group("视觉效果")
@export var animation: String = ""
@export var particle_effect: PackedScene
@export var sound_effect: String = ""


func get_mp_cost_string() -> String:
	if mp_cost > 0:
		return "灵力消耗: %d" % mp_cost
	return ""


func get_cooldown_string() -> String:
	if cooldown > 0:
		return "冷却: %d回合" % cooldown
	return ""


func get_damage_string() -> String:
	if damage.is_empty():
		return ""
	
	var base = damage.get("base", 0)
	var scaling = damage.get("scaling", 1.0)
	return "伤害: %d (×%.1f灵力)" % [base, scaling]
