## 门派面板 - 门派信息/技能/贡献/商店（接入SectSystem真实数据）
extends Control

signal sect_panel_closed()
signal sect_shop_requested()
signal sect_leave_requested()

# 当前门派数据
var _current_sect: Dictionary = {}
var _member_contribution: int = 0
var _member_rank: String = "普通成员"

# 系统引用
var _sect_system: Node = null

# UI组件
var _main_container: VBoxContainer
var _info_panel: PanelContainer
var _skills_panel: PanelContainer
var _contribution_panel: PanelContainer
var _shop_button: Button
var _leave_button: Button
var _join_button: Button

# 门派技能列表
var _sect_skills: Array = []

func _ready() -> void:
	visible = false
	# 自动截图
	ScreenshotSystem.auto_screenshot("13_门派")
	_custom_init()

func _custom_init() -> void:
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.15, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	_main_container = VBoxContainer.new()
	_main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_container.add_theme_constant_override("separation", 15)
	add_child(_main_container)

	_build_header()
	_build_content_area()
	_build_footer()

func _build_header() -> void:
	var header = HBoxContainer.new()
	header.custom_minimum_size.y = 60

	var title = Label.new()
	title.text = "🏛️ 门派信息"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.pressed.connect(_on_close_clicked)
	header.add_child(close_btn)

	_main_container.add_child(header)

	# 分隔线
	var sep = HSeparator.new()
	_main_container.add_child(sep)

func _build_content_area() -> void:
	# 使用HBoxContainer左右布局
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.y = 400
	_main_container.add_child(hbox)

	# 左侧：门派基本信息
	_info_panel = PanelContainer.new()
	_info_panel.custom_minimum_size = Vector2(300, 380)
	var info_vbox = VBoxContainer.new()
	_info_panel.add_child(info_vbox)

	var sect_name_label = Label.new()
	sect_name_label.text = "未加入门派"
	sect_name_label.add_theme_font_size_override("font_size", 24)
	sect_name_label.name = "SectNameLabel"
	info_vbox.add_child(sect_name_label)

	var sect_novel_label = Label.new()
	sect_novel_label.text = "所属: -"
	sect_novel_label.name = "SectNovelLabel"
	info_vbox.add_child(sect_novel_label)

	var sect_desc = Label.new()
	sect_desc.text = "加入一个门派以获得门派技能和属性加成"
	sect_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	sect_desc.name = "SectDescLabel"
	info_vbox.add_child(sect_desc)

	var sect_feature = Label.new()
	sect_feature.text = "门派特色: -"
	sect_feature.name = "SectFeatureLabel"
	info_vbox.add_child(sect_feature)

	var member_count = Label.new()
	member_count.text = "门派等级: -"
	member_count.name = "MemberCountLabel"
	info_vbox.add_child(member_count)

	# 加入门派列表区域
	var join_title = Label.new()
	join_title.text = "--- 可加入门派 ---"
	join_title.name = "JoinTitle"
	info_vbox.add_child(join_title)

	var join_scroll = ScrollContainer.new()
	join_scroll.custom_minimum_size = Vector2(280, 150)
	join_scroll.name = "JoinScroll"
	var join_vbox = VBoxContainer.new()
	join_scroll.add_child(join_vbox)
	info_vbox.add_child(join_scroll)

	hbox.add_child(_info_panel)

	# 右侧：技能和贡献标签页
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(400, 380)
	hbox.add_child(right_panel)

	# 标签切换按钮
	var tab_hbox = HBoxContainer.new()
	var skills_tab = Button.new()
	skills_tab.text = "门派技能"
	skills_tab.pressed.connect(_show_skills_tab)
	right_panel.add_child(tab_hbox)

	var contrib_tab = Button.new()
	contrib_tab.text = "贡献度"
	contrib_tab.pressed.connect(_show_contribution_tab)
	tab_hbox.add_child(skills_tab)
	tab_hbox.add_child(contrib_tab)

	# 技能面板
	_skills_panel = PanelContainer.new()
	_skills_panel.custom_minimum_size = Vector2(400, 300)
	var skills_scroll = ScrollContainer.new()
	_skills_panel.add_child(skills_scroll)
	var skills_vbox = VBoxContainer.new()
	skills_scroll.add_child(skills_vbox)
	right_panel.add_child(_skills_panel)

	# 贡献面板
	_contribution_panel = PanelContainer.new()
	_contribution_panel.custom_minimum_size = Vector2(400, 300)
	_contribution_panel.visible = false
	var contrib_vbox = VBoxContainer.new()
	_contribution_panel.add_child(contrib_vbox)

	var contrib_title = Label.new()
	contrib_title.text = "我的贡献度"
	contrib_title.add_theme_font_size_override("font_size", 20)
	contrib_vbox.add_child(contrib_title)

	var contrib_progress = ProgressBar.new()
	contrib_progress.max_value = 10000
	contrib_progress.value = 0
	contrib_progress.show_percentage = false
	contrib_progress.name = "ContribProgress"
	contrib_vbox.add_child(contrib_progress)

	var contrib_label = Label.new()
	contrib_label.text = "0 / 10000"
	contrib_label.name = "ContribLabel"
	contrib_vbox.add_child(contrib_label)

	var rank_label = Label.new()
	rank_label.text = "当前职位: 普通弟子"
	rank_label.name = "RankLabel"
	contrib_vbox.add_child(rank_label)

	var contribute_btn = Button.new()
	contribute_btn.text = "捐献资源提升贡献"
	contribute_btn.pressed.connect(_on_contribute_clicked)
	contrib_vbox.add_child(contribute_btn)

	right_panel.add_child(_contribution_panel)

func _show_skills_tab() -> void:
	_skills_panel.visible = true
	_contribution_panel.visible = false

func _show_contribution_tab() -> void:
	_skills_panel.visible = false
	_contribution_panel.visible = true

func _build_footer() -> void:
	var footer = HBoxContainer.new()
	footer.custom_minimum_size.y = 60
	footer.alignment = BoxContainer.ALIGNMENT_CENTER

	# 加入门派按钮（当没有门派时显示）
	_join_button = Button.new()
	_join_button.text = "🏛️ 加入门派"
	_join_button.custom_minimum_size = Vector2(150, 50)
	_join_button.pressed.connect(_on_join_clicked)
	footer.add_child(_join_button)

	_shop_button = Button.new()
	_shop_button.text = "🏪 门派商店"
	_shop_button.custom_minimum_size = Vector2(150, 50)
	_shop_button.pressed.connect(_on_shop_clicked)
	footer.add_child(_shop_button)

	var spacer = Control.new()
	spacer.custom_minimum_size.x = 50
	footer.add_child(spacer)

	_leave_button = Button.new()
	_leave_button.text = "🚪 退出宗门"
	_leave_button.custom_minimum_size = Vector2(150, 50)
	_leave_button.pressed.connect(_on_leave_clicked)
	footer.add_child(_leave_button)

	_main_container.add_child(footer)

# ==================== 真实数据加载 ====================

func setup_system(sys: Node) -> void:
	_sect_system = sys

func _load_real_data() -> void:
	if not _sect_system:
		# 尝试使用全局autoload
		if has_node("/root/SectSystem"):
			_sect_system = get_node("/root/SectSystem")
		else:
			return

	# 检查玩家是否已加入门派
	var player_sect_id = _sect_system.player_sect_id if _sect_system else ""

	if player_sect_id != "" and _sect_system.has_method("get_sect"):
		# 已加入门派，显示门派信息
		var sect_data = _sect_system.get_sect(player_sect_id)
		if sect_data:
			_current_sect = {
				"id": sect_data.id,
				"name": sect_data.name,
				"novel": sect_data.novel_source,
				"description": sect_data.description,
				"feature": str(sect_data.bonus_stats),
				"skills": sect_data.skills,
				"partners": sect_data.partners,
				"level": 1,
				"member_count": 0,
			}
			_sect_skills = []
			for skill_id in sect_data.skills:
				_sect_skills.append({
					"id": skill_id,
					"name": skill_id,
					"level": 1,
					"desc": "门派技能",
					"unlocked": false,
				})

		# 获取贡献度信息
		var contrib = _sect_system.get("player_contribution")
		if contrib:
			_member_contribution = contrib.get("total_contribution", 0)
			_member_rank = (
				_sect_system.get_contribution_rank_name()
				if _sect_system.has_method(
					"get_contribution_rank_name")
				else "普通弟子")

		_update_skills_display()
		_update_contribution_display()
		_show_member_mode()
	else:
		# 未加入门派，显示可加入列表
		_show_join_mode()

func _show_member_mode() -> void:
	"""显示已加入门派的模式"""
	_join_button.visible = false
	_leave_button.visible = true
	_shop_button.visible = true

	# 更新门派信息面板
	var info_vbox = _info_panel.get_child(0)
	info_vbox.get_node("SectNameLabel").text = _current_sect.get("name", "未知门派")
	info_vbox.get_node("SectNovelLabel").text = "所属: %s" % _current_sect.get("novel", "未知")
	info_vbox.get_node("SectDescLabel").text = _current_sect.get("description", "无描述")
	info_vbox.get_node("SectFeatureLabel").text = "门派特色: %s" % _current_sect.get("feature", "无")
	info_vbox.get_node("MemberCountLabel").text = "门派等级: %d 级" % _current_sect.get("level", 1)
	info_vbox.get_node("JoinTitle").visible = false
	info_vbox.get_node("JoinScroll").visible = false

func _show_join_mode() -> void:
	"""显示可加入门派的模式"""
	_join_button.visible = true
	_leave_button.visible = false
	_shop_button.visible = false

	# 更新门派信息面板
	var info_vbox = _info_panel.get_child(0)
	info_vbox.get_node("SectNameLabel").text = "选择门派加入"
	info_vbox.get_node("SectNovelLabel").text = ""
	info_vbox.get_node("SectDescLabel").text = "选择一个门派以获得门派技能和属性加成"
	info_vbox.get_node("SectFeatureLabel").text = ""
	info_vbox.get_node("MemberCountLabel").text = ""
	info_vbox.get_node("JoinTitle").visible = true
	info_vbox.get_node("JoinScroll").visible = true

	# 填充可加入门派列表
	var join_scroll = info_vbox.get_node("JoinScroll")
	var join_vbox = join_scroll.get_child(0)
	for child in join_vbox.get_children():
		child.queue_free()

	if _sect_system and _sect_system.has_method("get_all_sects"):
		var all_sects = _sect_system.get_all_sects()
		for sect in all_sects:
			var sect_btn = Button.new()
			sect_btn.custom_minimum_size = Vector2(260, 50)
			sect_btn.text = "%s (%s)\n%s" % [
				sect.name,
				sect.novel_source,
				sect.description.substr(0, 30) + "..."
			]
			sect_btn.pressed.connect(_on_sect_to_join.bind(sect.id))
			join_vbox.add_child(sect_btn)

	# 清空技能和贡献面板
	_sect_skills = []
	_update_skills_display()

func _on_sect_to_join(sect_id: String) -> void:
	"""加入门派"""
	if _sect_system and _sect_system.has_method("join_sect"):
		var success = _sect_system.join_sect(sect_id)
		if success:
			_load_real_data()

func _update_skills_display() -> void:
	var skills_scroll = _skills_panel.get_child(0)
	var skills_vbox = skills_scroll.get_child(0)
	for child in skills_vbox.get_children():
		child.queue_free()

	if _sect_skills.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无门派技能"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		skills_vbox.add_child(empty_label)
		return

	for skill in _sect_skills:
		var skill_panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		skill_panel.add_child(hbox)

		var name_label = Label.new()
		name_label.text = skill.get("name", "")
		name_label.custom_minimum_size.x = 100
		hbox.add_child(name_label)

		var level_label = Label.new()
		level_label.text = "等级: %d" % skill.get("level", 1)
		hbox.add_child(level_label)

		var desc_label = Label.new()
		desc_label.text = skill.get("desc", "")
		desc_label.custom_minimum_size.x = 150
		hbox.add_child(desc_label)

		var status_label = Label.new()
		status_label.text = "✓ 已解锁" if skill.get("unlocked", false) else "🔒 未解锁"
		status_label.add_theme_color_override(
			"font_color",
			Color.GREEN if skill.get("unlocked", false)
			else Color.ORANGE)
		hbox.add_child(status_label)

		skills_vbox.add_child(skill_panel)

func _update_contribution_display() -> void:
	var contrib_vbox = _contribution_panel.get_child(0)
	var progress = contrib_vbox.get_node_or_null("ContribProgress")
	var label = contrib_vbox.get_node_or_null("ContribLabel")
	var rank = contrib_vbox.get_node_or_null("RankLabel")

	if progress:
		progress.value = _member_contribution
	if label:
		label.text = "%d / 10000" % _member_contribution
	if rank:
		rank.text = "当前职位: %s" % _member_rank

func setup_sect(sect_data: Dictionary) -> void:
	_current_sect = sect_data
	update_display()

func update_display() -> void:
	if _current_sect.is_empty():
		return

	var info_vbox = _info_panel.get_child(0)
	var children = info_vbox.get_children()

	if children.size() >= 6:
		children[0].text = _current_sect.get("name", "未知门派")
		children[1].text = "所属: %s" % _current_sect.get("novel", "未知")
		children[2].text = _current_sect.get("description", "无描述")
		children[3].text = "门派特色: %s" % _current_sect.get("feature", "无")
		children[4].text = "成员数量: %d" % _current_sect.get("member_count", 0)
		children[5].text = "门派等级: %d 级" % _current_sect.get("level", 1)

func update_contribution(contribution: int, rank: String) -> void:
	_member_contribution = contribution
	_member_rank = rank
	_update_contribution_display()

func update_member_info(_sect_name: String, contribution: int, rank: String) -> void:
	_member_contribution = contribution
	_member_rank = rank

# ==================== 事件处理 ====================

func _on_close_clicked() -> void:
	visible = false
	sect_panel_closed.emit()

func _on_shop_clicked() -> void:
	sect_shop_requested.emit()

func _on_join_clicked() -> void:
	# 如果没有选择门派，不操作（门派列表已在界面中）
	pass

func _on_leave_clicked() -> void:
	# 显示确认对话框
	_show_leave_confirmation()

func _show_leave_confirmation() -> void:
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "确定要退出宗门吗？退出后将与宗门解除所有关系。"
	confirm_dialog.confirmed.connect(_on_leave_confirmed)
	add_child(confirm_dialog)
	confirm_dialog.popup_centered()

func _on_leave_confirmed() -> void:
	# 调用门派系统退出
	if _sect_system and _sect_system.has_method("leave_sect"):
		_sect_system.leave_sect()
	sect_leave_requested.emit()
	_load_real_data()

func _on_contribute_clicked() -> void:
	# 调用门派系统增加贡献度
	if _sect_system and _sect_system.has_method("add_contribution"):
		_sect_system.add_contribution(100, "捐献资源")
		_load_real_data()

func show_panel() -> void:
	_load_real_data()
	visible = true

func hide_panel() -> void:
	visible = false
