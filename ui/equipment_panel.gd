## 装备面板 - 强化/宝石/套装/打造（接入EquipmentSystem真实数据）
extends Control

signal equipment_panel_closed()
signal equipment_enhanced(slot_id: String, level: int)
signal equipment_gem_socketed(slot_id: String, gem_type: String)
signal equipment_crafted(item_id: String)

# 当前角色装备数据
var _character_equipment: Dictionary = {
	"weapon": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
	"armor": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
	"helmet": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
	"boots": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
	"accessory": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}}
}
var _selected_slot: String = "weapon"
var _current_tab: String = "enhance"  # enhance, gem, set, craft

# 背包物品
var _inventory_items: Array = []

# 系统引用
var _equipment_system: Node = null

# UI组件
var _main_container: VBoxContainer
var _equipment_display: Control
var _enhance_panel: PanelContainer
var _gem_panel: PanelContainer
var _set_panel: PanelContainer
var _craft_panel: PanelContainer

func _ready() -> void:
	visible = false
	# 自动截图
	ScreenshotSystem.auto_screenshot("12_装备")
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

# ==================== 真实数据加载 ====================

func setup_system(sys: Node) -> void:
	_equipment_system = sys

func _load_real_data() -> void:
	if not _equipment_system:
		return
	
	# 获取玩家装备列表
	var player_equipment = _equipment_system.get("player_equipment")
	if player_equipment:
		# 重置装备栏
		_character_equipment = {
			"weapon": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
			"armor": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
			"helmet": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
			"boots": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}},
			"accessory": {"id": "", "name": "无装备", "level": 0, "slots": [], "quality": 0, "stats": {}}
		}
		
		for equip in player_equipment:
			var slot_id = _get_slot_key(equip.get("slot", 0))
			if slot_id != "" and _character_equipment.has(slot_id):
				_character_equipment[slot_id] = {
					"id": equip.get("id", ""),
					"name": equip.get("name", "未知装备"),
					"level": equip.get("enhancement_level", 0),
					"slots": equip.get("gems", []),
					"quality": equip.get("quality", 0),
					"stats": equip.get("stats", {}),
					"set_id": equip.get("set_id", ""),
					"gem_slots": equip.get("gem_slots", 0),
				}
	
	# 获取装备模板列表（用于打造面板）
	var templates = _equipment_system.get("equipment_templates")
	if templates:
		_inventory_items = []
		for tid in templates:
			var tpl = templates[tid]
			_inventory_items.append({
				"id": tpl.get("id", ""),
				"name": tpl.get("name", ""),
				"quality": tpl.get("quality", 0),
				"level_req": tpl.get("level_requirement", 1),
				"stats": tpl.get("base_stats", {}),
			})
	
	# 刷新UI
	_refresh_equipment_display()

func _get_slot_key(slot_enum: int) -> String:
	"""将EquipmentSlot枚举转换为面板slot key"""
	match slot_enum:
		0: return "weapon"   # WEAPON
		1: return "armor"    # ARMOR
		2: return "accessory" # ACCESSORY
		_: return ""

func _refresh_equipment_display() -> void:
	# 刷新装备栏显示
	var vbox = _equipment_display.get_child(0)
	var children = vbox.get_children()
	var slot_ids = ["weapon", "helmet", "armor", "boots", "accessory"]
	var slot_names = ["武器", "头盔", "衣服", "鞋子", "饰品"]
	
	for i in range(slot_ids.size()):
		# Button is at index i+1 (after title)
		if i + 1 < children.size():
			var slot_btn = children[i + 1]
			if slot_btn is Button:
				var equip = _character_equipment.get(slot_ids[i], {})
				slot_btn.text = "%s: %s +%d" % [
					slot_names[i],
					equip.get("name", "无装备"),
					equip.get("level", 0)
				]

func _show_enhance_panel() -> void:
	_enhance_panel.visible = true
	_gem_panel.visible = false
	_set_panel.visible = false
	_craft_panel.visible = false
	
	# 清除旧内容
	for child in _enhance_panel.get_children():
		child.queue_free()
	
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
	
	var cost = current_level * 100 + 50
	var cost_label = Label.new()
	cost_label.text = "消耗: 灵石 x%d" % cost
	vbox.add_child(cost_label)
	
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
	
	# 清除旧内容
	for child in _gem_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	_gem_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "宝石镶嵌"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var equip = _character_equipment.get(_selected_slot, {})
	var desc = Label.new()
	desc.text = "当前装备: %s (宝石孔: %d)" % [equip.get("name", ""), equip.get("gem_slots", 0)]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)
	
	var gem_types = [
		{"id": 0, "name": "红宝石(攻击)", "key": "attack"},
		{"id": 1, "name": "蓝宝石(防御)", "key": "defense"},
		{"id": 2, "name": "绿宝石(生命)", "key": "hp"},
		{"id": 3, "name": "黄宝石(速度)", "key": "speed"},
	]
	for gem_type in gem_types:
		var gem_hbox = HBoxContainer.new()
		var gem_label = Label.new()
		gem_label.text = gem_type["name"]
		gem_label.custom_minimum_size.x = 150
		gem_hbox.add_child(gem_label)
		
		var socket_btn = Button.new()
		socket_btn.text = "镶嵌"
		socket_btn.pressed.connect(_on_gem_socket.bind(gem_type["id"]))
		gem_hbox.add_child(socket_btn)
		
		var remove_btn = Button.new()
		remove_btn.text = "摘除"
		remove_btn.pressed.connect(_on_gem_remove.bind(gem_type["id"]))
		gem_hbox.add_child(remove_btn)
		
		vbox.add_child(gem_hbox)

func _show_set_panel() -> void:
	_enhance_panel.visible = false
	_gem_panel.visible = false
	_set_panel.visible = true
	_craft_panel.visible = false
	
	# 清除旧内容
	for child in _set_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	_set_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "套装效果"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	# 从装备系统获取套装信息
	if _equipment_system and _equipment_system.has_method("get_equipment_template"):
		var sets = _equipment_system.get("equipment_sets")
		if sets:
			for set_id in sets:
				var set_data = sets[set_id]
				var set_hbox = HBoxContainer.new()
				var set_label = Label.new()
				set_label.text = "%s" % set_data.get("name", set_id)
				set_label.custom_minimum_size.x = 150
				set_hbox.add_child(set_label)
				
				var bonuses = set_data.get("bonuses", [])
				var effect_text = ""
				for bonus in bonuses:
					effect_text += "%d件: %s\n" % [bonus.get("required", 0), bonus.get("special_effect", "")]
				var effect_label = Label.new()
				effect_label.text = effect_text.strip_edges()
				set_hbox.add_child(effect_label)
				
				vbox.add_child(set_hbox)
		else:
			var no_sets = Label.new()
			no_sets.text = "暂无套装数据"
			vbox.add_child(no_sets)
	else:
		var no_system = Label.new()
		no_system.text = "装备系统未连接"
		vbox.add_child(no_system)

func _show_craft_panel() -> void:
	_enhance_panel.visible = false
	_gem_panel.visible = false
	_set_panel.visible = false
	_craft_panel.visible = true
	
	# 清除旧内容
	for child in _craft_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	_craft_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "装备打造"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	# 从装备系统获取可打造装备
	for item in _inventory_items:
		var recipe_hbox = HBoxContainer.new()
		var name_label = Label.new()
		name_label.text = item.get("name", "")
		name_label.custom_minimum_size.x = 100
		recipe_hbox.add_child(name_label)
		
		var stats_text = ""
		var stats = item.get("stats", {})
		for key in stats:
			stats_text += "%s:%d " % [key, stats[key]]
		var materials_label = Label.new()
		materials_label.text = stats_text
		materials_label.custom_minimum_size.x = 200
		recipe_hbox.add_child(materials_label)
		
		var craft_btn = Button.new()
		craft_btn.text = "打造"
		craft_btn.pressed.connect(_on_craft_item.bind(item.get("id", "")))
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

# ==================== 事件处理 ====================

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
	var equip_id = equip.get("id", "")
	
	if equip_id.is_empty():
		_show_enhance_result("请先装备一件装备！")
		return
	
	# 调用装备系统强化
	if _equipment_system and _equipment_system.has_method("enhance_equipment"):
		var result = _equipment_system.enhance_equipment(equip_id)
		if result.get("success", false):
			_show_enhance_result("强化成功！+%d" % result.get("new_level", 0))
			equipment_enhanced.emit(_selected_slot, result.get("new_level", 0))
		else:
			_show_enhance_result("强化失败: %s" % result.get("reason", ""))
		_load_real_data()
	else:
		_show_enhance_result("装备系统未连接")

func _show_enhance_result(text: String) -> void:
	var vbox = _enhance_panel.get_child(0)
	var result_label = vbox.get_node_or_null("ResultLabel")
	if result_label:
		result_label.text = text

func _on_gem_socket(gem_type: int) -> void:
	var equip = _character_equipment.get(_selected_slot, {})
	var equip_id = equip.get("id", "")
	
	if equip_id.is_empty():
		return
	
	if _equipment_system and _equipment_system.has_method("insert_gem"):
		_equipment_system.insert_gem(equip_id, gem_type)
		_load_real_data()
		_refresh_panels()
	
	equipment_gem_socketed.emit(_selected_slot, str(gem_type))

func _on_gem_remove(gem_type: int) -> void:
	var equip = _character_equipment.get(_selected_slot, {})
	var equip_id = equip.get("id", "")
	
	if equip_id.is_empty():
		return
	
	if _equipment_system and _equipment_system.has_method("remove_gem"):
		# 查找对应宝石的槽位
		var gems = equip.get("slots", [])
		for i in range(gems.size()):
			if gems[i] == gem_type:
				_equipment_system.remove_gem(equip_id, i)
				break
		_load_real_data()
		_refresh_panels()

func _on_craft_item(item_id: String) -> void:
	if _equipment_system and _equipment_system.has_method("create_equipment"):
		var result = _equipment_system.create_equipment(item_id)
		if result:
			_load_real_data()
			_refresh_panels()
	equipment_crafted.emit(item_id)

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
	_load_real_data()
	visible = true

func hide_panel() -> void:
	visible = false
