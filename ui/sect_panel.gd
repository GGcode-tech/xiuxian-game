## 门派面板 - 门派信息/技能/贡献/商店
extends Control

signal sect_panel_closed()
signal sect_shop_requested()
signal sect_leave_requested()

# 当前门派数据
var _current_sect: Dictionary = {}
var _member_contribution: int = 0
var _member_rank: String = "普通成员"

# UI组件
var _main_container: VBoxContainer
var _info_panel: PanelContainer
var _skills_panel: PanelContainer
var _contribution_panel: PanelContainer
var _shop_button: Button
var _leave_button: Button

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
	_build_sample_sect_data()

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
	sect_name_label.text = "门派名称"
	sect_name_label.add_theme_font_size_override("font_size", 24)
	info_vbox.add_child(sect_name_label)
	
	var sect_novel_label = Label.new()
	sect_novel_label.text = "所属: -"
	info_vbox.add_child(sect_novel_label)
	
	var sect_desc = Label.new()
	sect_desc.text = "门派描述"
	sect_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(sect_desc)
	
	var sect_feature = Label.new()
	sect_feature.text = "门派特色: -"
	info_vbox.add_child(sect_feature)
	
	var member_count = Label.new()
	member_count.text = "成员数量: -"
	info_vbox.add_child(member_count)
	
	var sect_level = Label.new()
	sect_level.text = "门派等级: -"
	info_vbox.add_child(sect_level)
	
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
	contrib_progress.value = 2500
	contrib_progress.show_percentage = false
	contrib_vbox.add_child(contrib_progress)
	
	var contrib_label = Label.new()
	contrib_label.text = "2500 / 10000"
	contrib_vbox.add_child(contrib_label)
	
	var rank_label = Label.new()
	rank_label.text = "当前职位: 普通成员"
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

func _build_sample_sect_data() -> void:
	_sect_skills = [
		{"name": "基础剑法", "level": 1, "desc": "门派入门剑法", "unlocked": true},
		{"name": "御剑术", "level": 3, "desc": "御剑飞行攻敌", "unlocked": true},
		{"name": "剑意决", "level": 5, "desc": "凝聚剑意", "unlocked": false},
		{"name": "万剑归宗", "level": 10, "desc": "剑道至高奥义", "unlocked": false}
	]
	_update_skills_display()

func _update_skills_display() -> void:
	var skills_vbox = _skills_panel.get_child(0).get_child(0)
	for child in skills_vbox.get_children():
		child.queue_free()
	
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
		status_label.add_theme_color_override("font_color", Color.GREEN if skill.get("unlocked", false) else Color.ORANGE)
		hbox.add_child(status_label)
		
		skills_vbox.add_child(skill_panel)

func setup_sect(sect_data: Dictionary) -> void:
	_current_sect = sect_data
	update_display()

func update_display() -> void:
	if _current_sect.is_empty():
		return
	
	var info_vbox = _info_panel.get_child(0)
	var children = info_vbox.get_children()
	
	children[0].text = _current_sect.get("name", "未知门派")
	children[1].text = "所属: %s" % _current_sect.get("novel", "未知")
	children[2].text = _current_sect.get("description", "无描述")
	children[3].text = "门派特色: %s" % _current_sect.get("feature", "无")
	children[4].text = "成员数量: %d" % _current_sect.get("member_count", 0)
	children[5].text = "门派等级: %d 级" % _current_sect.get("level", 1)

func update_contribution(contribution: int, rank: String) -> void:
	_member_contribution = contribution
	_member_rank = rank
	# 更新贡献面板...

func update_member_info(name: String, contribution: int, rank: String) -> void:
	_member_contribution = contribution
	_member_rank = rank

func _on_close_clicked() -> void:
	visible = false
	sect_panel_closed.emit()

func _on_shop_clicked() -> void:
	sect_shop_requested.emit()

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
	sect_leave_requested.emit()
	visible = false

func _on_contribute_clicked() -> void:
	# 捐献界面...
	pass

func show_panel() -> void:
	visible = true

func hide_panel() -> void:
	visible = false