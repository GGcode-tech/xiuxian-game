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

	_notification = NOTIFICATION_SCENE.instantiate()
	ui_layer.add_child(_notification)

	_show_start_menu()


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
		ui_layer.add_child(_start_menu)
	_start_menu.show()


# ==================== 角色创建流程 ====================

func _on_start_game_requested(novel_index: int) -> void:
	GameManager.selected_novel = novel_index
	_start_menu.hide()
	_show_character_create()


func _show_character_create() -> void:
	if not _character_create:
		_character_create = CHARACTER_CREATE_SCENE.instantiate()
		_character_create.character_created.connect(_on_character_created)
		_character_create.creation_cancelled.connect(_on_creation_cancelled)
		ui_layer.add_child(_character_create)
	_character_create.show()


func _on_character_created(char_data: Dictionary) -> void:
	_player_data = char_data
	# 初始化 GameManager 中的角色数据
	_apply_new_character(char_data)
	# 关闭创建界面 → 跳转主界面
	_character_create.hide()
	GameManager.is_game_started = true
	GameManager.set_state(GameManager.GameState.PLAYING)


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


func _create_player_dict(data: Dictionary) -> Dictionary:
	var realm_id = "realm_lianqi"
	var realm_map = {
		"炼气": "realm_lianqi", "筑基": "realm_zhuoji", "结丹": "realm_jiandan",
		"元婴": "realm_yuanying", "化神": "realm_huashen"
	}
	realm_id = realm_map.get(data.get("realm_name", "炼气"), "realm_lianqi")

	var stats = data.get("base_stats", {})
	var ch: Dictionary = {
		"id": "player_%d" % Time.get_ticks_msec(),
		"name": data.get("name", "修仙者"),
		"gender": data.get("gender", 0),
		"age": 18,
		"family_id": "family_player",
		"generation": 1,
		"parent_ids": [],
		"spouse_id": "",
		"children_ids": [],
		"spirit_root": data.get("spirit_root", {"gold": 0.2, "wood": 0.2, "water": 0.2, "fire": 0.2, "earth": 0.2}),
		"bloodline": "",
		"bloodline_purity": 0.0,
		"realm_id": realm_id,
		"realm_exp": 0,
		"base_stats": stats,
		"hp": stats.get("max_hp", 100),
		"mp": stats.get("max_mp", 50),
		"is_alive": true,
		"techniques": [],
		"items": [],
		"element": data.get("element", "wood"),
		"role": "cultivator",
		"sect_id": data.get("sect_id", ""),
		"sect_name": data.get("sect_name", "无"),
		"novel_source": data.get("novel_source", "凡人修仙传"),
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


# ==================== 主游戏界面 ====================

func _show_main_menu() -> void:
	_hide_all()
	get_tree().paused = false

	# HUD（3D场景上的HUD）
	if not _hud:
		_hud = HUD_SCENE.instantiate()
		_hud.character_selected.connect(_on_character_selected)
		_hud.family_panel_requested.connect(_on_family_panel_requested)
		ui_layer.add_child(_hud)
	_hud.show()

	# 主菜单面板
	if not _main_menu:
		_main_menu = MAIN_MENU_SCENE.instantiate()
		_main_menu.menu_button_pressed.connect(_on_menu_button_pressed)
		ui_layer.add_child(_main_menu)

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
		ui_layer.add_child(_sect_panel)
	_sect_panel.show()


func _show_spirit_beast_panel() -> void:
	_hide_all_overlay_panels()
	if not _spirit_beast_panel:
		_spirit_beast_panel = SPIRIT_BEAST_SCENE.instantiate()
		ui_layer.add_child(_spirit_beast_panel)
	_spirit_beast_panel.show()


func _show_equipment_panel() -> void:
	_hide_all_overlay_panels()
	if not _equipment_panel:
		_equipment_panel = EQUIPMENT_SCENE.instantiate()
		ui_layer.add_child(_equipment_panel)
	_equipment_panel.show()


func _show_dungeon_panel() -> void:
	_hide_all_overlay_panels()
	if not _dungeon_panel:
		_dungeon_panel = DUNGEON_SCENE.instantiate()
		ui_layer.add_child(_dungeon_panel)
	_dungeon_panel.show()


func _show_daily_panel() -> void:
	_hide_all_overlay_panels()
	if not _daily_panel:
		_daily_panel = DAILY_ACTIVITY_SCENE.instantiate()
		ui_layer.add_child(_daily_panel)
	_daily_panel.show()


func _show_combat_panel() -> void:
	_hide_all_overlay_panels()
	if not _combat_panel:
		_combat_panel = COMBAT_SCENE.instantiate()
		ui_layer.add_child(_combat_panel)
	_combat_panel.show()


func _show_character_panel() -> void:
	var player = _get_player_character()
	if _character_panel:
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
	if _character_panel:   _character_panel.hide()
	if _family_panel:       _family_panel.hide()


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
	if _family_panel and family:
		_family_panel.setup(family)
		_family_panel.show()


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
