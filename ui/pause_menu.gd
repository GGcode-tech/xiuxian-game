## 暂停菜单
extends Control

@onready var resume_button: Button = $VBox/ResumeButton
@onready var save_button: Button = $VBox/SaveButton
@onready var load_button: Button = $VBox/LoadButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

func _ready() -> void:
	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit_to_menu)
	hide()

func _on_resume() -> void:
	GameManager.set_state(GameManager.GameState.PLAYING)
	hide()

func _on_save() -> void:
	GameManager.save_game("quick")
	hide()

func _on_load() -> void:
	GameManager.load_game("quick")
	GameManager.set_state(GameManager.GameState.PLAYING)
	hide()

func _on_settings() -> void:
	# 设置面板暂未实现，显示提示
	var notification_node = get_node_or_null("/root/Main/UILayer/NotificationSystem")
	if notification_node and notification_node.has_method("show_notification"):
		notification_node.show_notification("设置功能开发中...", "info")
	hide()

func _on_quit_to_menu() -> void:
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	hide()
