## 通知系统UI - 显示游戏内通知和消息
extends Control

@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var event_popup: PanelContainer = $EventPopup

# 通知场景
const NOTIFICATION_SCENE = preload("res://ui/notification_item.tscn")

var _active_notifications: Array[Control] = []


func _ready() -> void:
	EventManager.notification_added.connect(_on_notification_added)
	EventManager.event_triggered.connect(_on_event_triggered)
	EventManager.event_choice_made.connect(_on_event_choice_made)

	event_popup.visible = false


func _on_notification(_notification: Dictionary) -> void:
	_add_notification(_notification.get("title", ""), _notification.get("message", ""), _notification.get("type", "info"))


func _add_notification(title: String, message: String, type: String = "info") -> void:
	var notif_control = PanelContainer.new()
	var vbox = VBoxContainer.new()

	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_color_override("font_color", _get_type_color(type))

	var message_label = Label.new()
	message_label.text = message
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	vbox.add_child(title_label)
	vbox.add_child(message_label)
	notif_control.add_child(vbox)

	notification_container.add_child(notif_control)
	_active_notifications.append(notif_control)

	# 自动消失
	var tween = create_tween()
	tween.tween_interval(DataManager.constants.get("notification_duration", 5.0))
	tween.tween_callback(_remove_notification.bind(notif_control))

	# 限制数量
	while _active_notifications.size() > DataManager.constants.get("max_notifications", 50):
		var oldest = _active_notifications.pop_front()
		if oldest:
			oldest.queue_free()


func _remove_notification(notif: Control) -> void:
	if notif:
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 0.0, 0.5)
		tween.tween_callback(notif.queue_free)
		_active_notifications.erase(notif)


func _on_notification_added(title: String, message: String, type: String) -> void:
	_add_notification(title, message, type)


func _on_event_triggered(_event, _context: Dictionary) -> void:
	# 显示事件弹窗
	_show_event_popup(_event)


func _on_event_choice_made(_event, _choice_index: int, _outcome) -> void:
	# 显示选择结果
	var outcome_text: String = ""
	if _outcome is Dictionary:
		outcome_text = _outcome.get("text", "")
	elif _outcome != null:
		outcome_text = str(_outcome)
	_add_notification("事件结果", outcome_text, "info")


func _show_event_popup(event) -> void:
	event_popup.visible = true

	# 清空之前的内容
	for child in event_popup.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()

	# 标题 - 安全访问Dictionary
	var event_title: String = event.get("title", "") if event is Dictionary else str(event)
	var title_label = Label.new()
	title_label.text = event_title
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	# 描述
	var desc = RichTextLabel.new()
	desc.text = event.get("description", "") if event is Dictionary else ""
	desc.fit_content = true
	desc.custom_minimum_size = Vector2(400, 100)
	vbox.add_child(desc)

	# 选项按钮
	var choices: Array = event.get("choices", []) if event is Dictionary else []
	for i in range(choices.size()):
		var choice = choices[i]
		if not choice is Dictionary:
			continue
		var button = Button.new()
		button.text = choice.get("text", "")
		var req_str: String = ""
		if choice.has("get_requirement_string") and choice.get_requirement_string is Callable:
			req_str = choice.get_requirement_string()
		button.tooltip_text = req_str
		button.pressed.connect(_on_event_choice.bind(event, i))
		vbox.add_child(button)

	# 关闭按钮
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(func(): event_popup.visible = false)
	vbox.add_child(close_button)

	event_popup.add_child(vbox)


func _on_event_choice(event, choice_index: int) -> void:
	var choices: Array = event.get("choices", []) if event is Dictionary else []
	if choice_index < 0 or choice_index >= choices.size():
		return
	var choice = choices[choice_index]

	# 随机选择结果
	var roll = randf()
	var cumulative = 0.0
	var selected_outcome = null

	var outcomes: Array = choice.get("outcomes", []) if choice is Dictionary else []
	for outcome in outcomes:
		cumulative += outcome.get("probability", 0.0) if outcome is Dictionary else 0.0
		if roll <= cumulative:
			selected_outcome = outcome
			break

	if not selected_outcome and outcomes.size() > 0:
		selected_outcome = outcomes[-1]

	if selected_outcome:
		# 应用效果
		_apply_outcome_effects(selected_outcome)

		# 显示结果
		var event_title: String = event.get("title", "") if event is Dictionary else ""
		var outcome_text: String = selected_outcome.get("text", "") if selected_outcome is Dictionary else ""
		_add_notification(event_title, outcome_text, "info")

	event_popup.visible = false


func _apply_outcome_effects(outcome) -> void:
	# 通过事件管理器应用效果
	EventManager.apply_event_outcome(outcome)


func _get_type_color(type: String) -> Color:
	match type:
		"success":
			return Color.GREEN
		"warning":
			return Color.YELLOW
		"danger":
			return Color.RED
		"info":
			return Color.CYAN
		_:
			return Color.WHITE
