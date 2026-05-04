## 灵兽面板 - 灵兽列表/详情/契约/派遣
extends Control

signal spirit_beast_panel_closed()
signal beast_contract_requested(beast_id: String)
signal beast_dispatch_requested(beast_id: String)

# 灵兽数据
var _all_beasts: Array = []
var _combat_beasts: Array = []  # 参战灵兽（最多6只）
var _warehouse_beasts: Array = []  # 仓库灵兽
var _selected_beast: Dictionary = {}
var _current_tab: String = "list"  # list, detail, dispatch

# UI组件
var _main_container: VBoxContainer
var _beast_list_container: ScrollContainer
var _detail_panel: PanelContainer
var _dispatch_panel: PanelContainer
var _tab_buttons: HBoxContainer

func _ready() -> void:
	visible = false
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
	_load_sample_data()

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
	
	_update_beast_list()
	_update_detail_panel()

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
	
	_main_container.add_child(footer)

func _load_sample_data() -> void:
	_all_beasts = [
		{
			"id": "beast_1",
			"name": "小青蛇",
			"type": "蛇类",
			"level": 5,
			"quality": "普通",
			"stats": {"hp": 200, "attack": 25, "defense": 10, "speed": 30},
			"skills": ["毒液喷射", "蜷缩防御"],
			"aptitude": {"hp": 0.6, "attack": 0.7, "defense": 0.5},
			"in_combat": false
		},
		{
			"id": "beast_2",
			"name": "烈火鹰",
			"type": "鸟类",
			"level": 12,
			"quality": "优秀",
			"stats": {"hp": 450, "attack": 65, "defense": 20, "speed": 55},
			"skills": ["烈焰啄", "高空俯冲", "火羽护体"],
			"aptitude": {"hp": 0.7, "attack": 0.85, "defense": 0.6},
			"in_combat": true
		},
		{
			"id": "beast_3",
			"name": "玄水龟",
			"type": "龟类",
			"level": 8,
			"quality": "良好",
			"stats": {"hp": 600, "attack": 20, "defense": 45, "speed": 10},
			"skills": ["水弹", "龟甲防御", "水盾"],
			"aptitude": {"hp": 0.9, "attack": 0.4, "defense": 0.95},
			"in_combat": false
		}
	]
	
	_update_beast_list()
	_update_beast_counts()

func _update_beast_list() -> void:
	var list_vbox = _beast_list_container.get_child(0)
	for child in list_vbox.get_children():
		child.queue_free()
	
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
	type_label.text = "%s | Lv.%d | %s" % [beast.get("type", ""), beast.get("level", 1), beast.get("quality", "普通")]
	info_vbox.add_child(type_label)
	
	var status_label = Label.new()
	status_label.text = "✅ 参战中" if beast.get("in_combat", false) else "📦 仓库中"
	status_label.add_theme_color_override("font_color", Color.GREEN if beast.get("in_combat", false) else Color.GRAY)
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
		"蛇类": return "🐍"
		"鸟类": return "🦅"
		"龟类": return "🐢"
		"狼类": return "🐺"
		"狐类": return "🦊"
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
	header.text = "%s [%s]" % [_selected_beast.get("name", ""), _selected_beast.get("quality", "普通")]
	header.add_theme_font_size_override("font_size", 24)
	detail_vbox.add_child(header)
	
	# 基本信息
	var info_label = Label.new()
	info_label.text = "等级: %d | 类型: %s" % [_selected_beast.get("level", 1), _selected_beast.get("type", "")]
	detail_vbox.add_child(info_label)
	
	# 属性
	var stats_title = Label.new()
	stats_title.text = "--- 属性 ---"
	detail_vbox.add_child(stats_title)
	
	var stats = _selected_beast.get("stats", {})
	var stats_text = "生命: %d\n攻击: %d\n防御: %d\n速度: %d" % [
		stats.get("hp", 0),
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
	var apt_text = "生命资质: %.2f\n攻击资质: %.2f\n防御资质: %.2f" % [
		apt.get("hp", 0),
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
	for skill in skills:
		var skill_label = Label.new()
		skill_label.text = "• %s" % skill
		detail_vbox.add_child(skill_label)

func _update_beast_counts() -> void:
	var header = _main_container.get_child(0)
	var info_label = header.get_child(1)
	var combat_count = _all_beasts.filter(func(b): return b.get("in_combat", false)).size()
	var warehouse_count = _all_beasts.size() - combat_count
	info_label.text = "参战: %d/6 | 仓库: %d" % [combat_count, warehouse_count]

func _on_beast_selected(beast: Dictionary) -> void:
	_selected_beast = beast
	_update_detail_panel()

func _on_list_tab_clicked() -> void:
	_current_tab = "list"
	_detail_panel.visible = true
	_update_beast_list()

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
	
	var contract_btn = Button.new()
	contract_btn.text = "开始契约"
	contract_btn.custom_minimum_size = Vector2(200, 60)
	if not _selected_beast.is_empty():
		contract_btn.pressed.connect(_on_contract_beast.bind(_selected_beast.get("id", "")))
	else:
		contract_btn.disabled = true
	detail_vbox.add_child(contract_btn)

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
	
	var dispatch_btn = Button.new()
	dispatch_btn.text = "派遣当前灵兽"
	dispatch_btn.custom_minimum_size = Vector2(200, 60)
	if not _selected_beast.is_empty():
		dispatch_btn.pressed.connect(_on_dispatch_beast.bind(_selected_beast.get("id", "")))
	else:
		dispatch_btn.disabled = true
	detail_vbox.add_child(dispatch_btn)

func _on_contract_beast(beast_id: String) -> void:
	beast_contract_requested.emit(beast_id)

func _on_dispatch_beast(beast_id: String) -> void:
	beast_dispatch_requested.emit(beast_id)

func _on_close_clicked() -> void:
	visible = false
	spirit_beast_panel_closed.emit()

func _on_summon_clicked() -> void:
	# 打开捕捉界面...
	pass

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

func setup_beasts(beasts: Array) -> void:
	_all_beasts = beasts
	_update_beast_list()
	_update_beast_counts()

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false