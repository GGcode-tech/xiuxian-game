## 主场景脚本 - 管理所有UI面板生命周期
## 整合：角色创建 → 主界面 → 各功能面板
extends Node3D

# ==================== 场景引用 ====================
@onready var world = $World
@onready var ui_layer: CanvasLayer = $UILayer

# ==================== 旧面板（保留）====================
const START_MENU_SCENE     = preload("res://ui/start_menu.tscn")
const HUD_SCENE            = preload("res://ui/hud.tscn")
const PAUSE_MENU_SCENE     = preload("res://ui/pause_menu.tscn")
const GAME_OVER_SCENE      = preload("res://ui/game_over.tscn")
const CHARACTER_PANEL_SCENE = preload("res://ui/character_panel.tscn")
const FAMILY_PANEL_SCENE   = preload("res://ui/family_panel.tscn")
const NOTIFICATION_SCENE   = preload("res://ui/notification_system.tscn")

# ==================== 新面板 ====================
const CHARACTER_CREATE_SCENE = preload("res://ui/character_create_panel.tscn")
const MAIN_MENU_SCENE        = preload("res://ui/main_menu.tscn")
const SECT_PANEL_SCENE       = preload("res://ui/sect_panel.tscn")
const SPIRIT_BEAST_SCENE     = preload("res://ui/spirit_beast_panel.tscn")
const EQUIPMENT_SCENE        = preload("res://ui/equipment_panel.tscn")
const DUNGEON_SCENE          = preload("res://ui/dungeon_panel.tscn")
const DAILY_ACTIVITY_SCENE  = preload("res://ui/daily_activity_panel.tscn")
const COMBAT_SCENE           = preload("res://ui/combat_panel.tscn")

# ==================== 核心系统脚本 ====================
const CombatSystemScript         = preload("res://scripts/systems/combat_system.gd")
const DungeonSystemScript        = preload("res://scripts/systems/dungeon_system.gd")
const SectSystemScript           = preload("res://scripts/systems/sect_system.gd")
const SpiritBeastSystemScript    = preload("res://scripts/systems/spirit_beast_system.gd")
const EquipmentSystemScript      = preload("res://scripts/systems/equipment_system.gd")
const DailyActivitySystemScript  = preload("res://scripts/systems/daily_activity_system.gd")
const AlchemySystemScript        = preload("res://scripts/systems/alchemy_system.gd")
const DialogueSystemScript       = preload("res://scripts/systems/dialogue_system.gd")

# ==================== 面板实例引用 ====================
var _start_menu:        Control = null
var _character_create:  Control = null
var _main_menu:         Control = null
var _hud:               Control = null
var _pause_menu:        Control = null
var _game_over:         Control = null
var _character_panel:  Control = null
var _family_panel:      Control = null
var _notification:      Control = null
var _sect_panel:        Control = null
var _spirit_beast_panel:Control = null
var _equipment_panel:   Control = null
var _dungeon_panel:      Control = null
var _daily_panel:       Control = null
var _combat_panel:      Control = null
var _dialogue_panel:    Control = null

# ==================== 核心系统实例引用 ====================
var combat_system: Node = null
var dungeon_system: Node = null
var sect_system: Node = null
var spirit_beast_system: Node = null
var equipment_system: Node = null
var daily_activity_system: Node = null
var alchemy_system: Node = null
var dialogue_system: Node = null

# 当前游戏状态
var current_state: GameManager.GameState = GameManager.GameState.MAIN_MENU

# 当前玩家角色数据（新建角色流程产生）
var _player_data: Dictionary = {}

# ==================== 生命周期 ====================

func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_started.connect(_on_game_started)
	_initialize_game()


func _initialize_game() -> void:
	DataManager.load_all_data()
	AudioManager.initialize()

	# 实例化核心系统
	_instantiate_systems()

	_notification = NOTIFICATION_SCENE.instantiate()
	ui_layer.add_child(_notification)

	_show_start_menu()


func _instantiate_systems() -> void:
	# 战斗系统
	combat_system = Node.new()
	combat_system.name = "CombatSystem"
	combat_system.set_script(CombatSystemScript)
	add_child(combat_system)

	# 副本系统
	dungeon_system = Node.new()
	dungeon_system.name = "DungeonSystem"
	dungeon_system.set_script(DungeonSystemScript)
	add_child(dungeon_system)

	# 门派系统
	sect_system = Node.new()
	sect_system.name = "SectSystem"
	sect_system.set_script(SectSystemScript)
	add_child(sect_system)

	# 灵兽系统
	spirit_beast_system = Node.new()
	spirit_beast_system.name = "SpiritBeastSystem"
	spirit_beast_system.set_script(SpiritBeastSystemScript)
	add_child(spirit_beast_system)

	# 装备系统
	equipment_system = Node.new()
	equipment_system.name = "EquipmentSystem"
	equipment_system.set_script(EquipmentSystemScript)
	add_child(equipment_system)

	# 日常活动系统
	daily_activity_system = Node.new()
	daily_activity_system.name = "DailyActivitySystem"
	daily_activity_system.set_script(DailyActivitySystemScript)
	add_child(daily_activity_system)

	# 炼丹系统
	alchemy_system = Node.new()
	alchemy_system.name = "AlchemySystem"
	alchemy_system.set_script(AlchemySystemScript)
	add_child(alchemy_system)

	print("[MainScene] 核心系统实例化完成：7个系统已加入场景树")

	# 对话系统
	dialogue_system = Node.new()
	dialogue_system.name = "DialogueSystem"
	dialogue_system.set_script(DialogueSystemScript)
	add_child(dialogue_system)


# ==================== 状态机 ====================

func _on_state_changed(new_state: GameManager.GameState) -> void:
	current_state = new_state
	match new_state:
		GameManager.GameState.MAIN_MENU:
			_show_start_menu()
		GameManager.GameState.PLAYING:
			_show_main_menu()
		GameManager.GameState.PAUSED:
			_show_pause_menu()
		GameManager.GameState.GAME_OVER:
			_show_game_over()


func _on_game_started() -> void:
	world.initialize()
	GameManager.set_state(GameManager.GameState.PLAYING)


# ==================== 启动流程 ====================

func _show_start_menu() -> void:
	_hide_all()
	if not _start_menu:
		_start_menu = START_MENU_SCENE.instantiate()
		_start_menu.start_game_requested.connect(_on_start_game_requested)
		_start_menu.load_game_requested.connect(_on_load_game_requested)
		_start_menu.settings_requested.connect(_on_settings_requested)
		ui_layer.add_child(_start_menu)
	_start_menu.show()
	# 自动截图
	ScreenshotSystem.auto_screenshot("01_开始菜单")


# ==================== 角色创建流程 ====================

func _on_start_game_requested() -> void:
	_start_menu.hide()
	_show_character_create()


func _on_load_game_requested() -> void:
	# 尝试加载快速存档
	if SaveManager.has_method("load_game"):
		SaveManager.load_game("quick")


func _on_settings_requested() -> void:
	# 暂时跳转到暂停菜单（设置功能）
	GameManager.set_state(GameManager.GameState.PAUSED)


func _show_character_create() -> void:
	if not _character_create:
		_character_create = CHARACTER_CREATE_SCENE.instantiate()
		_character_create.character_created.connect(_on_character_created)
		_character_create.back_to_menu_requested.connect(_on_creation_cancelled)
		ui_layer.add_child(_character_create)
	_character_create.show()
	# 自动截图
	ScreenshotSystem.auto_screenshot("02_角色创建")


func _on_character_created(char_data: Dictionary) -> void:
	_player_data = char_data
	# 初始化 GameManager 中的角色数据
	_apply_new_character(char_data)
	# 关闭创建界面 → 跳转主界面
	_character_create.hide()
	GameManager.is_game_started = true
	# 初始化3D世界
	world.initialize()
	GameManager.set_state(GameManager.GameState.PLAYING)
	# 自动截图
	ScreenshotSystem.auto_screenshot("03_角色创建完成")


func _on_creation_cancelled() -> void:
	_character_create.hide()
	_start_menu.show()


func _apply_new_character(data: Dictionary) -> void:
	# 替换原有 family-based 初始化为角色数据
	GameManager.game_time = {"year": 1, "month": 1, "day": 1}
	GameManager.game_speed = 1.0
	GameManager.is_paused = false

	var ch = _create_player_dict(data)
	GameManager.add_character(ch)
	GameManager.player_family_id = ch["family_id"]
	# 创建家族（world需要通过get_player_family获取成员列表）
	var family = {
		"id": ch["family_id"],
		"name": data.get("name", "修仙者") + "家族",
		"founder_id": ch["id"],
		"founded_year": 1,
		"level": 1,
		"members": [ch["id"]],
		"unlocked_buildings": [],
	}
	GameManager.add_family(family)


func _create_player_dict(data: Dictionary) -> Dictionary:
	var stats = _calculate_stats(data.get("attributes", {}))
	var ch: Dictionary = {
		"id": "player_%d" % Time.get_ticks_msec(),
		"name": data.get("name", "修仙者"),
		"gender": 0,
		"age": 18,
		"family_id": "family_player",
		"generation": 1,
		"parent_ids": [],
		"spouse_id": "",
		"children_ids": [],
		"spirit_root": {"gold": 0.2, "wood": 0.2, "water": 0.2, "fire": 0.2, "earth": 0.2},
		"bloodline": "",
		"bloodline_purity": 0.0,
		"realm_id": "realm_lianqi",
		"realm_exp": 0,
		"base_stats": stats,
		"hp": stats.get("max_hp", 100),
		"mp": stats.get("max_mp", 50),
		"is_alive": true,
		"techniques": [],
		"items": [],
		"element": "wood",
		"role": "cultivator",
		"sect_id": data.get("sect", ""),
		"sect_name": data.get("sect_name", "无"),
		"spirit_beasts": [],
		"equipment": {},
		"resources": {
			"spirit_stone": 1000,
			"essence": 0,
			"spirit_jade": 0,
			"stamina": 100,
			"max_stamina": 100,
			"energy": 50,
			"max_energy": 50,
		},
	}
	return ch


func _calculate_stats(attributes: Dictionary) -> Dictionary:
	var base_hp = 100
	var base_mp = 50
	var base_attack = 10
	var base_defense = 5
	var base_speed = 10
	var base_spirit = 10

	return {
		"max_hp": base_hp + attributes.get("constitution", 0) * 10,
		"max_mp": base_mp + attributes.get("spirit", 0) * 5,
		"attack": base_attack + attributes.get("strength", 0) * 3,
		"defense": base_defense + attributes.get("constitution", 0) * 2,
		"speed": base_speed + attributes.get("agility", 0) * 2,
		"spirit": base_spirit + attributes.get("spirit", 0) * 3,
		"luck": attributes.get("luck", 0),
	}


# ==================== 主游戏界面 ====================

func _show_main_menu() -> void:
	_hide_all()
	get_tree().paused = false

	# HUD（3D场景上的HUD）
	if not _hud:
		_hud = HUD_SCENE.instantiate()
		_hud.character_selected.connect(_on_character_selected)
		_hud.family_panel_requested.connect(_on_family_panel_requested)
		_hud.map_panel_requested.connect(_on_map_panel_requested)
		ui_layer.add_child(_hud)
	_hud.show()

	# 主菜单面板
	if not _main_menu:
		_main_menu = MAIN_MENU_SCENE.instantiate()
		_main_menu.menu_button_pressed.connect(_on_menu_button_pressed)
		ui_layer.add_child(_main_menu)

	# 自动截图
	ScreenshotSystem.auto_screenshot("04_主界面")

	# 更新主菜单角色信息
	var player = _get_player_character()
	if _main_menu.has_method("update_character_info"):
		_main_menu.update_character_info(player)
	if _main_menu.has_method("update_resources"):
		var res = player.get("resources", {}) if player else {}
		_main_menu.update_resources(res)

	_main_menu.show()


func _get_player_character() -> Dictionary:
	for cid in GameManager.all_characters:
		var c = GameManager.all_characters[cid]
		if c.get("generation", 0) == 1 and c.get("role", "") == "cultivator":
			return c
	return {}


# ==================== 功能面板（主菜单按钮触发）====================

func _on_menu_button_pressed(menu_type: String) -> void:
	match menu_type:
		"dungeon":
			_show_dungeon_panel()
		"sect":
			_show_sect_panel()
		"spirit_beast":
			_show_spirit_beast_panel()
		"equipment":
			_show_equipment_panel()
		"daily":
			_show_daily_panel()
		"inventory":
			_show_inventory()
		"settings":
			_show_settings()
		"character":
			_show_character_panel()
		"combat":
			_show_combat_panel()
		"back":
			_hide_all_overlay_panels()
			if _main_menu:
				_main_menu.show()


func _show_sect_panel() -> void:
	_hide_all_overlay_panels()
	if not _sect_panel:
		_sect_panel = SECT_PANEL_SCENE.instantiate()
		_sect_panel.sect_panel_closed.connect(_on_sect_panel_closed)
		_sect_panel.sect_leave_requested.connect(_on_sect_leave_requested)
		ui_layer.add_child(_sect_panel)
	_sect_panel.setup_system(sect_system)
	_sect_panel.show()


func _show_spirit_beast_panel() -> void:
	_hide_all_overlay_panels()
	if not _spirit_beast_panel:
		_spirit_beast_panel = SPIRIT_BEAST_SCENE.instantiate()
		_spirit_beast_panel.spirit_beast_panel_closed.connect(_on_spirit_beast_panel_closed)
		ui_layer.add_child(_spirit_beast_panel)
	_spirit_beast_panel.setup_system(spirit_beast_system)
	_spirit_beast_panel.show()


func _show_equipment_panel() -> void:
	_hide_all_overlay_panels()
	if not _equipment_panel:
		_equipment_panel = EQUIPMENT_SCENE.instantiate()
		_equipment_panel.equipment_panel_closed.connect(_on_equipment_panel_closed)
		ui_layer.add_child(_equipment_panel)
	_equipment_panel.setup_system(equipment_system)
	_equipment_panel.show()


func _show_dungeon_panel() -> void:
	_hide_all_overlay_panels()
	if not _dungeon_panel:
		_dungeon_panel = DUNGEON_SCENE.instantiate()
		_dungeon_panel.dungeon_panel_closed.connect(_on_dungeon_panel_closed)
		_dungeon_panel.dungeon_started.connect(_on_dungeon_started)
		ui_layer.add_child(_dungeon_panel)
	_dungeon_panel.setup_system(dungeon_system)
	_dungeon_panel.show()


func _show_daily_panel() -> void:
	_hide_all_overlay_panels()
	if not _daily_panel:
		_daily_panel = DAILY_ACTIVITY_SCENE.instantiate()
		_daily_panel.daily_activity_panel_closed.connect(_on_daily_panel_closed)
		ui_layer.add_child(_daily_panel)
	_daily_panel.setup_system(daily_activity_system)
	_daily_panel.show()


func _show_combat_panel() -> void:
	_hide_all_overlay_panels()
	if not _combat_panel:
		_combat_panel = COMBAT_SCENE.instantiate()
		_combat_panel.combat_panel_closed.connect(_on_combat_panel_closed)
		_combat_panel.combat_ended.connect(_on_combat_ended)
		ui_layer.add_child(_combat_panel)
	_combat_panel.setup_system(combat_system)
	_combat_panel.show()


func _show_dialogue_panel(npc_id: String) -> void:
	"""打开NPC对话面板"""
	_hide_all_overlay_panels()
	if not _dialogue_panel:
		var panel_script = load("res://ui/dialogue_panel.gd")
		_dialogue_panel = Control.new()
		_dialogue_panel.set_script(panel_script)
		_dialogue_panel.dialogue_panel_closed.connect(_on_dialogue_panel_closed)
		_dialogue_panel.choice_made.connect(_on_dialogue_choice_made)
		ui_layer.add_child(_dialogue_panel)

	var dialogue_data = dialogue_system.start_dialogue(npc_id)
	if not dialogue_data.is_empty():
		_dialogue_panel.show_dialogue(dialogue_data)


func _on_dialogue_panel_closed() -> void:
	if _hud:
		_hud.show()


func _on_dialogue_choice_made(npc_id: String, choice_index: int) -> void:
	"""处理对话选项选择"""
	var result = dialogue_system.process_choice(npc_id, choice_index)
	if result.is_empty():
		return

	# 应用效果
	var notifications = dialogue_system.apply_effects(result.get("effects", []))

	# 更新面板显示回复
	if _dialogue_panel and _dialogue_panel.has_method("update_response"):
		_dialogue_panel.update_response(result.get("response_text", ""))

	# 显示效果通知
	if _notification and _notification.has_method("show_notification"):
		for note in notifications:
			_notification.show_notification(note, "info")


func _show_character_panel() -> void:
	var player = _get_player_character()
	if not _character_panel:
		_character_panel = CHARACTER_PANEL_SCENE.instantiate()
		ui_layer.add_child(_character_panel)
	if player:
		_character_panel.setup(player)
	_character_panel.show()


func _show_inventory() -> void:
	# 暂时复用 character_panel 的背包分页
	_show_character_panel()


func _show_settings() -> void:
	GameManager.set_state(GameManager.GameState.PAUSED)


func _hide_all_overlay_panels() -> void:
	if _sect_panel:        _sect_panel.hide()
	if _spirit_beast_panel: _spirit_beast_panel.hide()
	if _equipment_panel:   _equipment_panel.hide()
	if _dungeon_panel:     _dungeon_panel.hide()
	if _daily_panel:       _daily_panel.hide()
	if _combat_panel:      _combat_panel.hide()
	if _dialogue_panel:    _dialogue_panel.hide()
	if _character_panel:   _character_panel.hide()
	if _family_panel:       _family_panel.hide()


# ==================== 面板关闭回调 ====================

func _on_sect_panel_closed() -> void:
	if _sect_panel:
		_sect_panel.hide()
	if _main_menu:
		_main_menu.show()


func _on_spirit_beast_panel_closed() -> void:
	if _spirit_beast_panel:
		_spirit_beast_panel.hide()
	if _main_menu:
		_main_menu.show()


func _on_equipment_panel_closed() -> void:
	if _equipment_panel:
		_equipment_panel.hide()
	if _main_menu:
		_main_menu.show()


func _on_dungeon_panel_closed() -> void:
	if _dungeon_panel:
		_dungeon_panel.hide()
	if _main_menu:
		_main_menu.show()


func _on_dungeon_started(dungeon_id: String, difficulty: String) -> void:
	"""副本开始 → 自动进入战斗面板"""
	# 隐藏副本面板，显示战斗面板
	if _dungeon_panel:
		_dungeon_panel.hide()
	# 构建敌人队伍（从副本系统的波次配置）
	var wave_enemies: Array = []
	if dungeon_system and dungeon_system.has_method("get_dungeon"):
		var dungeon = dungeon_system.get_dungeon(dungeon_id)
		if dungeon and dungeon.wave_config.size() > 0:
			# 取第一波敌人
			var first_wave = dungeon.wave_config[0]
			wave_enemies = first_wave.get("enemies", [])
	# 打开战斗面板
	_show_combat_panel()
	if _combat_panel:
		_combat_panel.start_combat_from_enemies(wave_enemies)


func _on_combat_ended(victory: bool) -> void:
	"""战斗结束 → 返回主菜单"""
	if _combat_panel:
		_combat_panel.hide()
	if _main_menu:
		_main_menu.show()
	# 如果胜利，通知副本系统波次完成
	if victory and dungeon_system and dungeon_system.has_method("on_wave_completed"):
		dungeon_system.on_wave_completed()


func _on_sect_leave_requested() -> void:
	"""门派退出请求已处理（sect_panel内部已调用sect_system）"""
	pass


func _on_daily_panel_closed() -> void:
	if _daily_panel:
		_daily_panel.hide()
	if _main_menu:
		_main_menu.show()


func _on_combat_panel_closed() -> void:
	if _combat_panel:
		_combat_panel.hide()
	if _main_menu:
		_main_menu.show()


# ==================== 原有面板（保留兼容）====================

func _show_pause_menu() -> void:
	if not _pause_menu:
		_pause_menu = PAUSE_MENU_SCENE.instantiate()
		ui_layer.add_child(_pause_menu)
	_pause_menu.show()


func _show_game_over() -> void:
	if not _game_over:
		_game_over = GAME_OVER_SCENE.instantiate()
		ui_layer.add_child(_game_over)
	_game_over.show_game_over()


func _on_character_selected(character) -> void:
	if _character_panel:
		_character_panel.setup(character)
		_character_panel.show()


func _on_family_panel_requested() -> void:
	var family = GameManager.get_player_family()
	if _family_panel and not family.is_empty():
		_family_panel.setup(family)
		_family_panel.show()


func _on_map_panel_requested() -> void:
	# TODO: 地图面板（暂未实现）
	if _notification and _notification.has_method("show_notification"):
		_notification.show_notification("地图功能开发中...", "info")


# ==================== 工具方法 ====================

func _hide_all() -> void:
	if _start_menu:        _start_menu.hide()
	if _character_create:  _character_create.hide()
	if _main_menu:         _main_menu.hide()
	if _hud:               _hud.hide()
	if _pause_menu:        _pause_menu.hide()
	if _game_over:          _game_over.hide()
	if _character_panel:   _character_panel.hide()
	if _family_panel:       _family_panel.hide()
	_hide_all_overlay_panels()


# ==================== 输入处理 ====================

func _process(delta: float) -> void:
	if current_state == GameManager.GameState.PLAYING:
		GameManager.process_tick(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameManager.GameState.PLAYING:
				GameManager.set_state(GameManager.GameState.PAUSED)
			GameManager.GameState.PAUSED:
				GameManager.set_state(GameManager.GameState.PLAYING)

	if event.is_action_pressed("toggle_speed"):
		GameManager.toggle_speed()

	if event.is_action_pressed("quick_save"):
		SaveManager.save_game("quick")

	if event.is_action_pressed("quick_load"):
		SaveManager.load_game("quick")

	# 左键点击：射线检测建筑/角色，或移动角色
	if current_state == GameManager.GameState.PLAYING and not GameManager.is_paused:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 检查是否点击在UI上
			if _get_control_at_point(event.position):
				return
			# 先做射线检测，看是否命中建筑/角色
			var hit_info = world.raycast_objects(event.position)
			if hit_info.has("type"):
				if hit_info["type"] == "building":
					_on_building_clicked(hit_info["name"])
				elif hit_info["type"] == "character":
					_on_character_clicked(hit_info["id"])
			else:
				# 未命中物体，移动角色
				world.move_player_from_screen(event.position)

		# 滚轮缩放相机
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					world._zoom_camera(-world._camera_zoom_speed)
				MOUSE_BUTTON_WHEEL_DOWN:
					world._zoom_camera(world._camera_zoom_speed)


# ==================== 建筑/角色交互 ====================

func _on_building_clicked(building_name: String) -> void:
	"""点击建筑 → 根据建筑名分发功能"""
	match building_name:
		"主殿":
			_show_sect_panel()
		"炼丹房":
			_show_daily_panel()
		"藏经阁":
			_show_character_panel()
		"修炼塔":
			_show_character_panel()
		"山门":
			_show_dungeon_panel()
		"祭坛":
			_show_sect_panel()
		"炼器房":
			_show_equipment_panel()
		_:
			if _notification and _notification.has_method("show_notification"):
				_notification.show_notification("%s 暂未开放" % building_name, "info")


func _on_character_clicked(character_id: String) -> void:
	"""点击角色 → NPC打开对话面板，玩家角色打开角色面板"""
	# 检查是否是NPC
	var npc_data = NPCSystem.get_npc(character_id)
	if not npc_data.is_empty():
		_show_dialogue_panel(character_id)
		return

	var character = GameManager.get_character(character_id)
	if character and not character.is_empty():
		_show_character_panel()
	else:
		if _notification and _notification.has_method("show_notification"):
			_notification.show_notification("角色信息暂不可用", "info")


func _get_control_at_point(point: Vector2) -> Control:
	"""检查指定屏幕坐标下是否有Control节点（使用Viewport内置检测）"""
	# 使用根视口的gui_get_hovered_control
	var viewport = get_viewport()
	if viewport:
		var hovered = viewport.gui_get_hovered_control()
		if hovered and hovered.visible:
			return hovered
	return null
