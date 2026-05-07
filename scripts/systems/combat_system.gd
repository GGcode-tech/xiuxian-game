## 战斗系统 - 回合制战斗逻辑
class_name CombatSystem extends Node

enum CombatResult {
	PLAYER_WIN,
	PLAYER_LOSE,
	DRAW,
	FLED
}

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
		return a.get("derived_stats", {}).get("speed", 10) > b.get("derived_stats", {}).get("speed", 10)
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
		
		if not character.is_alive:
			continue
		
		turn_started.emit(character)
		
		# 检查控制效果
		if _is_controlled(character):
			combat_log.append("%s 被控制，无法行动" % character.name)
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
	for effect in character.status_effects:
		if effect.type == StatusEffect.EffectType.CONTROL:
			return true
	return false

func _ai_action(character) -> void:
	var alive_players = player_team.filter(func(c): return c.is_alive)
	if alive_players.is_empty():
		return
	
	# 简单AI：随机攻击一个存活的玩家
	var target = alive_players[randi() % alive_players.size()]
	
	# 检查是否有强力技能
	var skills = _get_available_skills(character)
	
	if skills.size() > 0 and randf() < 0.4:
		# 使用技能
		var skill = skills[randi() % skills.size()]
		_use_skill(character, skill, target)
	else:
		# 普通攻击
		_normal_attack(character, target)


func _get_available_skills(character) -> Array:
	var available = []
	# TODO: 从角色功法中获取可用技能
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
	var attack = attacker.get("derived_stats", {}).get("attack", 10)
	var defense = defender.get("derived_stats", {}).get("defense", 5)
	
	# 伤害计算
	var damage = maxi(1, attack - defense / 2)
	
	# 暴击
	var crit_rate = GameConstants.base_crit_rate + attacker.get("derived_stats", {}).get("crit_rate", 0.0)
	if randf() < crit_rate:
		damage = int(damage * GameConstants.base_crit_damage)
		combat_log.append("💥 %s 暴击！" % attacker.name)
	
	# 闪避
	var dodge = GameConstants.dodge_base + defender.get("derived_stats", {}).get("dodge", 0.0)
	if randf() < dodge:
		damage = 0
		combat_log.append("💨 %s 闪避了攻击" % defender.name)
	
	# 随机浮动 ±10%
	damage = int(damage * randf_range(0.9, 1.1))
	
	if damage > 0:
		# 减防效果
		var defend_buff = defender.status_effects.filter(func(e): return e.id == "defending")
		if not defend_buff.is_empty():
			damage = int(damage * 0.5)
		
		defender.take_damage(damage)
		character_damaged.emit(defender, damage)
		combat_log.append("⚔️ %s 攻击 %s，造成 %d 伤害" % [attacker.name, defender.name, damage])
	else:
		combat_log.append("⚔️ %s 的攻击被 %s 闪避" % [attacker.name, defender.name])


func _use_skill(caster, skill_id: String, target) -> void:
	var skill_data = DataManager.get_skill(skill_id)
	if not skill_data:
		return
	
	# 消耗灵力
	if not caster.use_mp(skill_data.mp_cost):
		combat_log.append("%s 灵力不足" % caster.name)
		return
	
	# 技能冷却
	caster.cooldowns[skill_id] = skill_data.cooldown
	
	match skill_data.target_type:
		SkillData.TargetType.SELF:
			_apply_skill_effect(caster, caster, skill_data)
		SkillData.TargetType.SINGLE_ENEMY:
			_apply_skill_effect(caster, target, skill_data)
		SkillData.TargetType.ALL_ENEMY:
			for enemy in enemy_team:
				if enemy.is_alive:
					_apply_skill_effect(caster, enemy, skill_data)
		SkillData.TargetType.SINGLE_ALLY:
			_apply_skill_effect(caster, target, skill_data)
		SkillData.TargetType.ALL_ALLY:
			for ally in player_team:
				if ally.is_alive:
					_apply_skill_effect(caster, ally, skill_data)


func _apply_skill_effect(caster, target, skill) -> void:
	# 伤害效果
	if skill.damage_multiplier > 0:
		var base_damage = caster.get("derived_stats", {}).get("attack", 10) * skill.damage_multiplier
		var defense = target.get("derived_stats", {}).get("defense", 5)
		var damage = maxi(1, int(base_damage - defense * 0.3))
		target.take_damage(damage)
		character_damaged.emit(target, damage)
		combat_log.append("✨ %s 使用 %s 对 %s 造成 %d 伤害" % [caster.name, skill.name, target.name, damage])
	
	# 治疗效果
	if skill.heal_amount > 0:
		var heal = skill.heal_amount + caster.get("derived_stats", {}).get("spirit", 10) * 0.5
		target.heal(int(heal))
		character_healed.emit(target, int(heal))
		combat_log.append("💚 %s 使用 %s 恢复 %s %d 生命" % [caster.name, skill.name, target.name, int(heal)])
	
	# 状态效果
	for effect_data in skill.effects:
		var effect = StatusEffect.new()
		effect.id = effect_data.get("id", "")
		effect.name = effect_data.get("name", "")
		effect.type = effect_data.get("type", StatusEffect.EffectType.BUFF)
		effect.remaining_duration = effect_data.get("duration", 3)
		effect.effects = effect_data.get("effects", {})
		target.status_effects.append(effect)
		combat_log.append("🌀 %s 获得 %s 效果" % [target.name, effect.name])


func _defend(character) -> void:
	var defend_effect = StatusEffect.create_defense_reduce(1, -999)  # 临时防御翻倍
	defend_effect.id = "defending"
	defend_effect.name = "防御"
	defend_effect.type = StatusEffect.EffectType.BUFF
	character.status_effects.append(defend_effect)
	combat_log.append("🛡️ %s 进入防御姿态" % character.name)


func _attempt_flee(character) -> void:
	var flee_chance = 0.3
	var avg_enemy_speed = 0.0
	for enemy in enemy_team:
		if enemy.is_alive:
			avg_enemy_speed += enemy.get("derived_stats", {}).get("speed", 10)
	avg_enemy_speed /= maxi(1, enemy_team.filter(func(e): return e.is_alive).size())
	
	var player_speed = character.get("derived_stats", {}).get("speed", 10)
	flee_chance += (player_speed - avg_enemy_speed) * 0.02
	flee_chance = clamp(flee_chance, 0.05, 0.8)
	
	if randf() < flee_chance:
		_end_combat(CombatResult.FLED)
		combat_log.append("🏃 %s 成功逃跑！" % character.name)
	else:
		combat_log.append("🏃 %s 逃跑失败！" % character.name)


func _use_combat_item(character, target) -> void:
	# TODO: 实现战斗中使用物品
	combat_log.append("%s 使用了物品" % character.name)


# ==================== 战斗结束 ====================

func _check_combat_end() -> void:
	var player_alive = player_team.any(func(c): return c.is_alive)
	var enemy_alive = enemy_team.any(func(c): return c.is_alive)
	
	if not player_alive:
		_end_combat(CombatResult.PLAYER_LOSE)
	elif not enemy_alive:
		_end_combat(CombatResult.PLAYER_WIN)

func _end_combat(result: CombatResult) -> void:
	is_in_combat = false
	
	# 清理状态效果
	for character in player_team:
		character.status_effects = character.status_effects.filter(func(e): return e.type == StatusEffect.EffectType.BUFF)
	for character in enemy_team:
		character.status_effects.clear()
	
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
		var realm = DataManager.get_realm(enemy.realm_id)
		if realm:
			total_exp += realm.tier * 100
		total_spirit_stones += randi_range(10, 50)
		
		# 掉落物品
		if randf() < 0.3:
			var drop = _generate_drop(enemy)
			if drop:
				drops.append(drop)
	
	# 分配奖励
	for character in player_team:
		if character.is_alive:
			character.realm_exp += total_exp / player_team.filter(func(c): return c.is_alive).size()
			for drop in drops:
				character.add_item(drop)
	
	var family = GameManager.get_family(player_team[0].family_id) if player_team.size() > 0 else null
	if family:
		family.add_resource("spirit_stone", total_spirit_stones)


func _generate_drop(enemy):
	# TODO: 根据敌人类型生成掉落
	return null


func get_combat_summary() -> Dictionary:
	return {
		"turn_count": current_turn,
		"player_alive": player_team.filter(func(c): return c.is_alive).size(),
		"enemy_alive": enemy_team.filter(func(c): return c.is_alive).size(),
		"log": combat_log
	}
