## 灵兽面板 - 灵兽列表/详情/契约/派遣（接入SpiritBeastSystem真实数据）
extends Control

signal spirit_beast_panel_closed()
signal beast_contract_requested(beast_id: String)
signal beast_dispatch_requested(beast_id: String)

# 灵兽数据
var _all_beasts: Array = []
var _selected_beast: Dictionary = {}
var _current_tab: String = "list"  # list, detail, dispatch

# 系统引用
var _spirit_beast_system: Node = null

# UI组件
var _main_container: VBoxContainer
var _beast_list_container: ScrollContainer
var _detail_panel: PanelContainer
var _tab_buttons: HBoxContainer

func _ready() -> void:
	visible = false
	# 自动截图
	ScreenshotSystem.auto_screenshot("14_灵兽")
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.12, 0.18, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 10)
	add_child(_main_container)

	_build_header()
	_build_tabs()
	_build_content_area()
	_build_footer()

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 60

	var title = Label.new()
	title.text = "🐉 灵兽面板"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)

	var info_label = Label.new()
	info_label.text = "参战: 0/6 | 仓库: 0"
	info_label.custom_minimum_size.x = 200
	info_label.name = "InfoLabel"
	header.add_child(info_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(_on_close_clicked)
	header.add_child(close_btn)

	_main_container.add_child(header)

	var sep = HSeparator.new()
	_main_container.add_child(sep)

func _build_tabs() -> void:
	_tab_buttons = HBoxContainer.new()
	_tab_buttons.custom_minimum_size.y = 50
	_tab_buttons.alignment = BoxContainer.ALIGNMENT_CENTER

	var list_btn = Button.new()
	list_btn.text = "📋 灵兽列表"
	list_btn.pressed.connect(_on_list_tab_clicked)
	_tab_buttons.add_child(list_btn)

	var contract_btn = Button.new()
	contract_btn.text = "🤝 契约灵兽"
	contract_btn.pressed.connect(_on_contract_tab_clicked)
	_tab_buttons.add_child(contract_btn)

	var dispatch_btn = Button.new()
	dispatch_btn.text = "📨 派遣灵兽"
	dispatch_btn.pressed.connect(_on_dispatch_tab_clicked)
	_tab_buttons.add_child(dispatch_btn)

	_main_container.add_child(_tab_buttons)

func _build_content_area() -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.y = 400
	_main_container.add_child(hbox)

	# 左侧灵兽列表
	_beast_list_container = ScrollContainer.new()
	_beast_list_container.custom_minimum_size = Vector2(350, 400)
	var list_vbox = VBoxContainer.new()
	_beast_list_container.add_child(list_vbox)
	hbox.add_child(_beast_list_container)

	# 右侧详情面板
	_detail_panel = PanelContainer.new()
	_detail_panel.custom_minimum_size = Vector2(400, 400)
	var detail_vbox = VBoxContainer.new()
	_detail_panel.add_child(detail_vbox)
	hbox.add_child(_detail_panel)

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 60
	footer.alignment = BoxContainer.ALIGNMENT_CENTER

	var summon_btn = Button.new()
	summon_btn.text = "🔮 捕捉灵兽"
	summon_btn.custom_minimum_size = Vector2(150, 50)
	summon_btn.pressed.connect(_on_summon_clicked)
	footer.add_child(summon_btn)

	var battle_btn = Button.new()
	battle_btn.text = "⚔️ 设置参战"
	battle_btn.custom_minimum_size = Vector2(150, 50)
	battle_btn.pressed.connect(_on_set_battle_clicked)
	footer.add_child(battle_btn)

	var feed_btn = Button.new()
	feed_btn.text = "🍖 喂食"
	feed_btn.custom_minimum_size = Vector2(150, 50)
	feed_btn.pressed.connect(_on_feed_clicked)
	footer.add_child(feed_btn)

	_main_container.add_child(footer)

# ==================== 真实数据加载 ====================

func setup_system(sys: Node) -> void:
	_spirit_beast_system = sys

func _load_real_data() -> void:
	if not _spirit_beast_system:
		return

	_all_beasts = []

	# 获取玩家已契约的灵兽
	var player_beasts = _spirit_beast_system.get("player_beasts")
	if player_beasts:
		for beast in player_beasts:
			var beast_dict = _convert_beast_instance(beast)
			if beast_dict:
				_all_beasts.append(beast_dict)

	# 获取可捕捉的灵兽配置（作为候选列表）
	var beasts_data = _spirit_beast_system.get("beasts_data")
	if beasts_data:
		for beast_id in beasts_data:
			# 检查是否已在玩家列表中
			var already_has = false
			for pb in _all_beasts:
				if pb.get("config_id", "") == beast_id:
					already_has = true
					break
			if not already_has:
				var bd = beasts_data[beast_id]
				_all_beasts.append({
					"id": beast_id,
					"config_id": beast_id,
					"name": bd.get("name", "未知灵兽"),
					"type": _get_beast_type_name(bd.get("beast_type", 0)),
					"level": 1,
					"quality": _get_grade_name(bd.get("grade", 3)),
					"grade": bd.get("grade", 3),
					"stats": bd.get("base_stats", {}),
					"skills": bd.get("skills", []),
					"aptitude": bd.get("growth_rate", {}),
					"in_combat": false,
					"contracted": false,
					"novel_source": bd.get("novel_source", ""),
				})

	_update_beast_list()
	_update_beast_counts()

func _convert_beast_instance(beast) -> Dictionary:
	"""将SpiritBeastInstance转换为Dictionary用于UI显示"""
	if beast == null:
		return {}

	var beast_dict = {
		"id": beast.get("id", ""),
		"config_id": beast.get("beast_data_id", ""),
		"name": beast.get("name", "未知灵兽"),
		"type": _get_beast_type_name(beast.get("beast_type", 0)),
		"level": beast.get("level", 1),
		"quality": _get_grade_name(beast.get("grade", 3)),
		"grade": beast.get("grade", 3),
		"stats": {},
		"skills": beast.get("skills", []),
		"aptitude": {},
		"in_combat": false,
		"contracted": true,
		"loyalty": beast.get("loyalty", 50),
		"novel_source": "",
	}

	# 获取stats - 可能是对象属性或字典
	var stats_obj = beast.get("stats", null)
	if stats_obj:
		if stats_obj is Dictionary:
			beast_dict["stats"] = stats_obj
		else:
			# 可能是对象，尝试读取属性
			beast_dict["stats"] = {
				"max_hp": 100, "attack": 10, "defense": 5, "speed": 10
			}

	return beast_dict

func _get_beast_type_name(type_value) -> String:
	match type_value:
		0: return "战斗型"
		1: return "辅助型"
		2: return "控制型"
		_: return "未知"

func _get_grade_name(grade_value) -> String:
	match grade_value:
		0: return "S级"
		1: return "A级"
		2: return "B级"
		3: return "C级"
		_: return "未知"

func _update_beast_list() -> void:
	var list_vbox = _beast_list_container.get_child(0)
	for child in list_vbox.get_children():
		child.queue_free()

	if _all_beasts.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无灵兽，快去捕捉吧！"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_vbox.add_child(empty_label)
		return

	for beast in _all_beasts:
		var beast_card = _create_beast_card(beast)
		list_vbox.add_child(beast_card)

func _create_beast_card(beast: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(320, 80)

	var hbox = HBoxContainer.new()
	card.add_child(hbox)

	# 灵兽图标
	var icon_label = Label.new()
	icon_label.text = _get_beast_icon(beast.get("type", ""))
	icon_label.add_theme_font_size_override("font_size", 32)
	hbox.add_child(icon_label)

	# 灵兽信息
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size.x = 200

	var name_label = Label.new()
	name_label.text = beast.get("name", "未知")
	name_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(name_label)

	var type_label = Label.new()
	type_label.text = "%s | Lv.%d | %s" % [beast.get("type", ""), beast.get("level", 1), beast.get("quality", "C级")]
	info_vbox.add_child(type_label)

	var status_label = Label.new()
	if beast.get("contracted", false):
		status_label.text = "✅ 已契约"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "📦 可捕捉"
		status_label.add_theme_color_override("font_color", Color.GRAY)
	info_vbox.add_child(status_label)

	hbox.add_child(info_vbox)

	# 选择按钮
	var select_btn = Button.new()
	select_btn.text = "查看"
	select_btn.pressed.connect(_on_beast_selected.bind(beast))
	hbox.add_child(select_btn)

	return card

func _get_beast_icon(type: String) -> String:
	match type:
		"战斗型": return "⚔️"
		"辅助型": return "💚"
		"控制型": return "🌀"
		_: return "🐉"

func _update_detail_panel() -> void:
	var detail_vbox = _detail_panel.get_child(0)
	for child in detail_vbox.get_children():
		child.queue_free()

	if _selected_beast.is_empty():
		var no_select = Label.new()
		no_select.text = "选择一只灵兽查看详情"
		no_select.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_vbox.add_child(no_select)
		return

	# 灵兽名称和品质
	var header = Label.new()
	header.text = "%s [%s]" % [_selected_beast.get("name", ""), _selected_beast.get("quality", "C级")]
	header.add_theme_font_size_override("font_size", 24)
	detail_vbox.add_child(header)

	# 基本信息
	var info_label = Label.new()
	info_label.text = "等级: %d | 类型: %s | 来源: %s" % [_selected_beast.get("level", 1), _selected_beast.get("type", ""), _selected_beast.get("novel_source", "通用")]
	detail_vbox.add_child(info_label)

	# 属性
	var stats_title = Label.new()
	stats_title.text = "--- 属性 ---"
	detail_vbox.add_child(stats_title)

	var stats = _selected_beast.get("stats", {})
	var stats_text = "生命: %d\n攻击: %d\n防御: %d\n速度: %d" % [
		stats.get("max_hp", stats.get("hp", 0)),
		stats.get("attack", 0),
		stats.get("defense", 0),
		stats.get("speed", 0)
	]
	var stats_label = Label.new()
	stats_label.text = stats_text
	detail_vbox.add_child(stats_label)

	# 资质
	var apt_title = Label.new()
	apt_title.text = "--- 成长资质 ---"
	detail_vbox.add_child(apt_title)

	var apt = _selected_beast.get("aptitude", {})
	var apt_text = "生命成长: %.1f\n攻击成长: %.1f\n防御成长: %.1f" % [
		apt.get("max_hp", 0),
		apt.get("attack", 0),
		apt.get("defense", 0)
	]
	var apt_label = Label.new()
	apt_label.text = apt_text
	detail_vbox.add_child(apt_label)

	# 技能
	var skills_title = Label.new()
	skills_title.text = "--- 技能 ---"
	detail_vbox.add_child(skills_title)

	var skills = _selected_beast.get("skills", [])
	if skills.is_empty():
		var no_skills = Label.new()
		no_skills.text = "暂无技能"
		detail_vbox.add_child(no_skills)
	else:
		for skill in skills:
			var skill_label = Label.new()
			skill_label.text = "• %s" % str(skill)
			detail_vbox.add_child(skill_label)

func _update_beast_counts() -> void:
	var header = _main_container.get_child(0)
	var info_label = header.get_node_or_null("InfoLabel")
	if not info_label:
		return
	var combat_count = _all_beasts.filter(func(b): return b.get("in_combat", false)).size()
	var warehouse_count = _all_beasts.filter(func(b): return not b.get("in_combat", false) and b.get("contracted", false)).size()
	info_label.text = "参战: %d/6 | 仓库: %d" % [combat_count, warehouse_count]

# ==================== 事件处理 ====================

func _on_beast_selected(beast: Dictionary) -> void:
	_selected_beast = beast
	_update_detail_panel()

func _on_list_tab_clicked() -> void:
	_current_tab = "list"
	_detail_panel.visible = true
	_load_real_data()

func _on_contract_tab_clicked() -> void:
	_current_tab = "contract"
	_show_contract_interface()

func _on_dispatch_tab_clicked() -> void:
	_current_tab = "dispatch"
	_show_dispatch_interface()

func _show_contract_interface() -> void:
	var detail_vbox = _detail_panel.get_child(0)
	for child in detail_vbox.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "🤝 契约灵兽"
	title.add_theme_font_size_override("font_size", 24)
	detail_vbox.add_child(title)

	var desc = Label.new()
	desc.text = "选择要契约的灵兽，通过战斗捕获后可契约。"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_vbox.add_child(desc)

	# 显示可契约的灵兽
	var contractable = _all_beasts.filter(func(b): return not b.get("contracted", false))
	if contractable.is_empty():
		var empty = Label.new()
		empty.text = "暂无可契约的灵兽"
		detail_vbox.add_child(empty)
	else:
		for beast in contractable:
			var beast_btn = Button.new()
			beast_btn.text = "%s [%s] Lv.%d" % [beast.get("name", ""), beast.get("quality", ""), beast.get("level", 1)]
			beast_btn.custom_minimum_size = Vector2(300, 40)
			beast_btn.pressed.connect(_on_contract_beast.bind(beast.get("id", "")))
			detail_vbox.add_child(beast_btn)

func _show_dispatch_interface() -> void:
	var detail_vbox = _detail_panel.get_child(0)
	for child in detail_vbox.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "📨 派遣灵兽"
	title.add_theme_font_size_override("font_size", 24)
	detail_vbox.add_child(title)

	var desc = Label.new()
	desc.text = "派遣灵兽外出收集资源，需要一定时间返回。"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_vbox.add_child(desc)

	# 显示已契约灵兽
	var contracted = _all_beasts.filter(func(b): return b.get("contracted", false))
	if contracted.is_empty():
		var empty = Label.new()
		empty.text = "暂无已契约灵兽"
		detail_vbox.add_child(empty)
	else:
		for beast in contracted:
			var beast_btn = Button.new()
			beast_btn.text = "%s [%s] Lv.%d" % [beast.get("name", ""), beast.get("quality", ""), beast.get("level", 1)]
			beast_btn.custom_minimum_size = Vector2(300, 40)
			beast_btn.pressed.connect(_on_dispatch_beast.bind(beast.get("id", "")))
			detail_vbox.add_child(beast_btn)

func _on_contract_beast(beast_id: String) -> void:
	# 调用灵兽系统契约
	if _spirit_beast_system and _spirit_beast_system.has_method("contract_beast"):
		_spirit_beast_system.contract_beast(beast_id)
		_load_real_data()
	beast_contract_requested.emit(beast_id)

func _on_dispatch_beast(beast_id: String) -> void:
	beast_dispatch_requested.emit(beast_id)

func _on_close_clicked() -> void:
	visible = false
	spirit_beast_panel_closed.emit()

func _on_summon_clicked() -> void:
	# 调用灵兽系统捕捉
	if _spirit_beast_system and _spirit_beast_system.has_method("capture_beast"):
		# 随机选择一个野生灵兽
		var beasts_data = _spirit_beast_system.get("beasts_data")
		if beasts_data and not beasts_data.is_empty():
			var random_id = beasts_data.keys()[randi() % beasts_data.keys().size()]
			var result = _spirit_beast_system.capture_beast(random_id)
			if result:
				_load_real_data()
				_add_notification("捕捉成功！", "成功捕捉到灵兽")

func _on_set_battle_clicked() -> void:
	if _selected_beast.is_empty():
		return

	var beast_id = _selected_beast.get("id", "")
	var combat_count = _all_beasts.filter(func(b): return b.get("in_combat", false)).size()

	for beast in _all_beasts:
		if beast.get("id", "") == beast_id:
			if beast.get("in_combat", false):
				beast["in_combat"] = false
			else:
				if combat_count < 6:
					beast["in_combat"] = true
			break

	_update_beast_list()
	_update_beast_counts()

func _on_feed_clicked() -> void:
	if _selected_beast.is_empty():
		return
	if _spirit_beast_system and _spirit_beast_system.has_method("feed_beast"):
		_spirit_beast_system.feed_beast(_selected_beast.get("id", ""))
		_load_real_data()

func _add_notification(_title: String, _message: String) -> void:
	# 使用NotificationSystem
	if has_node("/root/NotificationSystem") or has_node("/root/MainScene/NotificationSystem"):
		pass  # 通知系统集成

func setup_beasts(beasts: Array) -> void:
	_all_beasts = beasts
	_update_beast_list()
	_update_beast_counts()

func show_panel() -> void:
	_load_real_data()
	visible = true

func hide_panel() -> void:
	visible = false
