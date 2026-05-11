## 游戏结束界面
extends Control

@onready var summary_label: Label = $VBox/SummaryLabel
@onready var stats_label: RichTextLabel = $VBox/StatsLabel
@onready var restart_button: Button = $VBox/RestartButton
@onready var menu_button: Button = $VBox/MenuButton

func _ready() -> void:
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_quit_to_menu)
	hide()

func show_game_over(reason: String = "家族族人全部陨落") -> void:
	summary_label.text = reason
	_generate_stats()
	show()
	get_tree().paused = true

func _generate_stats() -> void:
	var family = GameManager.get_player_family()
	if family.is_empty():
		stats_label.text = "存续年数: ? | 历代族人: ?"
		return

	var txt = ""
	txt += "[b]存续年数[/b]: %d 年\n" % GameManager.game_time.year
	txt += "[b]历代族人[/b]: %d 人\n" % family.get("members", []).size()
	txt += "[b]最终等级[/b]: Lv.%d" % family.get("level", 1)
	stats_label.text = txt

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_to_menu() -> void:
	get_tree().paused = false
	GameManager.set_state(GameManager.GameState.MAIN_MENU)
	hide()
