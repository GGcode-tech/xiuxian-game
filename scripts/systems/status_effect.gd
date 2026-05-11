## 状态效果类 - 定义角色身上的状态效果
class_name StatusEffect extends Resource

enum EffectType {
	BUFF,            # 增益
	DEBUFF,          # 减益
	DOT,             # 持续伤害
	HOT,             # 持续治疗
	CONTROL,         # 控制效果
	SPECIAL          # 特殊效果
}

var id: String = ""
var name: String = ""
var type: EffectType = EffectType.BUFF
var remaining_duration: int = 1

# 效果数值
var effects: Dictionary = {
	"hp_change": 0,     # 每回合生命变化
	"mp_change": 0,     # 每回合灵力变化
	"stat_modifiers": {} # 属性修饰
}

# 来源信息
var source_id: String = ""
var source_skill: String = ""


func apply_effect(target) -> void:
	# 应用即时效果
	if effects.hp_change != 0:
		if effects.hp_change > 0:
			target.heal(effects.hp_change)
		else:
			target.take_damage(-effects.hp_change)

	if effects.mp_change != 0:
		if effects.mp_change > 0:
			target.restore_mp(effects.mp_change)
		else:
			target.use_mp(-effects.mp_change)


func apply_stat_modifiers(target) -> void:
	for stat in effects.stat_modifiers:
		if target.derived_stats.has(stat):
			target.derived_stats[stat] += effects.stat_modifiers[stat]


func remove_stat_modifiers(target) -> void:
	for stat in effects.stat_modifiers:
		if target.derived_stats.has(stat):
			target.derived_stats[stat] -= effects.stat_modifiers[stat]


func is_expired() -> bool:
	return remaining_duration <= 0


func get_description() -> String:
	var parts = []

	if effects.hp_change != 0:
		if effects.hp_change > 0:
			parts.append("每回合恢复%d生命" % effects.hp_change)
		else:
			parts.append("每回合损失%d生命" % -effects.hp_change)

	if effects.mp_change != 0:
		if effects.mp_change > 0:
			parts.append("每回合恢复%d灵力" % effects.mp_change)
		else:
			parts.append("每回合损失%d灵力" % -effects.mp_change)

	for stat in effects.stat_modifiers:
		var value = effects.stat_modifiers[stat]
		if value > 0:
			parts.append("%s+%d" % [stat, value])
		else:
			parts.append("%s%d" % [stat, value])

	return "%s (%d回合)" % [name, remaining_duration]


# ==================== 预设状态效果 ====================

static func create_poison(duration: int, damage: int):
	var effect = Resource.new()
	effect.id = "poison"
	effect.name = "中毒"
	effect.type = EffectType.DOT
	effect.remaining_duration = duration
	effect.effects.hp_change = -damage
	return effect


static func create_regeneration(duration: int, healing: int):
	var effect = Resource.new()
	effect.id = "regeneration"
	effect.name = "再生"
	effect.type = EffectType.HOT
	effect.remaining_duration = duration
	effect.effects.hp_change = healing
	return effect


static func create_attack_boost(duration: int, amount: int):
	var effect = Resource.new()
	effect.id = "attack_boost"
	effect.name = "攻击增强"
	effect.type = EffectType.BUFF
	effect.remaining_duration = duration
	effect.effects.stat_modifiers = {"attack": amount}
	return effect


static func create_defense_reduce(duration: int, amount: int):
	var effect = Resource.new()
	effect.id = "defense_reduce"
	effect.name = "防御削弱"
	effect.type = EffectType.DEBUFF
	effect.remaining_duration = duration
	effect.effects.stat_modifiers = {"defense": -amount}
	return effect


static func create_stun(duration: int):
	var effect = Resource.new()
	effect.id = "stun"
	effect.name = "眩晕"
	effect.type = EffectType.CONTROL
	effect.remaining_duration = duration
	return effect
