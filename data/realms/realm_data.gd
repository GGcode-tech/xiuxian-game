## 境界数据 - 定义修仙境界
class_name RealmData extends Resource

@export var id: String = ""
@export var name: String = ""
@export var tier: int = 0                      # 境界等级 (1-10)
@export_multiline var description: String = ""

# 突破条件
@export_group("突破条件")
@export var required_exp: int = 1000           # 所需修炼经验
@export var required_resources: Dictionary = {}  # {"spirit_stone": 1000}
@export var base_breakthrough_rate: float = 0.5  # 基础突破率
@export var breakthrough_items: Array[String] = []  # 辅助丹药等
@export var failure_penalty: Dictionary = {    # 失败惩罚
	"exp_loss_rate": 0.3,
	"injury_chance": 0.2,
	"death_chance": 0.0
}

# 属性加成
@export_group("属性加成")
@export var max_hp_bonus: int = 0
@export var max_mp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var spirit_bonus: int = 0             # 神识
@export var speed_bonus: int = 0
@export var lifespan_bonus: int = 0           # 寿命增加（年）

# 功能解锁
@export_group("功能解锁")
@export var unlocked_features: Array[String] = []  # ["flight", "divination"]
@export var unlock_description: String = ""

# 视觉效果
@export_group("视觉效果")
@export var aura_color: Color = Color.WHITE
@export var particle_effect: PackedScene


func get_display_name() -> String:
	return name


func get_required_resource_string() -> String:
	var parts = []
	for resource_id in required_resources:
		var amount = required_resources[resource_id]
		parts.append("%s x%d" % [resource_id, amount])
	return ", ".join(parts)
