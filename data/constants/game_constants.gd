## 游戏常量 - 全局配置参数
class_name GameConstants extends Resource

# 游戏版本
@export var version: String = "0.1.0"

# 时间相关
@export_group("时间设置")
@export var days_per_month: int = 30
@export var months_per_year: int = 12
@export var seconds_per_day: float = 1.0  # 游戏内1天=现实多少秒

# 角色相关
@export_group("角色设置")
@export var base_max_hp: int = 100
@export var base_max_mp: int = 50
@export var base_attack: int = 10
@export var base_defense: int = 5
@export var base_spirit: int = 10
@export var base_speed: int = 10
@export var base_lifespan: int = 80          # 基础寿命（年）
@export var max_lifespan: int = 10000        # 绝对寿命上限

# 修炼相关
@export_group("修炼设置")
@export var base_cultivation_exp: int = 10   # 每日基础修炼经验
@export var spirit_root_effect: float = 0.5   # 灵根对修炼速度影响
@export var bloodline_effect: float = 0.3    # 血脉对修炼速度影响
@export var min_breakthrough_rate: float = 0.05  # 最低突破率
@export var max_breakthrough_rate: float = 0.95  # 最高突破率

# 家族相关
@export_group("家族设置")
@export var base_family_capacity: int = 20   # 基础家族容量
@export var marriage_min_age: int = 16       # 结婚最低年龄
@export var pregnancy_duration: int = 270    # 怀孕周期（天）
@export var max_children_per_couple: int = 5 # 每对夫妇最多子女

# 资源相关
@export_group("资源设置")
@export var spirit_stone_value: int = 1      # 灵石基础价值
@export var resource_decay_rate: float = 0.01 # 资源衰减率

# 战斗相关
@export_group("战斗设置")
@export var base_crit_rate: float = 0.05     # 基础暴击率
@export var base_crit_damage: float = 1.5    # 基础暴击伤害倍数
@export var dodge_base: float = 0.02         # 基础闪避率
@export var hit_base: float = 0.95           # 基础命中率

# 项目等级
@export_group("项目设置")
@export var max_technique_level: int = 10    # 功法最高层数
@export var max_item_stack: int = 99         # 物品最大堆叠
@export var max_inventory_slots: int = 100   # 背包最大格子

# UI相关
@export_group("UI设置")
@export var tooltip_delay: float = 0.5       # 提示框延迟
@export var notification_duration: float = 5.0  # 通知显示时间
@export var max_notifications: int = 50      # 最大通知数量

# 平衡参数
@export_group("平衡参数")
@export var difficulty_multiplier: float = 1.0  # 难度系数
@export var exp_multiplier: float = 1.0         # 经验系数
@export var resource_multiplier: float = 1.0    # 资源系数


# ==================== 工具方法 ====================

func get(key: String, default = null):
	if get(key) != null:
		return get(key)
	return default


func calculate_lifespan(realm_tier: int) -> int:
	# 境界越高，寿命越长
	return base_lifespan + realm_tier * 200


func calculate_cultivation_speed(spirit_root_value: float, bloodline_purity: float) -> float:
	var base = 1.0
	base += spirit_root_value * spirit_root_effect
	base += bloodline_purity * bloodline_effect
	return base
