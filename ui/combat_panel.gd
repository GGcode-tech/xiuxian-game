## 战斗面板 - 5v5回合制战场
## 行动条/技能选择/目标选择/战斗日志
extends Control

signal combat_panel_closed()
signal combat_ended(victory: bool)
signal skill_used(skill_id: String, target_id: String)
signal beast_used(beast_id: String, target_id: String)

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

func _load_sample_combat() -> void:
	_player_team = [
		{"id": "p1", "name": "主角", "hp": 500, "max_hp": 500, "attack": 80, "defense": 30, "speed": 50, "is_alive": true},
		{"id": "p2", "name": "小青", "hp": 300, "max_hp": 300, "attack": 40, "defense": 20, "speed": 60, "is_alive": true},
		{"id": "p3", "name": "阿石", "hp": 400, "max_hp": 400, "attack": 50, "defense": 40, "speed": 40, "is_alive": true},
		{"id": "p4", "name": "小红", "hp": 250, "max_hp": 250, "attack": 60, "defense": 15, "speed": 70, "is_alive": true},
		{"id": "p5", "name": "老张", "hp": 350, "max_hp": 350, "attack": 45, "defense": 35, "speed": 35, "is_alive": true}
	]
	
	_enemy_team = [
		{"id": "e1", "name": "山贼头目", "hp": 600, "max_hp": 600, "attack": 70, "defense": 25, "speed": 45, "is_alive": true},
		{"id": "e2", "name": "山贼甲", "hp": 200, "max_hp": 200, "attack": 30, "defense": 15, "speed": 40, "is_alive": true},
		{"id": "e3", "name": "山贼乙", "hp": 200, "max_hp": 200, "attack": 30, "defense": 15, "speed": 40, "is_alive": true},
		{"id": "e4", "name": "山贼丙", "hp": 200, "max_hp": 200, "attack": 30, "defense": 15, "speed": 40, "is_alive": true},
		{"id": "e5", "name": "山贼丁", "hp": 200, "max_hp": 200, "attack": 30, "defense": 15, "speed": 40, "is_alive": true}
	]
	
	_available_skills = [
		{"id": "skill_1", "name": "基础剑法", "mp_cost": 0, "damage": 50, "target_type": "single"},
		{"id": "skill_2", "name": "御剑术", "mp_cost": 20, "damage": 80, "target_type": "single"},
		{"id": "skill_3", "name": "群体治疗", "mp_cost": 30, "heal": 100, "target_type": "ally_all"},
		{"id": "skill_4", "name": "天剑降世", "mp_cost": 50, "damage": 150, "target_type": "enemy_all"}
	]
	
	_update_turn_order()

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
	var is_player = _current_actor.get("id", "").begins_with("p")
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
		var is_player = unit.get("id", "").begins_with("p")
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
	pass

func _is_current_actor_player() -> bool:
	return _current_actor.get("id", "").begins_with("p")

func _add_combat_log(text: String) -> void:
	_combat_log_entries.append(text)
	_combat_log.append_text("[%s]\n" % text)

func _on_normal_attack() -> void:
	if _combat_state != CombatState.WAITING:
		return
	if not _is_current_actor_player():
		return
	
	# 自动选择第一个敌方目标
	var target = _enemy_team[0] if _enemy_team.size() > 0 else null
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
	_add_combat_log("%s 使用了 %s" % [caster.get("name", ""), skill_name])
	
	skill_used.emit(skill.get("id", ""), target.get("id", ""))
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
		combat_ended.emit(false)
	elif not enemy_alive:
		_combat_state = CombatState.GAME_OVER
		_add_combat_log("🏆 战斗胜利!")
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

func _on_speed_changed(speed: int) -> void:
	_combat_speed = speed

func _on_escape_clicked() -> void:
	_add_combat_log("🏃 成功逃跑!")
	combat_ended.emit(false)
	visible = false

func _on_close_clicked() -> void:
	visible = false
	combat_panel_closed.emit()

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

func show_panel() -> void:
	if _player_team.is_empty():
		_load_sample_combat()
		_update_unit_display()
	visible = true

func hide_panel() -> void:
	visible = false