## 开始菜单 - 游戏入口UI
extends Control

@onready var novel_select: OptionButton = $VBox/NovelSelect
@onready var start_button: Button = $VBox/StartButton
@onready var load_button: Button = $VBox/LoadButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton

signal start_game_requested(novel_index: int)
signal load_game_requested
signal settings_requested

func _ready() -> void:
	_populate_novel_select()
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 检查存档
	if SaveManager.get_save_slots().is_empty():
		load_button.disabled = true

func _populate_novel_select() -> void:
	novel_select.clear()
	var overview = NovelDB.get_cultivation_systems_overview()
	for entry in overview:
		var text = "%s (境界:%d 功法:%d)" % [entry["novel"], entry["realm_count"], entry["technique_count"]]
		novel_select.add_item(text)
	# 默认选凡人修仙传
	novel_select.select(0)

func _on_start_pressed() -> void:
	var index = novel_select.selected
	start_game_requested.emit(index)
	GameManager.game_started.emit()
	hide()

func _on_load_pressed() -> void:
	load_game_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
