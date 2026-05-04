## 装备面板 - 强化/宝石/套装/打造
extends Control

signal equipment_panel_closed()
signal equipment_enhanced(slot_id: String, level: int)
signal equipment_gem_socketed(slot_id: String, gem_type: String)
signal equipment_crafted(item_id: String)

# 当前角色装备数据
var _character_equipment: Dictionary = {
	"weapon": {"id": "equip_1", "name": "新手剑", "level": 0, "slots": []},
	"armor": {"id": "equip_2", "name": "布衣", "level": 0, "slots": []},
	"helmet": {"id": "equip_3", "name": "木簪", "level": 0, "slots": []},
	"boots": {"id": "equip_4", "name": "草鞋", "level": 0, "slots": []},
	"accessory": {"id": "equip_5", "name": "无", "level": 0, "slots": []}
}
var _selected_slot: String = "weapon"
var _current_tab: String = "enhance"  # enhance, gem, set, craft

# 背包物品
var _inventory_items: Array = []
var _enhance_materials: Dictionary = {
	"stone": 10,
	"crystal": 5,
	"gold": 1000
}

# UI组件
var _main_container: VBoxContainer
var _equipment_display: Control
var _enhance_panel: PanelContainer
var _gem_panel: PanelContainer
var _set_panel: PanelContainer
var _craft_panel: PanelContainer

func _ready() -> void:
	visible = false
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 主容器
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 10)
	add_child(_main_container)
	
	_build_header()
	_build_main_content()
	_build_footer()
	_load_sample_data()

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 60
	
	var title = Label.new()
	title.text = "⚔️ 装备面板"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	
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

func _build_main_content() -> void:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.y = 450
	_main_container.add_child(hbox)
	
	# 左侧：角色装备展示
	_equipment_display = _build_equipment_display()
	hbox.add_child(_equipment_display)
	
	# 右侧：操作面板
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(450, 450)
	hbox.add_child(right_panel)
	
	# 标签页按钮
	var tab_hbox = HBoxContainer.new()
	tab_hbox.custom_minimum_size.y = 50
	
	var enhance_btn = Button.new()
	enhance_btn.text = "🔨 强化"
	enhance_btn.pressed.connect(_on_enhance_tab_clicked)
	tab_hbox.add_child(enhance_btn)
	
	var gem_btn = Button.new()
	gem_btn.text = "💎 宝石"
	gem_btn.pressed.connect(_on_gem_tab_clicked)
	tab_hbox.add_child(gem_btn)
	
	var set_btn = Button.new()
	set_btn.text = "📦 套装"
	set_btn.pressed.connect(_on_set_tab_clicked)
	tab_hbox.add_child(set_btn)
	
	var craft_btn = Button.new()
	craft_btn.text = "🔧 打造"
	craft_btn.pressed.connect(_on_craft_tab_clicked)
	tab_hbox.add_child(craft_btn)
	
	right_panel.add_child(tab_hbox)
	
	# 操作面板容器
	_enhance_panel = PanelContainer.new()
	_enhance_panel.custom_minimum_size = Vector2(450, 400)
	right_panel.add_child(_enhance_panel)
	
	_gem_panel = PanelContainer.new()
	_gem_panel.custom_minimum_size = Vector2(450, 400)
	_gem_panel.visible = false
	right_panel.add_child(_gem_panel)
	
	_set_panel = PanelContainer.new()
	_set_panel.custom_minimum_size = Vector2(450, 400)
	_set_panel.visible = false
	right_panel.add_child(_set_panel)
	
	_craft_panel = PanelContainer.new()
	_craft_panel.custom_minimum_size = Vector2(450, 400)
	_craft_panel.visible = false
	right_panel.add_child(_craft_panel)
	
	_show_enhance_panel()

func _build_equipment_display() -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 450)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "装备栏"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var slots = [
		{"id": "weapon", "name": "武器", "pos": Vector2(150, 50)},
		{"id": "helmet", "name": "头盔", "pos": Vector2(150, 120)},
		{"id": "armor", "name": "衣服", "pos": Vector2(150, 190)},
		{"id": "boots", "name": "鞋子", "pos": Vector2(150, 260)},
		{"id": "accessory", "name": "饰品", "pos": Vector2(150, 330)}
	]
	
	for slot_data in slots:
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(200, 50)
		slot_btn.text = "%s: %s +%d" % [
			slot_data["name"],
			_character_equipment[slot_data["id"]].get("name", "无"),
			_character_equipment[slot_data["id"]].get("level", 0)
		]
		slot_btn.pressed.connect(_on_slot_selected.bind(slot_data["id"]))
		vbox.add_child(slot_btn)
	
	return panel

func _show_enhance_panel() -> void:
	_enhance_panel.visible = true
	_gem_panel.visible = false
	_set_panel.visible = false
	_craft_panel.visible = false
	
	var vbox = VBoxContainer.new()
	_enhance_panel.add_child(vbox)
	
	var equip = _character_equipment.get(_selected_slot, {})
	var title = Label.new()
	title.text = "强化 %s" % equip.get("name", "装备")
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var current_level = equip.get("level", 0)
	var level_label = Label.new()
	level_label.text = "当前强化等级: +%d" % current_level
	vbox.add_child(level_label)
	
	var success_rate = _calculate_enhance_success_rate(current_level)
	var rate_label = Label.new()
	rate_label.text = "成功率: %.1f%%" % (success_rate * 100)
	vbox.add_child(rate_label)
	
	var cost_label = Label.new()
	cost_label.text = "消耗: 强化石 x1, 灵石 x%d" % (current_level * 100 + 50)
	vbox.add_child(cost_label)
	
	var materials_label = Label.new()
	materials_label.text = "拥有: 强化石 x%d, 水晶 x%d, 金币 x%d" % [
		_enhance_materials.get("stone", 0),
		_enhance_materials.get("crystal", 0),
		_enhance_materials.get("gold", 0)
	]
	vbox.add_child(materials_label)
	
	var enhance_btn = Button.new()
	enhance_btn.text = "🔨 开始强化"
	enhance_btn.custom_minimum_size = Vector2(200, 60)
	enhance_btn.pressed.connect(_on_enhance_clicked)
	vbox.add_child(enhance_btn)
	
	var result_label = Label.new()
	result_label.text = ""
	result_label.name = "ResultLabel"
	vbox.add_child(result_label)

func _show_gem_panel() -> void:
	_enhance_panel.visible = false
	_gem_panel.visible = true
	_set_panel.visible = false
	_craft_panel.visible = false
	
	var vbox = VBoxContainer.new()
	_gem_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "宝石镶嵌"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "选择宝石类型进行镶嵌或摘除"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	
	var gem_types = ["红宝石(攻击)", "蓝宝石(防御)", "绿宝石(生命)", "黄宝石(速度)"]
	for gem_type in gem_types:
		var gem_hbox = HBoxContainer.new()
		var gem_label = Label.new()
		gem_label.text = gem_type
		gem_label.custom_minimum_size.x = 150
		gem_hbox.add_child(gem_label)
		
		var socket_btn = Button.new()
		socket_btn.text = "镶嵌"
		socket_btn.pressed.connect(_on_gem_socket.bind(gem_type))
		gem_hbox.add_child(socket_btn)
		
		var remove_btn = Button.new()
		remove_btn.text = "摘除"
		remove_btn.pressed.connect(_on_gem_remove.bind(gem_type))
		gem_hbox.add_child(remove_btn)
		
		vbox.add_child(gem_hbox)

func _show_set_panel() -> void:
	_enhance_panel.visible = false
	_gem_panel.visible = false
	_set_panel.visible = true
	_craft_panel.visible = false
	
	var vbox = VBoxContainer.new()
	_set_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "套装效果"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var sets = [
		{"name": "青云套装", "parts": 2, "effect": "攻击+10%"},
		{"name": "玄铁套装", "parts": 4, "effect": "防御+15%"},
		{"name": "天蚕套装", "parts": 5, "effect": "生命+20%"}
	]
	
	for set_data in sets:
		var set_hbox = HBoxContainer.new()
		var set_label = Label.new()
		set_label.text = "%s (%d件)" % [set_data["name"], set_data["parts"]]
		set_label.custom_minimum_size.x = 150
		set_hbox.add_child(set_label)
		
		var effect_label = Label.new()
		effect_label.text = set_data["effect"]
		set_hbox.add_child(effect_label)
		
		vbox.add_child(set_hbox)

func _show_craft_panel() -> void:
	_enhance_panel.visible = false
	_gem_panel.visible = false
	_set_panel.visible = false
	_craft_panel.visible = true
	
	var vbox = VBoxContainer.new()
	_craft_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "装备打造"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var recipes = [
		{"name": "铁剑", "materials": "铁矿石x5, 木柄x2", "level_req": 1},
		{"name": "钢甲", "materials": "钢锭x10, 皮革x5", "level_req": 5},
		{"name": "精钢剑", "materials": "精钢x15, 宝石x2", "level_req": 10}
	]
	
	for recipe in recipes:
		var recipe_hbox = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = recipe["name"]
		name_label.custom_minimum_size.x = 80
		recipe_hbox.add_child(name_label)
		
		var materials_label = Label.new()
		materials_label.text = recipe["materials"]
		materials_label.custom_minimum_size.x = 200
		recipe_hbox.add_child(materials_label)
		
		var craft_btn = Button.new()
		craft_btn.text = "打造"
		craft_btn.pressed.connect(_on_craft_item.bind(recipe["name"]))
		recipe_hbox.add_child(craft_btn)
		
		vbox.add_child(recipe_hbox)

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 60
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var inventory_btn = Button.new()
	inventory_btn.text = "🎒 背包"
	inventory_btn.custom_minimum_size = Vector2(120, 50)
	inventory_btn.pressed.connect(_on_inventory_clicked)
	footer.add_child(inventory_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.x = 30
	footer.add_child(spacer)
	
	var stats_btn = Button.new()
	stats_btn.text = "📊 属性总览"
	stats_btn.custom_minimum_size = Vector2(120, 50)
	stats_btn.pressed.connect(_on_stats_clicked)
	footer.add_child(stats_btn)
	
	_main_container.add_child(footer)

func _load_sample_data() -> void:
	_inventory_items = [
		{"id": "item_stone", "name": "强化石", "count": 10},
		{"id": "item_crystal", "name": "水晶", "count": 5},
		{"id": "item_gem_red", "name": "红宝石", "count": 3}
	]

func _calculate_enhance_success_rate(level: int) -> float:
	# 强化成功率随等级降低
	var rates = [1.0, 0.95, 0.90, 0.85, 0.80, 0.75, 0.70, 0.65, 0.60, 0.55, 0.50]
	if level < rates.size():
		return rates[level]
	return 0.3

func _on_slot_selected(slot_id: String) -> void:
	_selected_slot = slot_id
	_refresh_panels()

func _refresh_panels() -> void:
	for child in _enhance_panel.get_children():
		child.queue_free()
	for child in _gem_panel.get_children():
		child.queue_free()
	
	match _current_tab:
		"enhance": _show_enhance_panel()
		"gem": _show_gem_panel()
		"set": _show_set_panel()
		"craft": _show_craft_panel()

func _on_enhance_tab_clicked() -> void:
	_current_tab = "enhance"
	_show_enhance_panel()

func _on_gem_tab_clicked() -> void:
	_current_tab = "gem"
	_show_gem_panel()

func _on_set_tab_clicked() -> void:
	_current_tab = "set"
	_show_set_panel()

func _on_craft_tab_clicked() -> void:
	_current_tab = "craft"
	_show_craft_panel()

func _on_enhance_clicked() -> void:
	var equip = _character_equipment.get(_selected_slot, {})
	var current_level = equip.get("level", 0)
	var success_rate = _calculate_enhance_success_rate(current_level)
	
	# 检查材料
	if _enhance_materials.get("stone", 0) < 1:
		_show_enhance_result("材料不足！")
		return
	
	# 消耗材料
	_enhance_materials["stone"] -= 1
	
	# 成功率判定
	if randf() < success_rate:
		_character_equipment[_selected_slot]["level"] = current_level + 1
		_show_enhance_result("强化成功！+%d" % (current_level + 1))
		equipment_enhanced.emit(_selected_slot, current_level + 1)
	else:
		_show_enhance_result("强化失败...")
	
	_refresh_panels()

func _show_enhance_result(text: String) -> void:
	var vbox = _enhance_panel.get_child(0)
	var result_label = vbox.get_node("ResultLabel")
	if result_label:
		result_label.text = text

func _on_gem_socket(gem_type: String) -> void:
	equipment_gem_socketed.emit(_selected_slot, gem_type)

func _on_gem_remove(gem_type: String) -> void:
	# 摘除宝石...
	pass

func _on_craft_item(item_name: String) -> void:
	equipment_crafted.emit(item_name)

func _on_close_clicked() -> void:
	visible = false
	equipment_panel_closed.emit()

func _on_inventory_clicked() -> void:
	# 显示背包界面...
	pass

func _on_stats_clicked() -> void:
	# 显示属性总览...
	pass

func setup_equipment(equipment: Dictionary) -> void:
	_character_equipment = equipment
	_refresh_panels()

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false