## 日常活动面板 - 活动列表/奖励/活跃度
extends Control

signal daily_activity_panel_closed()
signal activity_started(activity_id: String)
signal activity_reward_claimed(activity_id: String)
signal vitality_reward_claimed(level: int)

# 活动数据
var _daily_activities: Array = []
var _activity_rewards: Dictionary = {}
var _current_vitality: int = 0
var _vitality_rewards_claimed: Array = []

# 活跃度奖励等级
var VITALITY_REWARDS = [
	{"level": 10, "rewards": [{"type": "spirit_stone", "count": 50}], "claimed": false},
	{"level": 30, "rewards": [{"type": "spirit_stone", "count": 100}], "claimed": false},
	{"level": 50, "rewards": [{"type": "spirit_jade", "count": 10}], "claimed": false},
	{"level": 80, "rewards": [{"type": "spirit_stone", "count": 200}], "claimed": false},
	{"level": 100, "rewards": [{"type": "rare_item", "count": 1}], "claimed": false}
]

# UI组件
var _main_container: VBoxContainer
var _activity_list_container: ScrollContainer
var _vitality_progress: ProgressBar
var _activity_detail_panel: PanelContainer
var _selected_activity_id: String = ""

func _ready() -> void:
	visible = false
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.12, 0.18, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 主容器
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 10)
	add_child(_main_container)
	
	_build_header()
	_build_main_content()
	_build_vitality_section()
	_build_footer()
	_load_sample_data()

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 60
	
	var title = Label.new()
	title.text = "📅 日常活动"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	
	var date_label = Label.new()
	date_label.text = "今日活跃度: 0/100"
	date_label.name = "DateLabel"
	header.add_child(date_label)
	
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
	hbox.custom_minimum_size.y = 350
	_main_container.add_child(hbox)
	
	# 左侧：活动列表
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 350)
	hbox.add_child(left_panel)
	
	var list_title = Label.new()
	list_title.text = "🎯 今日活动"
	list_title.add_theme_font_size_override("font_size", 20)
	left_panel.add_child(list_title)
	
	_activity_list_container = ScrollContainer.new()
	_activity_list_container.custom_minimum_size = Vector2(400, 320)
	var list_vbox = VBoxContainer.new()
	_activity_list_container.add_child(list_vbox)
	left_panel.add_child(_activity_list_container)
	
	# 右侧：活动详情
	_activity_detail_panel = _build_activity_detail_panel()
	hbox.add_child(_activity_detail_panel)

func _build_activity_detail_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 350)
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "活动详情"
	title.add_theme_font_size_override("font_size", 22)
	title.name = "DetailTitle"
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "选择一个活动查看详情"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.name = "DetailDesc"
	vbox.add_child(desc)
	
	var requirements_title = Label.new()
	requirements_title.text = "参与条件"
	requirements_title.name = "ReqTitle"
	vbox.add_child(requirements_title)
	
	var requirements = Label.new()
	requirements.text = "-"
	requirements.name = "Requirements"
	vbox.add_child(requirements)
	
	var rewards_title = Label.new()
	rewards_title.text = "完成奖励"
	rewards_title.name = "RewardsTitle"
	vbox.add_child(rewards_title)
	
	var rewards = Label.new()
	rewards.text = "-"
	rewards.name = "Rewards"
	vbox.add_child(rewards)
	
	var start_btn = Button.new()
	start_btn.text = "🎮 参与活动"
	start_btn.custom_minimum_size = Vector2(200, 60)
	start_btn.pressed.connect(_on_start_activity)
	start_btn.name = "StartButton"
	vbox.add_child(start_btn)
	
	return panel

func _build_vitality_section() -> void:
	var vitality_panel = PanelContainer.new()
	vitality_panel.custom_minimum_size.y = 120
	_main_container.add_child(vitality_panel)
	
	var vbox = VBoxContainer.new()
	vitality_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🌟 活跃度进度"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	_vitality_progress = ProgressBar.new()
	_vitality_progress.max_value = 100
	_vitality_progress.value = 0
	_vitality_progress.show_percentage = false
	vbox.add_child(_vitality_progress)
	
	var vitality_label = Label.new()
	vitality_label.text = "0 / 100"
	vitality_label.name = "VitalityLabel"
	vitality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(vitality_label)
	
	# 奖励领取按钮
	var rewards_hbox = HBoxContainer.new()
	rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for i in range(VITALITY_REWARDS.size()):
		var reward_level = VITALITY_REWARDS[i]
		var reward_btn = Button.new()
		reward_btn.custom_minimum_size = Vector2(60, 40)
		reward_btn.text = "%d" % reward_level["level"]
		reward_btn.pressed.connect(_on_vitality_reward_clicked.bind(i))
		reward_btn.name = "VitalityBtn_%d" % i
		rewards_hbox.add_child(reward_btn)
	
	vbox.add_child(rewards_hbox)

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 60
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 刷新活动"
	refresh_btn.custom_minimum_size = Vector2(150, 50)
	refresh_btn.pressed.connect(_on_refresh_clicked)
	footer.add_child(refresh_btn)
	
	_main_container.add_child(footer)

func _load_sample_data() -> void:
	_daily_activities = [
		{
			"id": "activity_daily_1",
			"name": "日常委托",
			"icon": "📋",
			"description": "完成一次日常委托任务，获得经验和灵石奖励",
			"requirements": "无",
			"rewards": {"spirit_stone": 30, "exp": 50, "vitality": 10},
			"daily_count": 3,
			"current_count": 1
		},
		{
			"id": "activity_daily_2",
			"name": "宗门任务",
			"icon": "🏛️",
			"description": "完成宗门发布的任务，获得贡献度和灵石",
			"requirements": "已加入宗门",
			"rewards": {"contribution": 20, "spirit_stone": 50, "vitality": 15},
			"daily_count": 5,
			"current_count": 0
		},
		{
			"id": "activity_daily_3",
			"name": "灵兽狩猎",
			"icon": "🐉",
			"description": "狩猎野外灵兽，有机会获得灵兽蛋",
			"requirements": "拥有一只灵兽",
			"rewards": {"spirit_stone": 100, "beast_egg": 1, "vitality": 20},
			"daily_count": 3,
			"current_count": 2
		},
		{
			"id": "activity_daily_4",
			"name": "答题活动",
			"icon": "📝",
			"description": "回答修仙知识问题，答对获得奖励",
			"requirements": "无",
			"rewards": {"spirit_stone": 20, "exp": 100, "vitality": 5},
			"daily_count": 10,
			"current_count": 5
		},
		{
			"id": "activity_daily_5",
			"name": "护送任务",
			"icon": "🚗",
			"description": "护送商队到达目的地，获得丰厚奖励",
			"requirements": "境界达到筑基期",
			"rewards": {"spirit_stone": 200, "exp": 300, "vitality": 25},
			"daily_count": 2,
			"current_count": 0
		},
		{
			"id": "activity_daily_6",
			"name": "竞技场",
			"icon": "⚔️",
			"description": "与其他玩家进行PVP对战",
			"requirements": "境界达到炼气期",
			"rewards": {"spirit_stone": 150, "honor": 50, "vitality": 20},
			"daily_count": 5,
			"current_count": 3
		}
	]
	
	_update_activity_list()

func _update_activity_list() -> void:
	var list_vbox = _activity_list_container.get_child(0)
	for child in list_vbox.get_children():
		child.queue_free()
	
	for activity in _daily_activities:
		var activity_card = _create_activity_card(activity)
		list_vbox.add_child(activity_card)

func _create_activity_card(activity: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 70)
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	
	# 活动图标
	var icon_label = Label.new()
	icon_label.text = activity.get("icon", "📋")
	icon_label.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon_label)
	
	# 活动信息
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size.x = 220
	
	var name_label = Label.new()
	name_label.text = activity.get("name", "未知活动")
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var count_label = Label.new()
	count_label.text = "剩余次数: %d/%d" % [
		activity.get("daily_count", 0) - activity.get("current_count", 0),
		activity.get("daily_count", 0)
	]
	info_vbox.add_child(count_label)
	
	hbox.add_child(info_vbox)
	
	# 查看按钮
	var view_btn = Button.new()
	view_btn.text = "查看"
	view_btn.pressed.connect(_on_activity_selected.bind(activity))
	hbox.add_child(view_btn)
	
	return card

func _on_activity_selected(activity: Dictionary) -> void:
	var vbox = _activity_detail_panel.get_child(0)
	
	vbox.get_node("DetailTitle").text = "%s %s" % [activity.get("icon", "📋"), activity.get("name", "")]
	vbox.get_node("DetailDesc").text = activity.get("description", "")
	vbox.get_node("Requirements").text = activity.get("requirements", "-")
	
	var rewards = activity.get("rewards", {})
	var reward_text = "灵石: %d\n经验: %d\n活跃度: %d" % [
		rewards.get("spirit_stone", 0),
		rewards.get("exp", 0),
		rewards.get("vitality", 0)
	]
	if rewards.has("contribution"):
		reward_text += "\n贡献度: %d" % rewards.get("contribution", 0)
	if rewards.has("beast_egg"):
		reward_text += "\n灵兽蛋: %s" % rewards.get("beast_egg", "-")
	vbox.get_node("Rewards").text = reward_text
	
	_selected_activity_id = activity.get("id", "")

func _on_start_activity() -> void:
	var activity_id = _selected_activity_id
	if activity_id == "":
		return
	activity_started.emit(activity_id)

func _on_vitality_reward_clicked(index: int) -> void:
	if index >= VITALITY_REWARDS.size():
		return
	
	var reward_level = VITALITY_REWARDS[index]
	if _current_vitality < reward_level["level"]:
		return
	if _vitality_rewards_claimed.has(index):
		return
	
	_vitality_rewards_claimed.append(index)
	_vitality_reward_claimed.emit(reward_level["level"])
	_update_vitality_display()

func _update_vitality_display() -> void:
	var date_label = _main_container.get_child(0).get_node("DateLabel")
	date_label.text = "今日活跃度: %d/100" % _current_vitality
	
	_vitality_progress.value = _current_vitality
	
	var vbox = _main_container.get_child(2).get_child(0)
	var vitality_label = vbox.get_node("VitalityLabel")
	vitality_label.text = "%d / 100" % _current_vitality
	
	# 更新奖励按钮状态
	for i in range(VITALITY_REWARDS.size()):
		var reward_level = VITALITY_REWARDS[i]
		var reward_btn = vbox.get_node("VitalityBtn_%d" % i)
		if _vitality_rewards_claimed.has(i):
			reward_btn.text = "✓%d" % reward_level["level"]
			reward_btn.disabled = true
		elif _current_vitality >= reward_level["level"]:
			reward_btn.text = "领%d" % reward_level["level"]
		else:
			reward_btn.text = "%d" % reward_level["level"]
			reward_btn.disabled = true

func add_vitality(amount: int) -> void:
	_current_vitality = min(_current_vitality + amount, 100)
	_update_vitality_display()

func _on_close_clicked() -> void:
	visible = false
	daily_activity_panel_closed.emit()

func _on_refresh_clicked() -> void:
	# 刷新活动列表...
	pass

func setup_activities(activities: Array) -> void:
	_daily_activities = activities
	_update_activity_list()

func show_panel() -> void:
	_update_vitality_display()
	visible = true

func hide_panel() -> void:
	visible = false