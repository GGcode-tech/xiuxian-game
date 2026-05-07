## 副本面板 - 副本章节列表/难度/扫荡
extends Control

signal dungeon_panel_closed()
signal dungeon_started(dungeon_id: String, difficulty: String)
signal dungeon_sweep_requested(dungeon_id: String)

# 副本数据
var _all_dungeons: Dictionary = {}
var _selected_chapter: String = ""
var _selected_dungeon: String = ""
var _current_difficulty: String = "normal"  # simple, normal, hard, hell
var _sweep_tickets: int = 3
var _daily_sweep_count: int = 0

# UI组件
var _main_container: VBoxContainer
var _chapter_list: ItemList
var _dungeon_detail_panel: PanelContainer
var _difficulty_buttons: HBoxContainer

const DIFFICULTIES = ["simple", "normal", "hard", "hell"]
const DIFFICULTY_NAMES = {"simple": "简单", "normal": "普通", "hard": "困难", "hell": "地狱"}

func _ready() -> void:
	visible = false
	# 自动截图
	ScreenshotSystem.auto_screenshot("11_副本")
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.18, 0.95)
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
	_load_sample_data()

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 60
	
	var title = Label.new()
	title.text = "⚔️ 副本面板"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	
	var sweep_label = Label.new()
	sweep_label.text = "扫荡券: %d/3" % _sweep_tickets
	sweep_label.custom_minimum_size.x = 120
	header.add_child(sweep_label)
	
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
	hbox.custom_minimum_size.y = 420
	_main_container.add_child(hbox)
	
	# 左侧：章节列表
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(250, 420)
	hbox.add_child(left_panel)
	
	var chapter_title = Label.new()
	chapter_title.text = "📖 副本章节"
	chapter_title.add_theme_font_size_override("font_size", 18)
	left_panel.add_child(chapter_title)
	
	_chapter_list = ItemList.new()
	_chapter_list.custom_minimum_size = Vector2(250, 380)
	_chapter_list.item_selected.connect(_on_chapter_selected)
	left_panel.add_child(_chapter_list)
	
	# 中间：副本列表
	var mid_panel = VBoxContainer.new()
	mid_panel.custom_minimum_size = Vector2(300, 420)
	hbox.add_child(mid_panel)
	
	var dungeon_title = Label.new()
	dungeon_title.text = "📋 副本列表"
	dungeon_title.add_theme_font_size_override("font_size", 18)
	mid_panel.add_child(dungeon_title)
	
	var dungeon_scroll = ScrollContainer.new()
	dungeon_scroll.custom_minimum_size = Vector2(300, 380)
	var dungeon_vbox = VBoxContainer.new()
	dungeon_scroll.add_child(dungeon_vbox)
	mid_panel.add_child(dungeon_scroll)
	
	# 存储副本按钮引用
	dungeon_vbox.set_name("DungeonList")
	
	# 右侧：副本详情
	_dungeon_detail_panel = _build_dungeon_detail_panel()
	hbox.add_child(_dungeon_detail_panel)

func _build_dungeon_detail_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 420)
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "副本详情"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	# 副本名称
	var name_label = Label.new()
	name_label.text = "请选择副本"
	name_label.name = "DungeonName"
	vbox.add_child(name_label)
	
	# 推荐境界
	var realm_label = Label.new()
	realm_label.text = "推荐境界: -"
	realm_label.name = "RealmLabel"
	vbox.add_child(realm_label)
	
	# 消耗体力
	var stamina_label = Label.new()
	stamina_label.text = "消耗体力: -"
	stamina_label.name = "StaminaLabel"
	vbox.add_child(stamina_label)
	
	# 奖励预览
	var reward_title = Label.new()
	reward_title.text = "--- 奖励预览 ---"
	vbox.add_child(reward_title)
	
	var reward_label = Label.new()
	reward_label.text = "灵石: -\n经验: -\n装备: -"
	reward_label.name = "RewardLabel"
	vbox.add_child(reward_label)
	
	# 难度选择
	var diff_title = Label.new()
	diff_title.text = "选择难度"
	diff_title.custom_minimum_size.y = 30
	vbox.add_child(diff_title)
	
	_difficulty_buttons = HBoxContainer.new()
	for diff in DIFFICULTIES:
		var diff_btn = Button.new()
		diff_btn.text = DIFFICULTY_NAMES[diff]
		diff_btn.pressed.connect(_on_difficulty_selected.bind(diff))
		_difficulty_buttons.add_child(diff_btn)
	vbox.add_child(_difficulty_buttons)
	
	# 开始按钮
	var start_btn = Button.new()
	start_btn.text = "⚔️ 开始挑战"
	start_btn.custom_minimum_size = Vector2(200, 60)
	start_btn.pressed.connect(_on_start_dungeon)
	start_btn.name = "StartButton"
	vbox.add_child(start_btn)
	
	# 扫荡按钮
	var sweep_btn = Button.new()
	sweep_btn.text = "🗑️ 扫荡 (剩余%d次)" % _sweep_tickets
	sweep_btn.custom_minimum_size = Vector2(200, 60)
	sweep_btn.pressed.connect(_on_sweep_dungeon)
	sweep_btn.name = "SweepButton"
	vbox.add_child(sweep_btn)
	
	return panel

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 40

	var tip = Label.new()
	tip.text = "💡 提示: 挑战副本可获得灵石、经验和稀有物品"
	tip.add_theme_font_size_override("font_size", 14)
	footer.add_child(tip)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var status = Label.new()
	status.text = "体力: %d  扫荡券: %d/3" % [100, _sweep_tickets]
	status.add_theme_font_size_override("font_size", 14)
	footer.add_child(status)

	_main_container.add_child(footer)

func _load_sample_data() -> void:
	_all_dungeons = {
		"chapter_1": {
			"name": "第一章 踏入修仙",
			"novel": "凡人修仙传",
			"dungeons": [
				{
					"id": "dungeon_1_1",
					"name": "七玄门试炼",
					"realm_req": "炼气期",
					"stamina": 10,
					"rewards": {"spirit_stone": 50, "exp": 100}
				},
				{
					"id": "dungeon_1_2",
					"name": "野狼谷",
					"realm_req": "炼气期",
					"stamina": 15,
					"rewards": {"spirit_stone": 80, "exp": 200}
				}
			]
		},
		"chapter_2": {
			"name": "第二章 筑基之路",
			"novel": "凡人修仙传",
			"dungeons": [
				{
					"id": "dungeon_2_1",
					"name": "黄枫谷",
					"realm_req": "筑基期",
					"stamina": 20,
					"rewards": {"spirit_stone": 150, "exp": 500}
				},
				{
					"id": "dungeon_2_2",
					"name": "血色禁地",
					"realm_req": "筑基期",
					"stamina": 30,
					"rewards": {"spirit_stone": 300, "exp": 1000, "item": "筑基丹"}
				}
			]
		},
		"chapter_3": {
			"name": "第三章 结丹风云",
			"novel": "凡人修仙传",
			"dungeons": [
				{
					"id": "dungeon_3_1",
					"name": "溪州之战",
					"realm_req": "结丹期",
					"stamina": 40,
					"rewards": {"spirit_stone": 500, "exp": 2000}
				}
			]
		}
	}
	
	# 填充章节列表
	_populate_chapters()

func _populate_chapters() -> void:
	_chapter_list.clear()
	for chapter_id in _all_dungeons.keys():
		var chapter = _all_dungeons[chapter_id]
		_chapter_list.add_item(chapter.get("name", "未知章节"))

func _populate_dungeon_list(chapter_id: String) -> void:
	var dungeon_scroll = _main_container.get_child(1).get_child(2)
	var dungeon_vbox = dungeon_scroll.get_child(0)
	
	# 清除旧列表
	for child in dungeon_vbox.get_children():
		child.queue_free()
	
	var chapter = _all_dungeons.get(chapter_id, {})
	var dungeons = chapter.get("dungeons", [])
	
	for dungeon in dungeons:
		var dungeon_btn = Button.new()
		dungeon_btn.custom_minimum_size = Vector2(280, 50)
		dungeon_btn.text = "%s (消耗%d体力)" % [dungeon.get("name", ""), dungeon.get("stamina", 0)]
		dungeon_btn.pressed.connect(_on_dungeon_selected.bind(dungeon))
		dungeon_vbox.add_child(dungeon_btn)

func _update_dungeon_detail(dungeon: Dictionary) -> void:
	var vbox = _dungeon_detail_panel.get_child(0)
	
	vbox.get_node("DungeonName").text = dungeon.get("name", "未知副本")
	vbox.get_node("RealmLabel").text = "推荐境界: %s" % dungeon.get("realm_req", "-")
	vbox.get_node("StaminaLabel").text = "消耗体力: %d" % dungeon.get("stamina", 0)
	
	var rewards = dungeon.get("rewards", {})
	var reward_text = "灵石: %d\n经验: %d" % [
		rewards.get("spirit_stone", 0),
		rewards.get("exp", 0)
	]
	if rewards.has("item"):
		reward_text += "\n物品: %s" % rewards.get("item", "")
	vbox.get_node("RewardLabel").text = reward_text
	
	_selected_dungeon = dungeon.get("id", "")

func _on_chapter_selected(index: int) -> void:
	var chapter_ids = _all_dungeons.keys()
	if index < chapter_ids.size():
		_selected_chapter = chapter_ids[index]
		_populate_dungeon_list(_selected_chapter)

func _on_dungeon_selected(dungeon: Dictionary) -> void:
	_update_dungeon_detail(dungeon)

func _on_difficulty_selected(difficulty: String) -> void:
	_current_difficulty = difficulty

func _on_start_dungeon() -> void:
	if _selected_dungeon == "":
		return
	dungeon_started.emit(_selected_dungeon, _current_difficulty)

func _on_sweep_dungeon() -> void:
	if _selected_dungeon == "" or _sweep_tickets <= 0:
		return
	dungeon_sweep_requested.emit(_selected_dungeon)
	_sweep_tickets -= 1
	_update_sweep_button()

func _update_sweep_button() -> void:
	var vbox = _dungeon_detail_panel.get_child(0)
	var sweep_btn = vbox.get_node("SweepButton")
	sweep_btn.text = "🗑️ 扫荡 (剩余%d次)" % _sweep_tickets

func _on_close_clicked() -> void:
	visible = false
	dungeon_panel_closed.emit()

func setup_dungeons(dungeons: Dictionary) -> void:
	_all_dungeons = dungeons
	_populate_chapters()

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false