## 对话面板UI - NPC对话界面
## 深色主题，与游戏其他面板一致
extends Control

signal dialogue_panel_closed()
signal choice_made(npc_id: String, choice_index: int)

# 当前对话的NPC ID
var _current_npc_id: String = ""

# UI组件
var _main_container: VBoxContainer
var _npc_name_label: Label
var _dialogue_text: RichTextLabel
var _choices_container: VBoxContainer
var _close_button: Button
var _relationship_label: Label


func _ready() -> void:
	visible = false
	_custom_init()


func _custom_init() -> void:
	# 背景（半透明黑色遮罩）
	var bg = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# 对话面板居中
	var panel_container = PanelContainer.new()
	panel_container.set_anchors_preset(Control.PRESET_CENTER)
	panel_container.offset_left = -350
	panel_container.offset_right = 350
	panel_container.offset_top = -250
	panel_container.offset_bottom = 250
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.97)
	panel_style.border_color = Color(0.5, 0.4, 0.7)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(20)
	panel_container.add_theme_stylebox_override("panel", panel_style)
	add_child(panel_container)

	# 主容器
	_main_container = VBoxContainer.new()
	_main_container.add_theme_constant_override("separation", 12)
	panel_container.add_child(_main_container)

	# 顶部：NPC名字 + 关系 + 关闭按钮
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 40
	_main_container.add_child(header)

	_npc_name_label = Label.new()
	_npc_name_label.text = "NPC"
	_npc_name_label.add_theme_font_size_override("font_size", 22)
	_npc_name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))
	header.add_child(_npc_name_label)

	_relationship_label = Label.new()
	_relationship_label.text = ""
	_relationship_label.add_theme_font_size_override("font_size", 14)
	_relationship_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	header.add_child(_relationship_label)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	_close_button = Button.new()
	_close_button.text = "✕"
	_close_button.custom_minimum_size = Vector2(36, 36)
	_close_button.pressed.connect(_on_close_pressed)
	header.add_child(_close_button)

	# 分隔线
	var sep = HSeparator.new()
	_main_container.add_child(sep)

	# 对话文本区
	_dialogue_text = RichTextLabel.new()
	_dialogue_text.custom_minimum_size.y = 120
	_dialogue_text.bbcode_enabled = true
	_dialogue_text.fit_content = true
	_dialogue_text.scroll_active = false
	_dialogue_text.add_theme_font_size_override("normal_font_size", 16)
	_main_container.add_child(_dialogue_text)

	# 选项区标题
	var choice_label = Label.new()
	choice_label.text = "— 选择 —"
	choice_label.add_theme_font_size_override("font_size", 14)
	choice_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_main_container.add_child(choice_label)

	# 选项按钮容器
	_choices_container = VBoxContainer.new()
	_choices_container.add_theme_constant_override("separation", 8)
	_main_container.add_child(_choices_container)


## 显示对话
func show_dialogue(dialogue_data: Dictionary) -> void:
	if dialogue_data.is_empty():
		return

	_current_npc_id = dialogue_data.get("npc_data", {}).get("id", "")
	var npc_data = dialogue_data.get("npc_data", {})
	var npc_name = npc_data.get("name", "未知")
	var relationship = npc_data.get("relationship", 0)
	var personality = npc_data.get("personality", "")
	var realm_id = npc_data.get("realm_id", "")

	# 设置NPC信息
	_npc_name_label.text = "💬 %s" % npc_name
	_relationship_label.text = "关系: %d | %s" % [relationship, personality]

	# 设置对话文本
	var dialogue_text = dialogue_data.get("text", "……")
	_dialogue_text.text = dialogue_text

	# 清空旧选项
	for child in _choices_container.get_children():
		child.queue_free()

	# 动态生成选项按钮
	var choices = dialogue_data.get("choices", [])
	_add_choice_buttons(choices)

	show()
	get_tree().paused = true


func _add_choice_buttons(choices: Array) -> void:
	for i in range(choices.size()):
		var btn = Button.new()
		btn.text = "%s" % choices[i]
		btn.custom_minimum_size = Vector2(200, 40)

		# 按钮样式
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.15, 0.12, 0.25, 0.9)
		btn_style.border_color = Color(0.4, 0.35, 0.6)
		btn_style.set_border_width_all(1)
		btn_style.set_corner_radius_all(6)
		btn_style.set_content_margin_all(10)
		btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover = btn_style.duplicate()
		btn_hover.bg_color = Color(0.25, 0.2, 0.4, 0.95)
		btn_hover.border_color = Color(0.6, 0.5, 0.8)
		btn.add_theme_stylebox_override("hover", btn_hover)

		var btn_pressed = btn_style.duplicate()
		btn_pressed.bg_color = Color(0.35, 0.3, 0.55, 0.95)
		btn.add_theme_stylebox_override("pressed", btn_pressed)

		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))

		btn.pressed.connect(_on_choice_pressed.bind(i))
		_choices_container.add_child(btn)


func _on_choice_pressed(index: int) -> void:
	choice_made.emit(_current_npc_id, index)


func _on_close_pressed() -> void:
	close_dialogue()


func close_dialogue() -> void:
	_current_npc_id = ""
	hide()
	get_tree().paused = false
	dialogue_panel_closed.emit()


## 更新对话文本（选择后显示NPC回复）
func update_response(text: String) -> void:
	_dialogue_text.text = text
	# 清空选项按钮
	for child in _choices_container.get_children():
		child.queue_free()

	# 添加"继续"按钮
	var btn = Button.new()
	btn.text = "继续"
	btn.custom_minimum_size = Vector2(160, 36)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.12, 0.25, 0.9)
	btn_style.border_color = Color(0.4, 0.35, 0.6)
	btn_style.set_border_width_all(1)
	btn_style.set_corner_radius_all(6)
	btn_style.set_content_margin_all(10)
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	btn.pressed.connect(_on_close_pressed)
	_choices_container.add_child(btn)
