## 角色创建面板 - 绝对定位版
extends Control

signal character_created(character_data: Dictionary)
signal back_to_menu_requested()

var _character_name: String = ""
var _selected_sect: String = ""
var _selected_sect_name: String = ""
var _attribute_points: Dictionary = {"strength": 0, "spirit": 0, "constitution": 0, "agility": 0, "luck": 0}
var _remaining_points: int = 10

var _name_input: LineEdit = null
var _current_step: int = 0
const TOTAL_STEPS: int = 3

var _sects: Array = [
	{"id": "sect_qingyun", "name": "青云门", "desc": "正道领袖，剑道至尊", "type": "正道"},
	{"id": "sect_hepia", "name": "合欢派", "desc": "诡秘邪道，魅惑众生", "type": "邪道"},
	{"id": "sect_chong", "name": "鬼王宗", "desc": "万毒门旁支，野心勃勃", "type": "邪道"},
	{"id": "sect_shrimp", "name": "史莱克学院", "desc": "怪物学院，只收怪物", "type": "中立"},
	{"id": "sect_qin", "name": "秦家", "desc": "神界势力，血脉传承", "type": "正道"},
	{"id": "sect_chen", "name": "陈家", "desc": "凡人背景，厚积薄发", "type": "散修"},
	{"id": "sect_su", "name": "苏家", "desc": "小门派，资源匮乏", "type": "散修"},
	{"id": "sect_default1", "name": "正道宗门", "desc": "名门正派", "type": "正道"},
	{"id": "sect_default2", "name": "邪道宗门", "desc": "旁门左道", "type": "邪道"},
	{"id": "sect_default3", "name": "散修联盟", "desc": "无派别散修", "type": "散修"},
]

func _ready() -> void:
	visible = false
	_show_step(0)

func _clear_ui() -> void:
	for child in get_children():
		if child.name != "Background":  # 保留背景
			child.queue_free()

func _make_bg() -> ColorRect:
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.04, 0.04, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	return bg

func _center_label(text: String, y: float, size: int = 20, color: Color = Color.WHITE) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	if color != Color.WHITE:
		lbl.add_theme_color_override("font_color", color)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.offset_left = -300
	lbl.offset_right = 300
	lbl.offset_top = int(y) - 15
	lbl.offset_bottom = int(y) + 15
	return lbl

func _center_button(text: String, y: float, w: int = 120) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(w, 42)
	btn.set_anchors_preset(Control.PRESET_CENTER)
	btn.offset_left = -w / 2
	btn.offset_right = w / 2
	btn.offset_top = int(y) - 21
	btn.offset_bottom = int(y) + 21
	return btn

func _show_step(step: int) -> void:
	_current_step = step
	# 清除所有非背景子节点
	for child in get_children():
		child.queue_free()

	# 背景
	add_child(_make_bg())

	match step:
		0: _step_name()
		1: _step_sect()
		2: _step_attrs()
		3: _step_confirm()

	ScreenshotSystem.auto_screenshot("create_step%d" % step)

# ==================== 步骤1: 输入名字 ====================
func _step_name() -> void:
	# 步骤标签
	add_child(_center_label("— 步骤 1/4 —", -160, 16, Color(0.5, 0.6, 0.8)))
	# 标题
	add_child(_center_label("输入角色名称", -110, 30))

	# ★★★ 输入框 - 绝对定位 ★★★
	_name_input = LineEdit.new()
	_name_input.set_anchors_preset(Control.PRESET_CENTER)
	_name_input.offset_left = -200
	_name_input.offset_right = 200
	_name_input.offset_top = -50
	_name_input.offset_bottom = 10
	_name_input.placeholder_text = "请输入角色名称..."
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_font_size_override("font_size", 22)
	# 显式样式
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.15, 0.25, 1.0)
	s.border_color = Color(0.4, 0.5, 0.9, 1.0)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	_name_input.add_theme_stylebox_override("normal", s)
	var sf = s.duplicate()
	sf.border_color = Color(0.6, 0.8, 1.0, 1.0)
	_name_input.add_theme_stylebox_override("focus", sf)
	_name_input.text_submitted.connect(func(_t): _on_next())
	add_child(_name_input)

	# 提示
	add_child(_center_label("输入名称后点击「下一步」或按回车", 40, 13, Color(0.4, 0.4, 0.5)))

	# 按钮
	var next_btn = _center_button("下一步", 110)
	next_btn.pressed.connect(_on_next)
	add_child(next_btn)

	var cancel_btn = _center_button("取消", 110, 100)
	cancel_btn.set_anchors_preset(Control.PRESET_CENTER)
	cancel_btn.offset_left = 60
	cancel_btn.offset_right = 160
	cancel_btn.offset_top = 89
	cancel_btn.offset_bottom = 131
	cancel_btn.pressed.connect(_on_cancel)
	add_child(cancel_btn)

	call_deferred("_focus_input")

func _focus_input() -> void:
	if _name_input and is_instance_valid(_name_input):
		_name_input.grab_focus()

# ==================== 步骤2: 选择门派 ====================
func _step_sect() -> void:
	add_child(_center_label("— 步骤 2/4 —", -180, 16, Color(0.5, 0.6, 0.8)))
	add_child(_center_label("选择门派", -140, 30))

	# 门派列表用VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -280
	vbox.offset_right = 280
	vbox.offset_top = -100
	vbox.offset_bottom = 120
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	vbox.add_child(scroll)

	for sect in _sects:
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.12, 0.12, 0.2, 1)
		ps.set_corner_radius_all(6)
		ps.content_margin_left = 10; ps.content_margin_right = 10
		ps.content_margin_top = 6; ps.content_margin_bottom = 6
		panel.add_theme_stylebox_override("panel", ps)
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		panel.add_child(hbox)
		var info = Label.new()
		info.text = "%s [%s] — %s" % [sect.name, sect.type, sect.desc]
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)
		var b = Button.new()
		b.text = "选择"
		b.custom_minimum_size = Vector2(70, 30)
		b.pressed.connect(func(): _on_sect(sect.id, sect.name))
		hbox.add_child(b)
		list.add_child(panel)

	var back = _center_button("上一步", 155)
	back.pressed.connect(func(): _show_step(0))
	add_child(back)

# ==================== 步骤3: 分配属性 ====================
func _step_attrs() -> void:
	add_child(_center_label("— 步骤 3/4 —", -180, 16, Color(0.5, 0.6, 0.8)))
	var title = _center_label("分配属性点（剩余: %d）" % _remaining_points, -140, 24)
	title.name = "AttrTitle"
	add_child(title)

	var attrs = [
		{"k": "strength", "n": "力量", "d": "物理攻击"},
		{"k": "spirit", "n": "灵力", "d": "法术攻击"},
		{"k": "constitution", "n": "体质", "d": "生命防御"},
		{"k": "agility", "n": "敏捷", "d": "速度闪避"},
		{"k": "luck", "n": "运气", "d": "暴击掉落"},
	]
	var y_start = -90
	for i in range(attrs.size()):
		var a = attrs[i]
		var y = y_start + i * 45
		var row = HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_CENTER)
		row.offset_left = -220
		row.offset_right = 220
		row.offset_top = int(y) - 18
		row.offset_bottom = int(y) + 18
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		add_child(row)
		var lbl = Label.new()
		lbl.text = "%s（%s）" % [a.n, a.d]
		lbl.custom_minimum_size = Vector2(180, 0)
		row.add_child(lbl)
		var val = Label.new()
		val.text = str(_attribute_points[a.k])
		val.custom_minimum_size = Vector2(40, 0)
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.add_theme_font_size_override("font_size", 20)
		row.add_child(val)
		var mn = Button.new(); mn.text = " − "; mn.custom_minimum_size = Vector2(45, 35)
		mn.pressed.connect(func(): _chg(a.k, val, -1))
		row.add_child(mn)
		var pl = Button.new(); pl.text = " + "; pl.custom_minimum_size = Vector2(45, 35)
		pl.pressed.connect(func(): _chg(a.k, val, 1))
		row.add_child(pl)

	var back = _center_button("上一步", 155)
	back.pressed.connect(func(): _show_step(1))
	add_child(back)
	var next = _center_button("下一步", 155)
	next.set_anchors_preset(Control.PRESET_CENTER)
	next.offset_left = 60; next.offset_right = 180
	next.offset_top = 134; next.offset_bottom = 176
	next.pressed.connect(_on_next)
	add_child(next)

func _chg(k: String, lbl: Label, d: int) -> void:
	if d > 0 and _remaining_points <= 0: return
	if d < 0 and _attribute_points[k] <= 0: return
	_attribute_points[k] += d
	_remaining_points -= d
	lbl.text = str(_attribute_points[k])
	var t = get_node_or_null("AttrTitle")
	if t: t.text = "分配属性点（剩余: %d）" % _remaining_points

# ==================== 步骤4: 确认 ====================
func _step_confirm() -> void:
	add_child(_center_label("— 步骤 4/4 —", -160, 16, Color(0.5, 0.6, 0.8)))
	add_child(_center_label("确认角色信息", -120, 30))
	var info = Label.new()
	info.text = "名字: %s\n门派: %s\n\n力量: %d  灵力: %d  体质: %d\n敏捷: %d  运气: %d" % [
		_character_name, _selected_sect_name,
		_attribute_points.get("strength", 0), _attribute_points.get("spirit", 0),
		_attribute_points.get("constitution", 0), _attribute_points.get("agility", 0),
		_attribute_points.get("luck", 0)]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 18)
	info.set_anchors_preset(Control.PRESET_CENTER)
	info.offset_left = -200; info.offset_right = 200
	info.offset_top = -60; info.offset_bottom = 60
	add_child(info)

	var create_btn = _center_button("✓ 创建角色", 120)
	create_btn.pressed.connect(_do_create)
	add_child(create_btn)
	var back = _center_button("上一步", 120)
	back.set_anchors_preset(Control.PRESET_CENTER)
	back.offset_left = -180; back.offset_right = -60
	back.offset_top = 99; back.offset_bottom = 141
	back.pressed.connect(func(): _show_step(2))
	add_child(back)

# ==================== 通用 ====================
func _on_sect(id: String, sname: String) -> void:
	_selected_sect = id
	_selected_sect_name = sname
	_show_step(2)

func _on_next() -> void:
	match _current_step:
		0:
			if _name_input and _name_input.text.strip_edges() != "":
				_character_name = _name_input.text.strip_edges()
			if _character_name == "": return
			_show_step(1)
		1:
			if _selected_sect == "": return
			_show_step(2)
		2:
			if _remaining_points > 0: return
			_show_step(3)
		3:
			_do_create()

func _on_cancel() -> void:
	visible = false
	back_to_menu_requested.emit()

func _do_create() -> void:
	character_created.emit({
		"name": _character_name, "sect": _selected_sect, "sect_name": _selected_sect_name,
		"attributes": _attribute_points.duplicate(), "level": 1, "exp": 0
	})
	visible = false

func show_panel() -> void:
	_character_name = ""
	_selected_sect = ""
	_selected_sect_name = ""
	_attribute_points = {"strength": 0, "spirit": 0, "constitution": 0, "agility": 0, "luck": 0}
	_remaining_points = 10
	_name_input = null
	visible = true
	_show_step(0)
