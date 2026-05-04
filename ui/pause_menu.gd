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
	# TODO: 设置面板
	pass

func _on_quit_to_menu() -> void:
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	hide()
