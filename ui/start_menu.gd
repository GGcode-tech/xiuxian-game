## 开始菜单 - 游戏入口UI
extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var load_button: Button = $VBox/LoadButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

signal start_game_requested
signal load_game_requested
signal settings_requested

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# 检查存档
	if SaveManager.get_save_slots().is_empty():
		load_button.disabled = true

func _on_start_pressed() -> void:
	start_game_requested.emit()
	hide()

func _on_load_pressed() -> void:
	load_game_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
