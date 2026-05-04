## 角色创建面板 - 梦幻西游Like角色创建
## 步骤：小说背景→名字→门派→属性点分配
extends Control

signal character_created(character_data: Dictionary)
signal back_to_menu_requested()

# 小说数据
var _novels: Array = []
var _selected_novel_index: int = 0
var _selected_novel_name: String = ""

# 创建数据
var _character_name: String = ""
var _selected_sect: String = ""
var _attribute_points: Dictionary = {
	"strength": 0,    # 力量
	"spirit": 0,      # 灵力
	"constitution": 0, # 体质
	"agility": 0,     # 敏捷
	"luck": 0        # 运气
}
var _remaining_points: int = 10

# UI组件
var _main_vbox: VBoxContainer
var _step_indicator: Label
var _content_container: Control
var _button_container: HBoxContainer

# 当前步骤
var _current_step: int = 0  # 0=小说选择, 1=名字输入, 2=门派选择, 3=属性分配, 4=确认
const TOTAL_STEPS: int = 4

# 门派数据
var _sects_by_novel: Dictionary = {}

func _ready() -> void:
	visible = false
	_custom_init()

func _custom_init() -> void:
	# 创建背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 创建主容器
	_main_vbox = VBoxContainer.new()
	_main_vbox.set_anchors_preset(Control.PRESET_CENTER)
	_main_vbox.position = Vector2(-300, -300)
	_main_vbox.custom_minimum_size = Vector2(600, 500)
	add_child(_main_vbox)
	
	_setup_styles()
	_populate_novel_data()
	_show_step(0)

func _setup_styles() -> void:
	pass

func _populate_novel_data() -> void:
	_novels = NovelDB.get_cultivation_systems_overview()
	# 预设门派数据（实际从数据库读取）
	_sects_by_novel = {
		"凡人修仙传": [
			{"id": "sect_chen", "name": "陈家", "desc": "凡人背景，厚积薄发"},
			{"id": "sect_su", "name": "苏家", "desc": "小门派，资源匮乏"},
			{"id": "sect_yao", "name": "天南修仙界", "desc": "散修聚集地"}
		],
		"星辰变": [
			{"id": "sect_qin", "name": "秦家", "desc": "神界势力，血脉传承"},
			{"id": "sect_fan", "name": "凡界星辰阁", "desc": "宇宙星辰之力"}
		],
		"诛仙": [
			{"id": "sect_qingyun", "name": "青云门", "desc": "正道领袖，剑道至尊"},
			{"id": "sect_hepia", "name": "合欢派", "desc": "诡秘邪道，魅惑众生"},
			{"id": "sect_chong", "name": "鬼王宗", "desc": "万毒门旁支，野心勃勃"}
		],
		"斗罗大陆": [
			{"id": "sect_shrimp", "name": "史莱克学院", "desc": "怪物学院，只收怪物"},
			{"id": "sect_tian", "name": "天斗帝国", "desc": "帝国皇室，武魂传承"}
		]
	}
	# 其他小说添加默认门派
	var default_sects = [
		{"id": "sect_default1", "name": "正道宗门", "desc": "名门正派"},
		{"id": "sect_default2", "name": "邪道宗门", "desc": "旁门左道"},
		{"id": "sect_default3", "name": "散修联盟", "desc": "无派别散修"}
	]
	for novel in _novels:
		var name = novel.get("novel", "")
		if not _sects_by_novel.has(name):
			_sects_by_novel[name] = default_sects.duplicate()

func _show_step(step: int) -> void:
	_current_step = step
	_clear_content()
	
	_step_indicator = Label.new()
	_step_indicator.text = "步骤 %d/%d" % [step + 1, TOTAL_STEPS]
	_step_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_vbox.add_child(_step_indicator)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 20
	_main_vbox.add_child(spacer1)
	
	_content_container = Control.new()
	_main_vbox.add_child(_content_container)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 20
	_main_vbox.add_child(spacer2)
	
	_button_container = HBoxContainer.new()
	_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_vbox.add_child(_button_container)
	
	match step:
		0: _show_novel_selection()
		1: _show_name_input()
		2: _show_sect_selection()
		3: _show_attribute分配()
		4: _show_confirmation()

func _clear_content() -> void:
	for child in _main_vbox.get_children():
		child.queue_free()

func _show_novel_selection() -> void:
	var title = Label.new()
	title.text = "选择小说背景"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_content_container.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 300)
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	_content_container.add_child(scroll)
	
	for i in range(_novels.size()):
		var novel = _novels[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(450, 60)
		btn.text = "%s\n境界:%d 功法:%d" % [novel.get("novel", ""), novel.get("realm_count", 0), novel.get("technique_count", 0)]
		btn.pressed.connect(_on_novel_selected.bind(i))
		vbox.add_child(btn)

func _on_novel_selected(index: int) -> void:
	_selected_novel_index = index
	_selected_novel_name = _novels[index].get("novel", "")
	_show_step(1)

func _show_name_input() -> void:
	var title = Label.new()
	title.text = "输入角色名称"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_content_container.add_child(title)
	
	var name_input = LineEdit.new()
	name_input.custom_minimum_size = Vector2(300, 50)
	name_input.placeholder_text = "请输入角色名称"
	name_input.text_submitted.connect(_on_name_submitted)
	_content_container.add_child(name_input)
	
	# 聚焦并等待
	await get_tree().create_timer(0.1).timeout
	name_input.grab_focus()

func _on_name_submitted(text: String) -> void:
	if text.strip_edges() != "":
		_character_name = text.strip_edges()
		_show_step(2)

func _show_sect_selection() -> void:
	var title = Label.new()
	title.text = "选择门派: %s" % _selected_novel_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_content_container.add_child(title)
	
	var sects = _sects_by_novel.get(_selected_novel_name, [])
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 280)
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	_content_container.add_child(scroll)
	
	for sect in sects:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		var info = Label.new()
		info.text = "%s\n%s" % [sect.get("name", ""), sect.get("desc", "")]
		hbox.add_child(info)
		
		var select_btn = Button.new()
		select_btn.text = "选择"
		select_btn.pressed.connect(_on_sect_selected.bind(sect.get("id", "")))
		hbox.add_child(select_btn)
		
		vbox.add_child(panel)

func _on_sect_selected(sect_id: String) -> void:
	_selected_sect = sect_id
	_show_step(3)

func _show_attribute分配() -> void:
	var title = Label.new()
	title.text = "分配属性点 (剩余: %d)" % _remaining_points
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_content_container.add_child(title)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 250)
	_content_container.add_child(vbox)
	
	var attributes = [
		{"key": "strength", "name": "力量", "desc": "影响物理攻击"},
		{"key": "spirit", "name": "灵力", "desc": "影响法术攻击"},
		{"key": "constitution", "name": "体质", "desc": "影响生命值和防御"},
		{"key": "agility", "name": "敏捷", "desc": "影响速度和闪避"},
		{"key": "luck", "name": "运气", "desc": "影响暴击和掉落"}
	]
	
	for attr in attributes:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		var name_label = Label.new()
		name_label.text = "%s (%s)" % [attr["name"], attr["desc"]]
		name_label.custom_minimum_size.x = 200
		hbox.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = str(_attribute_points[attr["key"]])
		value_label.custom_minimum_size.x = 50
		hbox.add_child(value_label)
		
		var minus_btn = Button.new()
		minus_btn.text = "-"
		minus_btn.pressed.connect(_on_attr_minus.bind(attr["key"], value_label))
		hbox.add_child(minus_btn)
		
		var plus_btn = Button.new()
		plus_btn.text = "+"
		plus_btn.pressed.connect(_on_attr_plus.bind(attr["key"], value_label))
		hbox.add_child(plus_btn)

func _on_attr_minus(key: String, label: Label) -> void:
	if _attribute_points[key] > 0:
		_attribute_points[key] -= 1
		_remaining_points += 1
		label.text = str(_attribute_points[key])
		_update_attribute_title()

func _on_attr_plus(key: String, label: Label) -> void:
	if _remaining_points > 0:
		_attribute_points[key] += 1
		_remaining_points -= 1
		label.text = str(_attribute_points[key])
		_update_attribute_title()

func _update_attribute_title() -> void:
	var title = _content_container.get_child(0)
	if title:
		title.text = "分配属性点 (剩余: %d)" % _remaining_points

func _show_confirmation() -> void:
	var title = Label.new()
	title.text = "确认角色信息"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	_content_container.add_child(title)
	
	var info = Label.new()
	info.text = """小说: %s
名字: %s
门派: %s

属性点分配:
  力量: %d
  灵力: %d
  体质: %d
  敏捷: %d
  运气: %d""" % [
		_selected_novel_name,
		_character_name,
		_selected_sect,
		_attribute_points["strength"],
		_attribute_points["spirit"],
		_attribute_points["constitution"],
		_attribute_points["agility"],
		_attribute_points["luck"]
	]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_container.add_child(info)

func _add_navigation_buttons() -> void:
	var back_btn = Button.new()
	back_btn.text = "上一步"
	back_btn.pressed.connect(_on_back_pressed)
	_button_container.add_child(back_btn)
	
	var next_btn = Button.new()
	next_btn.text = "下一步" if _current_step < TOTAL_STEPS else "创建角色"
	next_btn.pressed.connect(_on_next_pressed)
	_button_container.add_child(next_btn)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "取消"
	cancel_btn.pressed.connect(_on_cancel_pressed)
	_button_container.add_child(cancel_btn)

func _on_back_pressed() -> void:
	if _current_step > 0:
		_show_step(_current_step - 1)
	else:
		back_to_menu_requested.emit()

func _on_next_pressed() -> void:
	match _current_step:
		0: _show_step(1)
		1: 
			if _character_name != "":
				_show_step(2)
		2:
			if _selected_sect != "":
				_show_step(3)
		3:
			if _remaining_points == 0:
				_show_step(4)
		4: _create_character()

func _on_cancel_pressed() -> void:
	visible = false
	back_to_menu_requested.emit()

func _create_character() -> void:
	var character_data = {
		"name": _character_name,
		"novel": _selected_novel_name,
		"sect": _selected_sect,
		"attributes": _attribute_points.duplicate(),
		"level": 1,
		"exp": 0
	}
	character_created.emit(character_data)
	visible = false

func show_panel() -> void:
	# 重置状态
	_current_step = 0
	_character_name = ""
	_selected_sect = ""
	_attribute_points = {"strength": 0, "spirit": 0, "constitution": 0, "agility": 0, "luck": 0}
	_remaining_points = 10
	_populate_novel_data()
	_show_step(0)
	_add_navigation_buttons()
	visible = true