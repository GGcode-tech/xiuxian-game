## 主菜单面板 - 梦幻西游Like游戏主界面
## 顶部角色栏/底部快捷栏/公告/资源显示
extends Control

signal menu_button_pressed(menu_type: String)
signal character_info_requested()
signal resource_updated()

# 顶部角色信息
var _char_name_label: Label
var _char_realm_label: Label
var _char_sect_label: Label
var _char_hp_bar: ProgressBar
var _char_mp_bar: ProgressBar

# 资源显示
var _spirit_stone_label: Label  # 灵石
var _essence_label: Label        # 精华
var _spirit_jade_label: Label   # 灵玉

# 体力/精力
var _stamina_label: Label        # 体力
var _energy_label: Label         # 精力

# 底部快捷栏按钮
var _quick_buttons: Array = []

# 公告区域
var _announcement_label: Label

# 当前选中角色数据
var _current_character: Dictionary = {}

func _ready() -> void:
	visible = false
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 主容器 - 使用GridContainer实现布局
	var main_grid = GridContainer.new()
	main_grid.columns = 3
	main_grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_grid.add_theme_constant_override("column_min_width", 200)
	main_grid.add_theme_constant_override("row_min_height", 60)
	add_child(main_grid)
	
	_build_top_bar(main_grid)
	_build_center_area(main_grid)
	_build_bottom_bar(main_grid)
	_build_right_panel(main_grid)

func _build_top_bar(parent: GridContainer) -> void:
	# 左侧角色信息面板
	var char_panel = PanelContainer.new()
	char_panel.custom_minimum_size = Vector2(250, 100)
	var vbox = VBoxContainer.new()
	char_panel.add_child(vbox)
	
	_char_name_label = Label.new()
	_char_name_label.text = "未创建角色"
	_char_name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_char_name_label)
	
	_char_realm_label = Label.new()
	_char_realm_label.text = "境界: 凡人"
	vbox.add_child(_char_realm_label)
	
	_char_sect_label = Label.new()
	_char_sect_label.text = "门派: 无"
	vbox.add_child(_char_sect_label)
	
	var hp_hbox = HBoxContainer.new()
	_char_hp_bar = ProgressBar.new()
	_char_hp_bar.max_value = 100
	_char_hp_bar.value = 100
	_char_hp_bar.custom_minimum_size = Vector2(200, 20)
	_char_hp_bar.show_percentage = false
	hp_hbox.add_child(Label.new())
	hp_hbox.add_child(_char_hp_bar)
	vbox.add_child(hp_hbox)
	
	var mp_hbox = HBoxContainer.new()
	_char_mp_bar = ProgressBar.new()
	_char_mp_bar.max_value = 100
	_char_mp_bar.value = 50
	_char_mp_bar.custom_minimum_size = Vector2(200, 20)
	_char_mp_bar.show_percentage = false
	mp_hbox.add_child(Label.new())
	mp_hbox.add_child(_char_mp_bar)
	vbox.add_child(mp_hbox)
	
	# 将角色面板放到顶部左侧
	parent.add_child(_create_spacer())
	parent.add_child(_create_spacer())
	parent.add_child(char_panel)

func _build_center_area(parent: GridContainer) -> void:
	# 中央公告区域
	var center_panel = PanelContainer.new()
	center_panel.custom_minimum_size = Vector2(400, 200)
	var vbox = VBoxContainer.new()
	center_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "📢 仙界公告"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	_announcement_label = Label.new()
	_announcement_label.text = "欢迎来到修仙世界！\n请创建角色开始游戏。"
	_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_announcement_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_announcement_label)
	
	# 活动按钮区域
	var activity_hbox = HBoxContainer.new()
	activity_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var dungeon_btn = _create_menu_button("副本", Callable(self, "_on_dungeon_clicked"))
	var sect_btn = _create_menu_button("门派", Callable(self, "_on_sect_clicked"))
	var spirit_btn = _create_menu_button("灵兽", Callable(self, "_on_spirit_beast_clicked"))
	var equip_btn = _create_menu_button("装备", Callable(self, "_on_equipment_clicked"))
	
	activity_hbox.add_child(dungeon_btn)
	activity_hbox.add_child(sect_btn)
	activity_hbox.add_child(spirit_btn)
	activity_hbox.add_child(equip_btn)
	vbox.add_child(activity_hbox)
	
	parent.add_child(center_panel)

func _build_right_panel(parent: GridContainer) -> void:
	# 右侧资源面板
	var resource_panel = PanelContainer.new()
	resource_panel.custom_minimum_size = Vector2(180, 150)
	var vbox = VBoxContainer.new()
	resource_panel.add_child(vbox)
	
	var res_title = Label.new()
	res_title.text = "💰 资源"
	res_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(res_title)
	
	_spirit_stone_label = Label.new()
	_spirit_stone_label.text = "灵石: 0"
	vbox.add_child(_spirit_stone_label)
	
	_essence_label = Label.new()
	_essence_label.text = "精华: 0"
	vbox.add_child(_essence_label)
	
	_spirit_jade_label = Label.new()
	_spirit_jade_label.text = "灵玉: 0"
	vbox.add_child(_spirit_jade_label)
	
	_stamina_label = Label.new()
	_stamina_label.text = "体力: 100/100"
	vbox.add_child(_stamina_label)
	
	_energy_label = Label.new()
	_energy_label.text = "精力: 50/50"
	vbox.add_child(_energy_label)
	
	parent.add_child(_create_spacer())
	parent.add_child(_create_spacer())
	parent.add_child(resource_panel)

func _build_bottom_bar(parent: GridContainer) -> void:
	# 底部快捷栏
	var bottom_panel = PanelContainer.new()
	bottom_panel.custom_minimum_size = Vector2(800, 80)
	var hbox = HBoxContainer.new()
	bottom_panel.add_child(hbox)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var quick_menus = [
		{"icon": "📋", "name": "任务", "id": "quest"},
		{"icon": "⚔️", "name": "副本", "id": "dungeon"},
		{"icon": "🐉", "name": "灵兽", "id": "spirit_beast"},
		{"icon": "⚔️", "name": "装备", "id": "equipment"},
		{"icon": "🏛️", "name": "宗门", "id": "sect"},
		{"icon": "📅", "name": "日常", "id": "daily"},
		{"icon": "🎒", "name": "背包", "id": "inventory"},
		{"icon": "⚙️", "name": "设置", "id": "settings"}
	]
	
	for menu in quick_menus:
		var btn = _create_quick_button(menu["icon"], menu["name"])
		btn.pressed.connect(_on_quick_menu_pressed.bind(menu["id"]))
		hbox.add_child(btn)
		_quick_buttons.append(btn)
	
	# 设置grid位置到底部
	parent.add_child(_create_spacer())
	parent.add_child(bottom_panel)
	parent.add_child(_create_spacer())

func _create_spacer() -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(50, 50)
	return spacer

func _create_menu_button(text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 40)
	return btn

func _create_quick_button(icon: String, name: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 60)
	
	var vbox = VBoxContainer.new()
	btn.add_child(vbox)
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)
	
	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	return btn

func _on_quick_menu_pressed(menu_id: String) -> void:
	menu_button_pressed.emit(menu_id)

func _on_dungeon_clicked() -> void:
	menu_button_pressed.emit("dungeon")

func _on_sect_clicked() -> void:
	menu_button_pressed.emit("sect")

func _on_spirit_beast_clicked() -> void:
	menu_button_pressed.emit("spirit_beast")

func _on_equipment_clicked() -> void:
	menu_button_pressed.emit("equipment")

func update_character_info(character: Dictionary) -> void:
	_current_character = character
	if character.is_empty():
		return
	
	_char_name_label.text = character.get("name", "未知")
	
	var realm_data = DataManager.get_realm(character.get("realm_id", ""))
	_char_realm_label.text = "境界: %s" % realm_data.get("name", "凡人")
	
	_char_sect_label.text = "门派: %s" % character.get("sect_name", "无")
	
	var stats = character.get("base_stats", {})
	_char_hp_bar.max_value = stats.get("max_hp", 100)
	_char_hp_bar.value = character.get("hp", stats.get("max_hp", 100))
	
	_char_mp_bar.max_value = stats.get("max_mp", 50)
	_char_mp_bar.value = character.get("mp", stats.get("max_mp", 50))

func update_resources(resources: Dictionary) -> void:
	_spirit_stone_label.text = "灵石: %d" % resources.get("spirit_stone", 0)
	_essence_label.text = "精华: %d" % resources.get("essence", 0)
	_spirit_jade_label.text = "灵玉: %d" % resources.get("spirit_jade", 0)
	_stamina_label.text = "体力: %d/%d" % [resources.get("stamina", 100), resources.get("max_stamina", 100)]
	_energy_label.text = "精力: %d/%d" % [resources.get("energy", 50), resources.get("max_energy", 50)]
	resource_updated.emit()

func update_announcement(text: String) -> void:
	_announcement_label.text = text

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false