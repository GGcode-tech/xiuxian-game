## 通知系统UI - 显示游戏内通知和消息
extends Control

@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var event_popup: PanelContainer = $EventPopup

# 通知场景
const NOTIFICATION_SCENE = preload("res://ui/notification_item.tscn")

# 通知队列
var _notification_queue: Array[Dictionary] = []
var _active_notifications: Array[Control] = []


func _ready() -> void:
	EventManager.notification_added.connect(_on_notification_added)
	EventManager.event_triggered.connect(_on_event_triggered)
	EventManager.event_choice_made.connect(_on_event_choice_made)
	
	event_popup.visible = false


func _on_notification(notification: Dictionary) -> void:
	_add_notification(notification.title, notification.message, notification.type)


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


func _on_event_triggered(event, context: Dictionary) -> void:
	# 显示事件弹窗
	_show_event_popup(event)


func _on_event_choice_made(event, choice_index: int, outcome) -> void:
	# 显示选择结果
	_add_notification("事件结果", outcome.text, "info")


func _show_event_popup(event) -> void:
	event_popup.visible = true
	
	# 清空之前的内容
	for child in event_popup.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	
	# 标题
	var title = Label.new()
	title.text = event.title
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# 描述
	var desc = RichTextLabel.new()
	desc.text = event.description
	desc.fit_content = true
	desc.custom_minimum_size = Vector2(400, 100)
	vbox.add_child(desc)
	
	# 选项按钮
	for i in range(event.choices.size()):
		var choice = event.choices[i]
		var button = Button.new()
		button.text = choice.text
		button.tooltip_text = choice.get_requirement_string()
		button.pressed.connect(_on_event_choice.bind(event, i))
		vbox.add_child(button)
	
	# 关闭按钮
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.pressed.connect(func(): event_popup.visible = false)
	vbox.add_child(close_button)
	
	event_popup.add_child(vbox)


func _on_event_choice(event, choice_index: int) -> void:
	var choice = event.choices[choice_index]
	
	# 随机选择结果
	var roll = randf()
	var cumulative = 0.0
	var selected_outcome = null
	
	for outcome in choice.outcomes:
		cumulative += outcome.probability
		if roll <= cumulative:
			selected_outcome = outcome
			break
	
	if not selected_outcome and choice.outcomes.size() > 0:
		selected_outcome = choice.outcomes[-1]
	
	if selected_outcome:
		# 应用效果
		_apply_outcome_effects(selected_outcome)
		
		# 显示结果
		_add_notification(event.title, selected_outcome.text, "info")
	
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
