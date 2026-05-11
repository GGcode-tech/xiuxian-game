## 战斗面板 - 5v5回合制战场（接入CombatSystem真实战斗数据）
## 行动条/技能选择/目标选择/战斗日志
extends Control

signal combat_panel_closed()
signal combat_ended(victory: bool)
signal skill_used(skill_id: String, target_id: String)

# 战斗状态
enum CombatState {
	WAITING,      # 等待玩家操作
	SELECTING_SKILL,
	SELECTING_TARGET,
	ANIMATING,
	COMBAT_LOG,
	GAME_OVER
}

var _combat_state: CombatState = CombatState.WAITING

# 战斗单位
var _player_team: Array = []  # 我方5个单位
var _enemy_team: Array = []    # 敌方5个单位
var _turn_order: Array = []    # 速度排序后的行动顺序
var _current_turn_index: int = 0
var _current_actor: Dictionary = {}

# 技能数据
var _available_skills: Array = []
var _selected_skill: Dictionary = {}

# 战斗配置
var _is_auto_battle: bool = false
var _combat_speed: int = 1  # 1, 2, 3

# 系统引用
var _combat_system: Node = null

# UI组件
var _main_container: VBoxContainer
var _battle_field: Control
var _action_bar: HBoxContainer
var _skill_panel: PanelContainer
var _target_panel: PanelContainer
var _combat_log: RichTextLabel
var _turn_indicator: Label

# 战斗统计
var _combat_log_entries: Array = []
var _round_count: int = 1

func _ready() -> void:
	# 自动截图
	ScreenshotSystem.auto_screenshot("09_战斗面板")
	visible = false
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器 - 3行布局
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 5)
	add_child(_main_container)

	_build_top_bar()
	_build_battle_field()
	_build_action_bar()
	_build_skill_panel()
	_build_combat_log()

func _build_top_bar() -> void:
	var top_bar = HBoxContainer.new()
	top_bar.custom_minimum_size.y = 50

	var round_label = Label.new()
	round_label.text = "第1回合"
	round_label.name = "RoundLabel"
	round_label.add_theme_font_size_override("font_size", 20)
	top_bar.add_child(round_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	_turn_indicator = Label.new()
	_turn_indicator.text = "等待中..."
	_turn_indicator.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(_turn_indicator)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer2)

	var auto_btn = Button.new()
	auto_btn.text = "🤖 自动战斗"
	auto_btn.pressed.connect(_on_auto_battle_toggle)
	auto_btn.name = "AutoButton"
	top_bar.add_child(auto_btn)

	var speed_1x = Button.new()
	speed_1x.text = "1x"
	speed_1x.pressed.connect(_on_speed_changed.bind(1))
	top_bar.add_child(speed_1x)

	var speed_2x = Button.new()
	speed_2x.text = "2x"
	speed_2x.pressed.connect(_on_speed_changed.bind(2))
	top_bar.add_child(speed_2x)

	var speed_3x = Button.new()
	speed_3x.text = "3x"
	speed_3x.pressed.connect(_on_speed_changed.bind(3))
	top_bar.add_child(speed_3x)

	var escape_btn = Button.new()
	escape_btn.text = "🏃 逃跑"
	escape_btn.pressed.connect(_on_escape_clicked)
	top_bar.add_child(escape_btn)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(_on_close_clicked)
	top_bar.add_child(close_btn)

	_main_container.add_child(top_bar)

func _build_battle_field() -> void:
	_battle_field = Control.new()
	_battle_field.custom_minimum_size.y = 350
	_main_container.add_child(_battle_field)

	# 左：我方单位
	var player_team_panel = VBoxContainer.new()
	player_team_panel.custom_minimum_size.x = 200

	for i in range(5):
		var unit_card = _create_unit_card(null, true, i)
		unit_card.name = "PlayerUnit_%d" % i
		player_team_panel.add_child(unit_card)

	# 中：VS标识
	var vs_label = Label.new()
	vs_label.text = "⚔️ VS ⚔️"
	vs_label.add_theme_font_size_override("font_size", 48)
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.custom_minimum_size = Vector2(150, 350)

	# 右：敌方单位
	var enemy_team_panel = VBoxContainer.new()
	enemy_team_panel.custom_minimum_size.x = 200

	for i in range(5):
		var unit_card = _create_unit_card(null, false, i)
		unit_card.name = "EnemyUnit_%d" % i
		enemy_team_panel.add_child(unit_card)

	# 行动条
	var turn_order_panel = _build_turn_order_panel()
	turn_order_panel.name = "TurnOrderPanel"

func _create_unit_card(unit_data: Variant, is_player: bool, index: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 60)
	card.set("is_player", is_player)
	card.set("unit_index", index)

	var hbox = HBoxContainer.new()
	card.add_child(hbox)

	# 头像区域
	var avatar_label = Label.new()
	avatar_label.text = "👤" if is_player else "👹"
	avatar_label.add_theme_font_size_override("font_size", 24)
	avatar_label.custom_minimum_size.x = 40
	hbox.add_child(avatar_label)

	# 信息区域
	var info_vbox = VBoxContainer.new()

	var name_label = Label.new()
	name_label.text = unit_data.get("name", "空位") if unit_data else "空位"
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.name = "NameLabel"
	info_vbox.add_child(name_label)

	var hp_bar = ProgressBar.new()
	hp_bar.max_value = 100
	hp_bar.value = unit_data.get("hp", 100) if unit_data else 0
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(100, 12)
	hp_bar.name = "HPBar"
	info_vbox.add_child(hp_bar)

	var status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	status_label.name = "StatusLabel"
	info_vbox.add_child(status_label)

	hbox.add_child(info_vbox)

	return card

func _build_turn_order_panel() -> Control:
	var panel = HBoxContainer.new()
	panel.custom_minimum_size.y = 40
	panel.alignment = BoxContainer.ALIGNMENT_CENTER

	panel.add_child(Label.new())  # placeholder for now

	return panel

func _build_action_bar() -> void:
	_action_bar = HBoxContainer.new()
	_action_bar.custom_minimum_size.y = 60
	_action_bar.alignment = BoxContainer.ALIGNMENT_CENTER

	var attack_btn = Button.new()
	attack_btn.text = "⚔️ 普通攻击"
	attack_btn.custom_minimum_size = Vector2(120, 50)
	attack_btn.pressed.connect(_on_normal_attack)
	_action_bar.add_child(attack_btn)

	var skill_btn = Button.new()
	skill_btn.text = "📜 技能"
	skill_btn.custom_minimum_size = Vector2(120, 50)
	skill_btn.pressed.connect(_on_skill_button_pressed)
	_action_bar.add_child(skill_btn)

	var beast_btn = Button.new()
	beast_btn.text = "🐉 灵兽"
	beast_btn.custom_minimum_size = Vector2(120, 50)
	beast_btn.pressed.connect(_on_beast_button_pressed)
	_action_bar.add_child(beast_btn)

	var item_btn = Button.new()
	item_btn.text = "🎒 物品"
	item_btn.custom_minimum_size = Vector2(120, 50)
	item_btn.pressed.connect(_on_item_button_pressed)
	_action_bar.add_child(item_btn)

	var defend_btn = Button.new()
	defend_btn.text = "🛡️ 防御"
	defend_btn.custom_minimum_size = Vector2(120, 50)
	defend_btn.pressed.connect(_on_defend)
	_action_bar.add_child(defend_btn)

	_main_container.add_child(_action_bar)

func _build_skill_panel() -> void:
	_skill_panel = PanelContainer.new()
	_skill_panel.custom_minimum_size = Vector2(600, 150)
	_skill_panel.visible = false

	var scroll = ScrollContainer.new()
	_skill_panel.add_child(scroll)

	var hbox = HBoxContainer.new()
	scroll.add_child(hbox)

	_main_container.add_child(_skill_panel)

func _build_target_panel() -> void:
	_target_panel = PanelContainer.new()
	_target_panel.custom_minimum_size = Vector2(600, 80)
	_target_panel.visible = false

	var hbox = HBoxContainer.new()
	_target_panel.add_child(hbox)

	var title = Label.new()
	title.text = "选择目标: "
	hbox.add_child(title)

	_main_container.add_child(_target_panel)

func _build_combat_log() -> void:
	var log_container = HBoxContainer.new()
	log_container.custom_minimum_size = Vector2(0, 120)
	_main_container.add_child(log_container)

	_combat_log = RichTextLabel.new()
	_combat_log.custom_minimum_size = Vector2(0, 120)
	_combat_log.bbcode_enabled = true
	_combat_log.scroll_following = true
	log_container.add_child(_combat_log)

# ==================== 真实数据接入 ====================

func setup_system(sys: Node) -> void:
	_combat_system = sys

## 从角色字典中提取战斗所需属性（兼容Character格式）
func _extract_combat_stats(char: Dictionary) -> Dictionary:
	var base_stats = char.get("base_stats", {})
	var derived_stats = char.get("derived_stats", {})
	var max_hp = derived_stats.get("max_hp", base_stats.get("max_hp", 100))
	var attack = derived_stats.get("attack", base_stats.get("attack", 10))
	var defense = derived_stats.get("defense", base_stats.get("defense", 5))
	var speed = derived_stats.get("speed", base_stats.get("speed", 10))
	var spirit = derived_stats.get("spirit", base_stats.get("spirit", 10))

	return {
		"id": char.get("id", "unknown"),
		"name": char.get("name", "未知"),
		"hp": char.get("hp", max_hp),
		"max_hp": max_hp,
		"mp": char.get("mp", spirit * 5),
		"max_mp": spirit * 5,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"spirit": spirit,
		"is_alive": char.get("is_alive", true),
		"is_defending": false,
		"techniques": char.get("techniques", []),
		"_source": char,  # 保留原始引用
	}

## 从敌人配置构建战斗单位
func _create_combat_unit(enemy_config: Dictionary) -> Dictionary:
	var level = enemy_config.get("level", 1)
	var count = enemy_config.get("count", 1)
	var units: Array = []
	for i in range(count):
		units.append({
			"id": "enemy_%s_%d_%d" % [enemy_config.get("id", "e"), randi(), i],
			"name": enemy_config.get("name", "敌人"),
			"hp": level * 50,
			"max_hp": level * 50,
			"mp": level * 15,
			"max_mp": level * 15,
			"attack": level * 5,
			"defense": level * 3,
			"speed": level * 3,
			"spirit": level * 3,
			"is_alive": true,
			"is_defending": false,
		})
	return units[0] if units.size() == 1 else units

## 构建战斗单位列表（从敌人配置数组）
func _build_enemy_team_from_config(wave_enemies: Array) -> Array:
	var team: Array = []
	for enemy_config in wave_enemies:
		var unit = _create_combat_unit(enemy_config)
		if unit is Array:
			team.append_array(unit)
		else:
			team.append(unit)
	return team

## 构建玩家队伍（从GameManager角色数据）
func _build_player_team() -> Array:
	var team: Array = []
	# 从GameManager获取玩家角色
	for cid in GameManager.all_characters:
		var c = GameManager.all_characters[cid]
		if c.get("is_alive", true):
			team.append(_extract_combat_stats(c))
			if team.size() >= 5:
				break
	# 如果没有角色，创建默认角色
	if team.is_empty():
		team.append({
			"id": "player_default",
			"name": "修仙者",
			"hp": 100, "max_hp": 100,
			"mp": 50, "max_mp": 50,
			"attack": 10, "defense": 5,
			"speed": 10, "spirit": 10,
			"is_alive": true, "is_defending": false,
		})
	return team

## 从角色技能列表构建可用技能
func _build_available_skills(char: Dictionary) -> Array:
	var skills: Array = []
	var techniques = char.get("techniques", [])
	for tech in techniques:
		if tech is String:
			var skill_data = DataManager.get_technique(tech)
			if skill_data and not skill_data.is_empty():
				skills.append({
					"id": tech,
					"name": skill_data.get("name", tech),
					"mp_cost": skill_data.get("mp_cost", 10),
					"damage": skill_data.get("damage", 0),
					"target_type": skill_data.get("target_type", "single"),
				})
		elif tech is Dictionary:
			skills.append({
				"id": tech.get("id", ""),
				"name": tech.get("name", "技能"),
				"mp_cost": tech.get("mp_cost", 10),
				"damage": tech.get("damage", 0),
				"target_type": tech.get("target_type", "single"),
			})
	return skills

# ==================== 战斗开始/显示 ====================

func start_combat(player_team: Array, enemy_team: Array) -> void:
	_player_team = player_team
	_enemy_team = enemy_team
	_round_count = 1
	_combat_log_entries.clear()
	_combat_log.clear()

	_update_unit_display()
	_update_turn_order()
	_update_round_label()

	_combat_state = CombatState.WAITING
	_add_combat_log("⚔️ 战斗开始!")
	visible = true

func start_combat_from_enemies(wave_enemies: Array) -> void:
	"""从敌人配置开始战斗（由副本系统调用）"""
	var player_team = _build_player_team()
	var enemy_team = _build_enemy_team_from_config(wave_enemies)
	start_combat(player_team, enemy_team)

func show_panel() -> void:
	# 不自动加载样本数据，需要通过start_combat()传入数据
	visible = true

func hide_panel() -> void:
	visible = false

# ==================== 回合逻辑 ====================

func _update_turn_order() -> void:
	# 按速度排序
	_turn_order = []
	_turn_order.append_array(_player_team)
	_turn_order.append_array(_enemy_team)
	_turn_order.sort_custom(func(a, b): return a.get("speed", 0) > b.get("speed", 0))

	_current_turn_index = 0
	_current_actor = _turn_order[_current_turn_index] if _turn_order.size() > 0 else {}
	_update_turn_indicator()
	_update_turn_order_panel()

func _update_turn_indicator() -> void:
	var actor_name = _current_actor.get("name", "无人")
	var is_player = _current_actor.get("id", "").begins_with("player")
	_turn_indicator.text = "当前行动: %s [%s]" % [actor_name, "我方" if is_player else "敌方"]

func _update_turn_order_panel() -> void:
	var turn_panel = _battle_field.get_node_or_null("TurnOrderPanel")
	if not turn_panel:
		return

	for child in turn_panel.get_children():
		child.queue_free()

	for unit in _turn_order:
		if not unit.get("is_alive", true):
			continue
		var indicator = Label.new()
		var is_player = unit.get("id", "").begins_with("player")
		indicator.text = "👤" if is_player else "👹"
		indicator.add_theme_font_size_override("font_size", 20)
		turn_panel.add_child(indicator)

func _update_unit_display() -> void:
	for i in range(5):
		# 玩家单位
		var player_card = _battle_field.get_node_or_null("PlayerUnit_%d" % i)
		if player_card:
			var unit = _player_team[i] if i < _player_team.size() else null
			_update_unit_card(player_card, unit)

		# 敌方单位
		var enemy_card = _battle_field.get_node_or_null("EnemyUnit_%d" % i)
		if enemy_card:
			var unit = _enemy_team[i] if i < _enemy_team.size() else null
			_update_unit_card(enemy_card, unit)

func _update_unit_card(card: PanelContainer, unit: Variant) -> void:
	if not unit:
		return

	var info_vbox = card.get_child(0)
	var name_label = info_vbox.get_node_or_null("NameLabel")
	var hp_bar = info_vbox.get_node_or_null("HPBar")
	var status_label = info_vbox.get_node_or_null("StatusLabel")

	if name_label:
		name_label.text = unit.get("name", "")
	if hp_bar:
		hp_bar.max_value = unit.get("max_hp", 100)
		hp_bar.value = unit.get("hp", 0)
	if status_label:
		if not unit.get("is_alive", true):
			status_label.text = "已阵亡"
			status_label.add_theme_color_override("font_color", Color.RED)
		else:
			status_label.text = ""

func _show_skill_panel() -> void:
	_skill_panel.visible = true
	var hbox = _skill_panel.get_child(0).get_child(0)

	# 清除旧技能按钮
	for child in hbox.get_children():
		child.queue_free()

	# 从当前角色获取可用技能
	var current_source = _current_actor.get("_source", {})
	_available_skills = _build_available_skills(current_source)

	# 如果没有技能列表，使用默认基础技能
	if _available_skills.is_empty():
		_available_skills = [
			{"id": "basic_attack", "name": "基础剑法", "mp_cost": 0, "damage": 50, "target_type": "single"},
		]

	for skill in _available_skills:
		var skill_btn = Button.new()
		skill_btn.custom_minimum_size = Vector2(120, 80)
		skill_btn.text = "%s\nMP:%d" % [skill.get("name", ""), skill.get("mp_cost", 0)]
		skill_btn.pressed.connect(_on_skill_selected.bind(skill))
		hbox.add_child(skill_btn)

	_combat_state = CombatState.SELECTING_SKILL

func _show_target_panel(target_type: String) -> void:
	_target_panel.visible = true
	_skill_panel.visible = false

	# 根据目标类型显示可选择目标
	match target_type:
		"single", "enemy_all", "ally_all":
			_highlight_targets(target_type)

	_combat_state = CombatState.SELECTING_TARGET

func _highlight_targets(target_type: String) -> void:
	# 高亮可选择的目标单位
	var targets = []
	match target_type:
		"single":
			targets = _enemy_team if _is_current_actor_player() else _player_team
		"enemy_all":
			targets = _enemy_team
		"ally_all":
			targets = _player_team

	# 标记目标...

func _is_current_actor_player() -> bool:
	return _current_actor.get("id", "").begins_with("player")

func _add_combat_log(text: String) -> void:
	_combat_log_entries.append(text)
	_combat_log.append_text("[%s]\n" % text)

# ==================== 玩家操作 ====================

func _on_normal_attack() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return

	# 自动选择第一个存活的敌方目标
	var target = null
	for e in _enemy_team:
		if e.get("is_alive", true):
			target = e
			break
	if target:
		_execute_attack(_current_actor, target, 1.0)
		_next_turn()

func _on_skill_button_pressed() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return

	_show_skill_panel()

func _on_beast_button_pressed() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return

	# 显示灵兽技能...
	_add_combat_log("灵兽技能暂时不可用")

func _on_item_button_pressed() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return

	_add_combat_log("物品暂时不可用")

func _on_defend() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return

	_current_actor["is_defending"] = true
	_add_combat_log("%s 进入防御状态" % _current_actor.get("name", ""))
	_next_turn()

func _on_skill_selected(skill: Dictionary) -> void:
	_selected_skill = skill
	_skill_panel.visible = false
	_show_target_panel(skill.get("target_type", "single"))

func _on_skill_target_selected(target: Dictionary) -> void:
	if _selected_skill.is_empty():
		return

	skill_used.emit(_selected_skill.get("id", ""), target.get("id", ""))
	_execute_skill(_current_actor, target, _selected_skill)
	_next_turn()

# ==================== 战斗计算 ====================

func _execute_attack(attacker: Dictionary, target: Dictionary, damage_mult: float) -> void:
	var base_damage = attacker.get("attack", 10)
	var defense = target.get("defense", 0)
	var damage = int(base_damage * damage_mult - defense * 0.5)
	damage = max(damage, 1)

	target["hp"] = max(target["hp"] - damage, 0)
	if target["hp"] <= 0:
		target["is_alive"] = false

	_add_combat_log("%s 攻击 %s, 造成 %d 点伤害" % [attacker.get("name", ""), target.get("name", ""), damage])
	_update_unit_display()
	_check_combat_end()

func _execute_skill(caster: Dictionary, target: Dictionary, skill: Dictionary) -> void:
	var skill_name = skill.get("name", "技能")
	var mp_cost = skill.get("mp_cost", 0)

	# 检查MP
	if mp_cost > 0:
		var current_mp = caster.get("mp", 0)
		if current_mp < mp_cost:
			_add_combat_log("%s 灵力不足！" % caster.get("name", ""))
			return
		caster["mp"] = current_mp - mp_cost

	# 计算伤害
	var base_damage = skill.get("damage", 0)
	if base_damage > 0:
		var defense = target.get("defense", 0)
		var damage = max(int(base_damage - defense * 0.3), 1)
		target["hp"] = max(target["hp"] - damage, 0)
		if target["hp"] <= 0:
			target["is_alive"] = false
		_add_combat_log("%s 使用 %s 对 %s 造成 %d 伤害" % [caster.get("name", ""), skill_name, target.get("name", ""), damage])
	else:
		_add_combat_log("%s 使用了 %s" % [caster.get("name", ""), skill_name])

	_update_unit_display()
	_check_combat_end()

func _next_turn() -> void:
	_combat_state = CombatState.WAITING

	# 找到下一个存活的单位
	var attempts = 0
	while true:
		_current_turn_index = (_current_turn_index + 1) % _turn_order.size()
		_current_actor = _turn_order[_current_turn_index]
		attempts += 1
		if _current_actor.get("is_alive", true) or attempts >= _turn_order.size():
			break

	if attempts >= _turn_order.size():
		# 本轮结束，开始下一轮
		_round_count += 1
		_update_round_label()
		_reset_defense_flags()

	_update_turn_indicator()

	# 如果是敌方回合，AI自动行动
	if not _is_current_actor_player():
		_execute_enemy_turn()
	# 如果是玩家回合且自动战斗开启，自动执行
	elif _is_auto_battle:
		_auto_execute_player_turn()

func _reset_defense_flags() -> void:
	for unit in _turn_order:
		unit["is_defending"] = false

func _execute_enemy_turn() -> void:
	# 简单的AI：随机攻击一个玩家单位
	var alive_targets = _player_team.filter(func(u): return u.get("is_alive", true))
	if alive_targets.size() > 0:
		var target = alive_targets[randi() % alive_targets.size()]
		_execute_attack(_current_actor, target, 1.0)
		_next_turn()

func _check_combat_end() -> void:
	var player_alive = _player_team.any(func(u): return u.get("is_alive", true))
	var enemy_alive = _enemy_team.any(func(u): return u.get("is_alive", true))

	if not player_alive:
		_combat_state = CombatState.GAME_OVER
		_add_combat_log("💀 战斗失败...")
		# 通知战斗系统
		if _combat_system and _combat_system.has_method("_end_combat"):
			_combat_system._end_combat(0)  # PLAYER_LOSE
		combat_ended.emit(false)
	elif not enemy_alive:
		_combat_state = CombatState.GAME_OVER
		_add_combat_log("🏆 战斗胜利!")
		# 通知战斗系统
		if _combat_system and _combat_system.has_method("_end_combat"):
			_combat_system._end_combat(1)  # PLAYER_WIN
		combat_ended.emit(true)

func _update_round_label() -> void:
	var round_label = _main_container.get_node_or_null("RoundLabel")
	if round_label:
		round_label.text = "第%d回合" % _round_count

func _on_auto_battle_toggle() -> void:
	_is_auto_battle = not _is_auto_battle
	var auto_btn = _main_container.get_node_or_null("TopBar/AutoButton")
	if auto_btn:
		auto_btn.text = "🤖 自动战斗 [%s]" % ("ON" if _is_auto_battle else "OFF")
	# 如果开启自动战斗且当前是玩家回合，立即执行
	if _is_auto_battle and _combat_state == CombatState.WAITING and _is_current_actor_player():
		_auto_execute_player_turn()


func _auto_execute_player_turn() -> void:
	if not _is_auto_battle:
		return
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return
	# 自动使用普通攻击
	_on_normal_attack()


func _on_speed_changed(speed: int) -> void:
	_combat_speed = speed
	_add_combat_log("⚡ 战斗速度: %dx" % speed)

func _on_escape_clicked() -> void:
	_add_combat_log("🏃 成功逃跑!")
	combat_ended.emit(false)
	visible = false

func _on_close_clicked() -> void:
	visible = false
	combat_panel_closed.emit()
