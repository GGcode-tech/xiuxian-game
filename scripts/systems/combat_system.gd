## 战斗系统 - 回合制战斗逻辑（统一使用 Dictionary 角色数据）
extends Node

enum CombatResult {
	PLAYER_WIN,
	PLAYER_LOSE,
	DRAW,
	FLED
}

# 技能目标类型常量
const SKILL_TARGET_SELF = "self"
const SKILL_TARGET_SINGLE_ENEMY = "single_enemy"
const SKILL_TARGET_ALL_ENEMY = "all_enemy"
const SKILL_TARGET_SINGLE_ALLY = "single_ally"
const SKILL_TARGET_ALL_ALLY = "all_ally"

# 当前战斗状态
var is_in_combat: bool = false
var player_team: Array = []
var enemy_team: Array = []
var current_turn: int = 0
var turn_order: Array = []
var combat_log: Array[String] = []

# 信号
signal combat_started
signal combat_ended(result: CombatResult)
signal turn_started(character)
signal action_executed(action: Dictionary)
signal character_damaged(character, amount: int)
signal character_healed(character, amount: int)


# ==================== 角色属性辅助函数 ====================

func _char_get_stat(char: Dictionary, stat_name: String, default_value = 0):
	"""安全获取角色属性，优先 derived_stats，其次 base_stats"""
	var derived = char.get("derived_stats", {})
	if derived.has(stat_name):
		return derived.get(stat_name, default_value)
	var base = char.get("base_stats", {})
	return base.get(stat_name, default_value)


func _char_get_name(char: Dictionary) -> String:
	return char.get("name", "未知")


func _char_is_alive(char: Dictionary) -> bool:
	return char.get("is_alive", false)


func _char_take_damage(char: Dictionary, amount: int) -> void:
	"""对 Dictionary 角色造成伤害"""
	var hp: int = char.get("hp", 0)
	hp -= amount
	if hp <= 0:
		hp = 0
		char["is_alive"] = false
	char["hp"] = hp


func _char_heal(char: Dictionary, amount: int) -> void:
	"""治疗 Dictionary 角色"""
	var hp: int = char.get("hp", 0)
	var max_hp: int = char.get("base_stats", {}).get("max_hp", 100)
	char["hp"] = mini(hp + amount, max_hp)


func _char_use_mp(char: Dictionary, amount: int) -> bool:
	"""消耗 Dictionary 角色的灵力"""
	var mp: int = char.get("mp", 0)
	if mp >= amount:
		char["mp"] = mp - amount
		return true
	return false


func _char_get_status_effects(char: Dictionary) -> Array:
	return char.get("status_effects", [])


func _char_append_status_effect(char: Dictionary, effect: Dictionary) -> void:
	if not char.has("status_effects"):
		char["status_effects"] = []
	char["status_effects"].append(effect)


func _char_get_cooldowns(char: Dictionary) -> Dictionary:
	return char.get("cooldowns", {})


func _char_set_cooldown(char: Dictionary, skill_id: String, turns: int) -> void:
	if not char.has("cooldowns"):
		char["cooldowns"] = {}
	char["cooldowns"][skill_id] = turns


func _char_add_item(char: Dictionary, item) -> void:
	"""简化版物品添加"""
	if not char.has("items"):
		char["items"] = []
	char["items"].append(item)


func _char_get_realm_id(char: Dictionary) -> String:
	return char.get("realm_id", "mortal")


func _char_get_family_id(char: Dictionary) -> String:
	return char.get("family_id", "")


# ==================== 战斗开始 ====================

func start_combat(player: Array, enemies: Array) -> void:
	player_team = player
	enemy_team = enemies
	current_turn = 0
	is_in_combat = true
	combat_log.clear()

	# 计算行动顺序（速度排序）
	_calculate_turn_order()

	combat_started.emit()

	# 开始第一回合
	_process_turn()


func _calculate_turn_order() -> void:
	var all_chars = []
	all_chars.append_array(player_team)
	all_chars.append_array(enemy_team)

	all_chars.sort_custom(func(a, b):
		return _char_get_stat(a, "speed", 10) > _char_get_stat(b, "speed", 10)
	)

	turn_order = all_chars


# ==================== 回合处理 ====================

func _process_turn() -> void:
	if not is_in_combat:
		return

	current_turn += 1
	combat_log.append("--- 第%d回合 ---" % current_turn)

	for character in turn_order:
		if not is_in_combat:
			break

		if not _char_is_alive(character):
			continue

		turn_started.emit(character)

		# 检查控制效果
		if _is_controlled(character):
			combat_log.append("%s 被控制，无法行动" % _char_get_name(character))
			continue

		# AI行动
		if character in enemy_team:
			_ai_action(character)
		else:
			# 玩家行动由UI选择后调用 execute_action
			pass

		# 检查战斗结束
		_check_combat_end()

func _is_controlled(character) -> bool:
	var effects = _char_get_status_effects(character)
	for effect in effects:
		if effect.get("type", "") == "control":
			return true
	return false

func _ai_action(character) -> void:
	var alive_players = player_team.filter(func(c): return _char_is_alive(c))
	if alive_players.is_empty():
		return

	# 简单AI：随机攻击一个存活的玩家
	var target = alive_players[randi() % alive_players.size()]

	# 检查是否有强力技能
	var skills = _get_available_skills(character)

	if skills.size() > 0 and randf() < 0.4:
		# 使用技能
		var skill_id = skills[randi() % skills.size()]
		_use_skill(character, skill_id, target)
	else:
		# 普通攻击
		_normal_attack(character, target)


func _get_available_skills(character) -> Array:
	var available = []
	var cooldowns = _char_get_cooldowns(character)
	var techniques = character.get("techniques", [])
	# 从角色已学功法/技能中获取可用技能
	for tech_id in techniques:
		if tech_id is Dictionary:
			tech_id = tech_id.get("id", "")
		if not cooldowns.has(str(tech_id)):
			available.append(str(tech_id))
	return available


# ==================== 行动执行 ====================

func execute_action(character, action_type: String, target = null, skill_id: String = "") -> void:
	match action_type:
		"attack":
			_normal_attack(character, target)
		"skill":
			_use_skill(character, skill_id, target)
		"defend":
			_defend(character)
		"flee":
			_attempt_flee(character)
		"item":
			_use_combat_item(character, target)

	action_executed.emit({"type": action_type, "character": character, "target": target})
	_check_combat_end()


func _normal_attack(attacker, defender) -> void:
	var attack = _char_get_stat(attacker, "attack", 10)
	var defense = _char_get_stat(defender, "defense", 5)

	# 伤害计算
	var damage = maxi(1, attack - defense / 2)

	# 暴击
	var crit_rate = GameConstants.base_crit_rate + _char_get_stat(attacker, "crit_rate", 0.0)
	if randf() < crit_rate:
		damage = int(damage * GameConstants.base_crit_damage)
		combat_log.append("💥 %s 暴击！" % _char_get_name(attacker))

	# 闪避
	var dodge = GameConstants.dodge_base + _char_get_stat(defender, "dodge", 0.0)
	if randf() < dodge:
		damage = 0
		combat_log.append("💨 %s 闪避了攻击" % _char_get_name(defender))

	# 随机浮动 ±10%
	damage = int(damage * randf_range(0.9, 1.1))

	if damage > 0:
		# 减防效果
		var effects = _char_get_status_effects(defender)
		var defend_buff = effects.filter(func(e): return e.get("id", "") == "defending")
		if not defend_buff.is_empty():
			damage = int(damage * 0.5)

		_char_take_damage(defender, damage)
		character_damaged.emit(defender, damage)
		combat_log.append("⚔️ %s 攻击 %s，造成 %d 伤害" % [_char_get_name(attacker), _char_get_name(defender), damage])
	else:
		combat_log.append("⚔️ %s 的攻击被 %s 闪避" % [_char_get_name(attacker), _char_get_name(defender)])


func _use_skill(caster, skill_id: String, target) -> void:
	var skill_data = DataManager.get_skill(skill_id)
	if not skill_data or skill_data.is_empty():
		# 如果技能不在技能库中，尝试作为功法ID查找
		skill_data = DataManager.get_technique(skill_id)
		if not skill_data or skill_data.is_empty():
			return

	# 消耗灵力
	var mp_cost = skill_data.get("mp_cost", skill_data.get("exp_required", 10))
	if not _char_use_mp(caster, mp_cost):
		combat_log.append("%s 灵力不足" % _char_get_name(caster))
		return

	# 技能冷却
	var cooldown = skill_data.get("cooldown", skill_data.get("level", 1))
	_char_set_cooldown(caster, skill_id, cooldown)

	# 目标类型
	var target_type = skill_data.get("target_type", SKILL_TARGET_SINGLE_ENEMY)
	match target_type:
		SKILL_TARGET_SELF:
			_apply_skill_effect(caster, caster, skill_data)
		SKILL_TARGET_SINGLE_ENEMY:
			_apply_skill_effect(caster, target, skill_data)
		SKILL_TARGET_ALL_ENEMY:
			for enemy in enemy_team:
				if _char_is_alive(enemy):
					_apply_skill_effect(caster, enemy, skill_data)
		SKILL_TARGET_SINGLE_ALLY:
			_apply_skill_effect(caster, target, skill_data)
		SKILL_TARGET_ALL_ALLY:
			for ally in player_team:
				if _char_is_alive(ally):
					_apply_skill_effect(caster, ally, skill_data)


func _apply_skill_effect(caster, target, skill) -> void:
	var skill_name = skill.get("name", "未知技能")

	# 伤害效果
	var damage_multiplier = skill.get("damage_multiplier", skill.get("effect", {}).get("attack", 0) * 0.1)
	if damage_multiplier > 0:
		var base_damage = _char_get_stat(caster, "attack", 10) * damage_multiplier
		var defense = _char_get_stat(target, "defense", 5)
		var damage = maxi(1, int(base_damage - defense * 0.3))
		_char_take_damage(target, damage)
		character_damaged.emit(target, damage)
		combat_log.append("✨ %s 使用 %s 对 %s 造成 %d 伤害" % [_char_get_name(caster), skill_name, _char_get_name(target), damage])

	# 治疗效果
	var heal_amount = skill.get("heal_amount", 0)
	if heal_amount > 0:
		var heal = heal_amount + _char_get_stat(caster, "spirit", 10) * 0.5
		_char_heal(target, int(heal))
		character_healed.emit(target, int(heal))
		combat_log.append("💚 %s 使用 %s 恢复 %s %d 生命" % [_char_get_name(caster), skill_name, _char_get_name(target), int(heal)])

	# 状态效果
	var effects_data = skill.get("effects", [])
	for effect_data in effects_data:
		var effect = {
			"id": effect_data.get("id", ""),
			"name": effect_data.get("name", ""),
			"type": effect_data.get("type", "buff"),
			"remaining_duration": effect_data.get("duration", 3),
			"effects": effect_data.get("effects", {})
		}
		_char_append_status_effect(target, effect)
		combat_log.append("🌀 %s 获得 %s 效果" % [_char_get_name(target), effect.get("name", "")])


func _defend(character) -> void:
	var defend_effect = {
		"id": "defending",
		"name": "防御",
		"type": "buff",
		"remaining_duration": 999,
		"effects": {"defense_multiplier": 2.0}
	}
	_char_append_status_effect(character, defend_effect)
	combat_log.append("🛡️ %s 进入防御姿态" % _char_get_name(character))


func _attempt_flee(character) -> void:
	var flee_chance = 0.3
	var avg_enemy_speed = 0.0
	var alive_enemies = enemy_team.filter(func(e): return _char_is_alive(e))
	for enemy in alive_enemies:
		avg_enemy_speed += _char_get_stat(enemy, "speed", 10)
	avg_enemy_speed /= maxi(1, alive_enemies.size())

	var player_speed = _char_get_stat(character, "speed", 10)
	flee_chance += (player_speed - avg_enemy_speed) * 0.02
	flee_chance = clamp(flee_chance, 0.05, 0.8)

	if randf() < flee_chance:
		_end_combat(CombatResult.FLED)
		combat_log.append("🏃 %s 成功逃跑！" % _char_get_name(character))
	else:
		combat_log.append("🏃 %s 逃跑失败！" % _char_get_name(character))


func _use_combat_item(character, target) -> void:
	# TODO: 实现战斗中使用物品
	combat_log.append("%s 使用了物品" % _char_get_name(character))


# ==================== 战斗结束 ====================

func _check_combat_end() -> void:
	var player_alive = player_team.any(func(c): return _char_is_alive(c))
	var enemy_alive = enemy_team.any(func(c): return _char_is_alive(c))

	if not player_alive:
		_end_combat(CombatResult.PLAYER_LOSE)
	elif not enemy_alive:
		_end_combat(CombatResult.PLAYER_WIN)

func _end_combat(result: CombatResult) -> void:
	is_in_combat = false

	# 清理状态效果 - 保留 buff
	for character in player_team:
		var effects = _char_get_status_effects(character)
		character["status_effects"] = effects.filter(func(e): return e.get("type", "") == "buff")
	for character in enemy_team:
		character["status_effects"] = []

	# 战斗奖励
	if result == CombatResult.PLAYER_WIN:
		_process_combat_rewards()

	combat_ended.emit(result)

	match result:
		CombatResult.PLAYER_WIN:
			combat_log.append("🏆 战斗胜利！")
		CombatResult.PLAYER_LOSE:
			combat_log.append("💀 战斗失败...")
		CombatResult.FLED:
			combat_log.append("🏃 成功撤退")
		CombatResult.DRAW:
			combat_log.append("⚖️ 平局")


func _process_combat_rewards() -> void:
	var total_exp = 0
	var total_spirit_stones = 0
	var drops: Array = []

	for enemy in enemy_team:
		var realm = DataManager.get_realm(_char_get_realm_id(enemy))
		if not realm.is_empty():
			total_exp += realm.get("tier", 1) * 100
		total_spirit_stones += randi_range(10, 50)

		# 掉落物品
		if randf() < 0.3:
			var drop = _generate_drop(enemy)
			if drop:
				drops.append(drop)

	# 分配奖励
	var alive_count = player_team.filter(func(c): return _char_is_alive(c)).size()
	for character in player_team:
		if _char_is_alive(character):
			character["realm_exp"] = character.get("realm_exp", 0) + total_exp / maxi(1, alive_count)
			for drop in drops:
				_char_add_item(character, drop)

	# 家族灵石奖励
	var family_id = _char_get_family_id(player_team[0]) if player_team.size() > 0 else ""
	if family_id:
		var family = GameManager.get_family(family_id)
		if not family.is_empty():
			family["spirit_stone"] = family.get("spirit_stone", 0) + total_spirit_stones


func _generate_drop(enemy):
	# TODO: 根据敌人类型生成掉落
	return null


func get_combat_summary() -> Dictionary:
	return {
		"turn_count": current_turn,
		"player_alive": player_team.filter(func(c): return _char_is_alive(c)).size(),
		"enemy_alive": enemy_team.filter(func(c): return _char_is_alive(c)).size(),
		"log": combat_log
	}
