## 日常活动面板 - 活动列表/奖励/活跃度（接入DailyActivitySystem真实数据）

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

# 系统引用
var _daily_activity_system: Node = null

# 活跃度奖励等级
var VITALITY_REWARDS = [
	{"level": 30, "rewards": [{"type": "spirit_stone", "count": 50}], "claimed": false},
	{"level": 60, "rewards": [{"type": "spirit_stone", "count": 100}], "claimed": false},
	{"level": 100, "rewards": [{"type": "spirit_jade", "count": 10}], "claimed": false},
	{"level": 150, "rewards": [{"type": "spirit_stone", "count": 200}], "claimed": false},
	{"level": 200, "rewards": [{"type": "rare_item", "count": 1}], "claimed": false}
]

# UI组件
var _main_container: VBoxContainer
var _activity_list_container: ScrollContainer
var _vitality_progress: ProgressBar
var _activity_detail_panel: PanelContainer
var _selected_activity_id: String = ""

func _ready() -> void:
	visible = false
	# 自动截图
	ScreenshotSystem.auto_screenshot("10_日常活动")
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

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 45
	
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
	hbox.custom_minimum_size.y = 280
	_main_container.add_child(hbox)
	
	# 左侧：活动列表
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 280)
	hbox.add_child(left_panel)
	
	var list_title = Label.new()
	list_title.text = "🎯 今日活动"
	list_title.add_theme_font_size_override("font_size", 20)
	left_panel.add_child(list_title)
	
	_activity_list_container = ScrollContainer.new()
	_activity_list_container.custom_minimum_size = Vector2(400, 250)
	var list_vbox = VBoxContainer.new()
	_activity_list_container.add_child(list_vbox)
	left_panel.add_child(_activity_list_container)
	
	# 右侧：活动详情
	_activity_detail_panel = _build_activity_detail_panel()
	hbox.add_child(_activity_detail_panel)

func _build_activity_detail_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(350, 280)
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
	start_btn.custom_minimum_size = Vector2(160, 40)
	start_btn.pressed.connect(_on_start_activity)
	start_btn.name = "StartButton"
	vbox.add_child(start_btn)
	
	return panel

func _build_vitality_section() -> void:
	var vitality_panel = PanelContainer.new()
	vitality_panel.custom_minimum_size.y = 90
	_main_container.add_child(vitality_panel)
	
	var vbox = VBoxContainer.new()
	vitality_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🌟 活跃度进度"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	_vitality_progress = ProgressBar.new()
	_vitality_progress.max_value = 200
	_vitality_progress.value = 0
	_vitality_progress.show_percentage = false
	vbox.add_child(_vitality_progress)
	
	var vitality_label = Label.new()
	vitality_label.text = "0 / 200"
	vitality_label.name = "VitalityLabel"
	vitality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(vitality_label)
	
	# 奖励领取按钮
	var rewards_hbox = HBoxContainer.new()
	rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	for i in range(VITALITY_REWARDS.size()):
		var reward_level = VITALITY_REWARDS[i]
		var reward_btn = Button.new()
		reward_btn.custom_minimum_size = Vector2(50, 32)
		reward_btn.text = "%d" % reward_level["level"]
		reward_btn.pressed.connect(_on_vitality_reward_clicked.bind(i))
		reward_btn.name = "VitalityBtn_%d" % i
		rewards_hbox.add_child(reward_btn)
	
	vbox.add_child(rewards_hbox)

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 45
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 刷新活动"
	refresh_btn.custom_minimum_size = Vector2(130, 38)
	refresh_btn.pressed.connect(_on_refresh_clicked)
	footer.add_child(refresh_btn)
	
	_main_container.add_child(footer)

# ==================== 真实数据加载 ====================

func setup_system(sys: Node) -> void:
	_daily_activity_system = sys

func _load_real_data() -> void:
	if not _daily_activity_system:
		return
	
	_daily_activities = []
	
	# 从DailyActivitySystem获取活动数据
	var activities_data = _daily_activity_system.get("activities_data")
	if activities_data:
		for activity_id in activities_data:
			var ad = activities_data[activity_id]
			
			# 获取今日参与记录
			var instance = null
			if _daily_activity_system.has_method("get_activity_instance"):
				instance = _daily_activity_system.get_activity_instance(activity_id)
			
			var today_count = instance.get("today_count", 0) if instance else 0
			var max_count = ad.get("max_daily_count", 1)
			
			_daily_activities.append({
				"id": activity_id,
				"name": ad.get("name", "未知活动"),
				"icon": _get_activity_icon(ad.get("activity_type", 0)),
				"description": ad.get("description", ""),
				"requirements": "等级要求: %d" % ad.get("level_requirement", 1),
				"rewards": ad.get("rewards", {}),
				"daily_count": max_count,
				"current_count": today_count,
				"stamina_cost": ad.get("stamina_cost", 0),
				"difficulty": ad.get("difficulty", 1),
			})
	
	# 获取活跃度
	var daily_vitality = _daily_activity_system.get("daily_vitality")
	if daily_vitality != null:
		_current_vitality = daily_vitality
	
	# 获取已领取的奖励
	var claimed = _daily_activity_system.get("claimed_daily_rewards")
	if claimed:
		_vitality_rewards_claimed = claimed.duplicate()
	
	_update_activity_list()
	_update_vitality_display()

func _get_activity_icon(activity_type: int) -> String:
	match activity_type:
		0: return "🏛️"  # SECT_QUEST
		1: return "🐉"  # SPIRIT_ISLAND
		2: return "⚔️"  # ARENA
		3: return "📝"  # EXAM
		4: return "🚗"  # ESCORT
		5: return "🧘"  # PRACTICE
		6: return "💰"  # TREASURE
		_: return "📋"

func _update_activity_list() -> void:
	var list_vbox = _activity_list_container.get_child(0)
	for child in list_vbox.get_children():
		child.queue_free()
	
	if _daily_activities.is_empty():
		var empty = Label.new()
		empty.text = "暂无活动"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_vbox.add_child(empty)
		return
	
	for activity in _daily_activities:
		var activity_card = _create_activity_card(activity)
		list_vbox.add_child(activity_card)

func _create_activity_card(activity: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(380, 55)
	
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
	
	var remaining = activity.get("daily_count", 0) - activity.get("current_count", 0)
	var count_label = Label.new()
	count_label.text = "剩余次数: %d/%d" % [remaining, activity.get("daily_count", 0)]
	count_label.add_theme_color_override("font_color", Color.GREEN if remaining > 0 else Color.GRAY)
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
	var reward_text = "灵石: %d\n经验: %d" % [
		rewards.get("spirit_stones", rewards.get("spirit_stone", 0)),
		rewards.get("exp", 0)
	]
	if rewards.has("contribution"):
		reward_text += "\n贡献度: %d" % rewards.get("contribution", 0)
	if rewards.has("arena_points"):
		reward_text += "\n竞技积分: %d" % rewards.get("arena_points", 0)
	vbox.get_node("Rewards").text = reward_text
	
	_selected_activity_id = activity.get("id", "")

func _on_start_activity() -> void:
	var activity_id = _selected_activity_id
	if activity_id == "":
		return
	
	# 调用日常活动系统开始活动
	if _daily_activity_system and _daily_activity_system.has_method("start_activity"):
		var result = _daily_activity_system.start_activity(activity_id)
		if result.get("success", false):
			# 活动成功开始，完成活动
			if _daily_activity_system.has_method("complete_activity"):
				_daily_activity_system.complete_activity(activity_id, true, 1.0)
			_load_real_data()
			activity_started.emit(activity_id)
		else:
			push_warning("活动开始失败: %s" % str(result.get("reason", "未知错误")))
	else:
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
	
	# 调用系统领取奖励
	if _daily_activity_system and _daily_activity_system.has_method("claim_vitality_reward"):
		_daily_activity_system.claim_vitality_reward(index)
	
	vitality_reward_claimed.emit(reward_level["level"])
	_update_vitality_display()

func _update_vitality_display() -> void:
	var header = _main_container.get_child(0)
	var date_label = header.get_node_or_null("DateLabel")
	if date_label:
		date_label.text = "今日活跃度: %d/200" % _current_vitality
	
	_vitality_progress.value = _current_vitality
	
	# 找到活力面板中的vbox（第3个子节点）
	if _main_container.get_child_count() > 2:
		var vitality_container = _main_container.get_child(2)
		var vbox = vitality_container.get_child(0) if vitality_container.get_child_count() > 0 else null
		if vbox:
			var vitality_label = vbox.get_node_or_null("VitalityLabel")
			if vitality_label:
				vitality_label.text = "%d / 200" % _current_vitality
			
			# 更新奖励按钮状态
			for i in range(VITALITY_REWARDS.size()):
				var reward_level = VITALITY_REWARDS[i]
				var reward_btn = vbox.get_node_or_null("VitalityBtn_%d" % i)
				if reward_btn:
					if _vitality_rewards_claimed.has(i):
						reward_btn.text = "✓%d" % reward_level["level"]
						reward_btn.disabled = true
					elif _current_vitality >= reward_level["level"]:
						reward_btn.text = "领%d" % reward_level["level"]
						reward_btn.disabled = false
					else:
						reward_btn.text = "%d" % reward_level["level"]
						reward_btn.disabled = true

func add_vitality(amount: int) -> void:
	_current_vitality = min(_current_vitality + amount, 200)
	_update_vitality_display()

func _on_close_clicked() -> void:
	visible = false
	daily_activity_panel_closed.emit()

func _on_refresh_clicked() -> void:
	# 刷新活动列表
	_load_real_data()

func setup_activities(activities: Array) -> void:
	_daily_activities = activities
	_update_activity_list()

func show_panel() -> void:
	_load_real_data()
	visible = true

func hide_panel() -> void:
	visible = false
