## 随机事件数据 - 定义游戏随机事件
class_name RandomEventData extends Resource

enum EventType {
	CHARACTER,       # 角色事件
	FAMILY,          # 家族事件
	WORLD,           # 世界事件
	SPECIAL          # 特殊事件
}

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var event_type: String = "character"
@export var icon: Texture2D

# 触发条件
@export_group("触发条件")
@export var triggers: Dictionary = {
	"min_realm": "",           # 最低境界ID
	"min_age": 0,              # 最小年龄
	"max_age": 0,              # 最大年龄（0表示无限制）
	"required_trait": "",      # 需要特质
	"required_bloodline": "",  # 需要血脉
	"min_year": 0,             # 最小年份
	"min_family_level": 0,     # 家族最低等级
	"min_members": 0,          # 家族最少成员
	"random_chance": 0.01      # 随机触发概率
}
@export var trigger_chance: float = 0.01
@export var cooldown_days: int = 0           # 冷却时间
@export var max_occurrences: int = -1        # 最大触发次数（-1无限制）
@export var requirements: Array[Dictionary] = []  # 额外要求

# 事件选项
@export_group("事件选项")
@export var choices: Array = []

# 权重/优先级
@export_group("权重设置")
@export var weight: float = 1.0              # 事件权重
@export var priority: int = 0                # 优先级（越高越先处理）


func get_trigger_description() -> String:
	var parts = []

	if triggers.min_realm != "":
		parts.append("需要境界: %s" % triggers.min_realm)
	if triggers.min_age > 0:
		parts.append("年龄 ≥ %d" % triggers.min_age)
	if triggers.max_age > 0:
		parts.append("年龄 ≤ %d" % triggers.max_age)
	if triggers.required_trait != "":
		parts.append("需要特质: %s" % triggers.required_trait)
	if triggers.min_year > 0:
		parts.append("年份 ≥ 第%d年" % triggers.min_year)

	return "\n".join(parts)
