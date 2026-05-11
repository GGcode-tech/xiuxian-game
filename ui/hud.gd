## HUD - 游戏主界面HUD (梦幻西游风格底部通栏)
extends Control

# 顶部信息栏
@onready var date_label: Label = $TopBar/DateLabel
@onready var speed_label: Label = $TopBar/SpeedLabel
@onready var season_label: Label = $TopBar/SeasonLabel

# 家族概览
@onready var family_name_label: Label = $TopBar/FamilyNameLabel
@onready var member_count_label: Label = $TopBar/MemberCountLabel
@onready var spirit_stone_label: Label = $TopBar/SpiritStoneLabel

# 底部操作栏
@onready var action_bar: HBoxContainer = $BottomBar/MarginContainer/HBox/ActionBar

# 底部角色列表(水平排列)
@onready var character_sidebar: HBoxContainer = $BottomBar/MarginContainer/HBox/CharacterList

# 信号
signal character_selected(character)
signal family_panel_requested
signal map_panel_requested


func _ready() -> void:
	GameManager.time_elapsed.connect(_on_time_elapsed)
	GameManager.speed_changed.connect(_on_speed_changed)
	
	# 连接底部按钮
	var family_btn = $BottomBar/MarginContainer/HBox/ActionBar/FamilyButton
	var map_btn = $BottomBar/MarginContainer/HBox/ActionBar/MapButton
	if family_btn:
		family_btn.pressed.connect(_on_family_button_pressed)
	if map_btn:
		map_btn.pressed.connect(_on_map_button_pressed)
	
	# 自动截图
	ScreenshotSystem.auto_screenshot("04_HUD主界面")


func update_display() -> void:
	_update_date_display()
	_update_family_overview()
	_update_character_sidebar()


func _update_date_display() -> void:
	var gt = GameManager.game_time
	date_label.text = "第%d年 %s %d日" % [
		gt.year,
		_get_month_name(gt.month),
		gt.day
	]
	
	var speed_text = {0: "0.5x", 1: "1x", 2: "2x", 3: "5x", 4: "10x"}
	var idx = 0
	var speeds = [0.5, 1.0, 2.0, 5.0, 10.0]
	for i in range(speeds.size()):
		if abs(GameManager.game_speed - speeds[i]) < 0.01:
			idx = i
			break
	if GameManager.is_paused:
		speed_label.text = "速度: 暂停"
	else:
		speed_label.text = "速度: %s" % speed_text.get(idx, "1x")
	
	season_label.text = _get_season_name(gt.month)


func _update_family_overview() -> void:
	var family = GameManager.get_player_family()
	if family.is_empty():
		family_name_label.text = "家族: ?"
		member_count_label.text = "族人: 0"
		spirit_stone_label.text = "灵石: 0"
		return
	
	family_name_label.text = family.get("name", "未知")
	var members = family.get("members", [])
	member_count_label.text = "族人: %d" % members.size()
	
	var player = _get_player_character_from_hud()
	var spirit_stone = player.get("resources", {}).get("spirit_stone", 0) if player else 0
	spirit_stone_label.text = "灵石: %d" % spirit_stone


func _update_character_sidebar() -> void:
	for child in character_sidebar.get_children():
		child.queue_free()
	
	var family = GameManager.get_player_family()
	if family.is_empty():
		return
	
	var members = family.get("members", [])
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and not character.is_empty() and character.get("is_alive", false):
			var button = Button.new()
			var realm_id = character.get("realm_id", "")
			var realm = DataManager.get_realm(realm_id)
			var char_name = character.get("name", "未知")
			button.text = "%s [%s]" % [char_name, realm.name if realm else "?"]
			button.custom_minimum_size = Vector2(100, 28)
			button.pressed.connect(_on_character_button_pressed.bind(character))
			character_sidebar.add_child(button)


func _get_player_character_from_hud() -> Dictionary:
	for cid in GameManager.all_characters:
		var c = GameManager.all_characters[cid]
		if c.get("generation", 0) == 1 and c.get("role", "") == "cultivator":
			return c
	return {}


func _on_time_elapsed(day_data: Dictionary) -> void:
	_update_date_display()
	_update_family_overview()


func _on_speed_changed(_speed: int) -> void:
	_update_date_display()


func _on_character_button_pressed(character) -> void:
	character_selected.emit(character)


func _on_family_button_pressed() -> void:
	family_panel_requested.emit()


func _on_map_button_pressed() -> void:
	map_panel_requested.emit()


func _get_month_name(month: int) -> String:
	var months = ["正月", "二月", "三月", "四月", "五月", "六月",
				  "七月", "八月", "九月", "十月", "冬月", "腊月"]
	if month >= 1 and month <= 12:
		return months[month - 1]
	return "未知"


func _get_season_name(month: int) -> String:
	if month in [1, 2, 3]:
		return "🌸 春"
	elif month in [4, 5, 6]:
		return "☀️ 夏"
	elif month in [7, 8, 9]:
		return "🍂 秋"
	else:
		return "❄️ 冬"
