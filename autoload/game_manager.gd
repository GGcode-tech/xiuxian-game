## 游戏管理器 - 全局游戏状态管理
## 负责时间系统、游戏速度、全局事件分发
extends Node

# ==================== 信号定义 ====================
signal time_elapsed(day_data: Dictionary)
signal year_passed(year: int)
signal month_passed(month: int, year: int)
signal day_passed(day: int, month: int, year: int)
signal character_died(character)
signal character_born(character, parents: Array)
signal realm_breakthrough(character, new_realm)
signal game_loaded()
signal game_saved()

# ==================== UI状态信号 ====================
signal state_changed(new_state: int)
signal game_started()
signal speed_changed(speed: int)

# ==================== 游戏状态枚举 ====================
enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	GAME_OVER,
}

# ==================== 游戏状态 ====================
var current_state: GameState = GameState.MAIN_MENU
var current_save_slot: String = ""
var game_speed: float = 1.0
var is_paused: bool = false
var is_game_started: bool = false

# ==================== 时间系统 ====================
var game_time: Dictionary = {
	"year": 1,
	"month": 1,
	"day": 1
}

const DAYS_PER_MONTH: int = 30
const MONTHS_PER_YEAR: int = 12

# ==================== 全局数据容器 ====================
var all_characters: Dictionary = {}
var all_families: Dictionary = {}
var map_data: Dictionary = {}
var player_family_id: String = ""

# 时间积累器
var game_seed: int = 0
var _time_accumulator: float = 0.0
const TIME_PER_DAY: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[GameManager] 初始化完成")


func _process(delta: float) -> void:
	if not is_game_started or is_paused:
		return
	_time_accumulator += delta * game_speed
	if _time_accumulator >= TIME_PER_DAY:
		var days_to_process = int(_time_accumulator / TIME_PER_DAY)
		_time_accumulator -= days_to_process * TIME_PER_DAY
		for _i in range(days_to_process):
			_advance_one_day()


# ==================== 时间系统 ====================

func _advance_one_day() -> void:
	game_time["day"] += 1

	if game_time["day"] > DAYS_PER_MONTH:
		game_time["day"] = 1
		game_time["month"] += 1
		month_passed.emit(game_time["month"], game_time["year"])
		_process_month_end()

	if game_time["month"] > MONTHS_PER_YEAR:
		game_time["month"] = 1
		game_time["year"] += 1
		year_passed.emit(game_time["year"])
		_process_year_end()

	# 每日自动修炼 - 所有存活角色获得经验
	_daily_auto_cultivate()

	day_passed.emit(game_time["day"], game_time["month"], game_time["year"])
	time_elapsed.emit(game_time.duplicate())


func _process_daily_events() -> void:
	EventManager.process_daily_events()


func _process_month_end() -> void:
	EventManager.process_monthly_events()


func _process_year_end() -> void:
	EventManager.process_yearly_events()


# ==================== 每日自动修炼 ====================

func _daily_auto_cultivate() -> void:
	"""每天推进时，所有存活角色自动获得修炼经验"""
	var base_daily_exp: int = 5  # 每天基础修炼经验

	for char_id in all_characters:
		var character = all_characters[char_id]
		if not character.get("is_alive", false):
			continue

		# 计算灵根加成
		var spirit_root = character.get("spirit_root", {})
		var root_bonus = 0.0
		for element in spirit_root:
			root_bonus += spirit_root[element]
		# 灵根加成 0% ~ 150%
		var exp_gain = int(base_daily_exp * (1.0 + root_bonus))

		# 增加修炼经验
		character["realm_exp"] = character.get("realm_exp", 0) + exp_gain


# ==================== 游戏控制 ====================

func start_new_game(start_data: Dictionary = {}) -> void:
	game_time = {"year": 1, "month": 1, "day": 1}
	game_speed = 1.0
	game_seed = randi()
	is_paused = false
	is_game_started = true

	var founder_data = start_data.get("founder", {})
	var family_name = start_data.get("family_name", "修仙世家")

	# 内联创建角色（避免跨脚本类型依赖）
	var founder := _create_character_dict({
		"name": founder_data.get("name", "始祖"),
		"gender": founder_data.get("gender", 0),
		"age": founder_data.get("age", 25),
	})

	# 创建家族
	var family := _create_family_dict(founder, family_name)
	player_family_id = family["id"]

	# 初始化地图
	map_data = _create_map_dict()

	print("[GameManager] 新游戏开始，家族: %s" % family_name)


func _create_character_dict(data: Dictionary) -> Dictionary:
	var ch: Dictionary = {
		"id": "char_%d_%d" % [Time.get_ticks_msec(), randi()],
		"name": data.get("name", "未知"),
		"gender": data.get("gender", 0),
		"age": data.get("age", 0),
		"family_id": data.get("family_id", ""),
		"generation": data.get("generation", 1),
		"parent_ids": data.get("parent_ids", []),
		"spouse_id": "",
		"children_ids": [],
		"spirit_root": data.get("spirit_root", {"gold": 0.3, "wood": 0.3, "water": 0.3, "fire": 0.3, "earth": 0.3}),
		"bloodline": data.get("bloodline", ""),
		"bloodline_purity": data.get("bloodline_purity", 0.0),
		"realm_id": "mortal",
		"realm_exp": 0,
		"base_stats": {"max_hp": 100, "max_mp": 50, "attack": 10, "defense": 5, "spirit": 10, "speed": 10, "luck": 0},
		"hp": 100,
		"mp": 50,
		"is_alive": true,
		"techniques": [],
		"items": [],
		"element": "wood",
		"role": "cultivator",
	}
	add_character(ch)
	return ch


func _create_family_dict(founder: Dictionary, family_name: String) -> Dictionary:
	var family: Dictionary = {
		"id": "family_%d" % Time.get_ticks_msec(),
		"name": family_name,
		"founder_id": founder["id"],
		"founded_year": game_time["year"],
		"level": 1,
		"members": [founder["id"]],
		"unlocked_buildings": [],
	}
	add_family(family)
	return family


func _create_map_dict() -> Dictionary:
	return {
		"territories": {},
		"sects": {},
		"resource_nodes": {},
		"active_events": [],
		"event_history": [],
	}


func load_game(slot: String) -> bool:
	var success = SaveManager.load_game(slot)
	if success:
		current_save_slot = slot
		is_game_started = true
		game_loaded.emit()
		print("[GameManager] 游戏加载成功: %s" % slot)
	return success


func save_game(slot: String = "") -> bool:
	if slot == "":
		slot = current_save_slot
	var success = SaveManager.save_game(slot)
	if success:
		current_save_slot = slot
		game_saved.emit()
		print("[GameManager] 游戏保存成功: %s" % slot)
	return success


func set_pause(pause: bool) -> void:
	is_paused = pause
	print("[GameManager] %s" % ("暂停" if pause else "继续"))


func set_speed(speed: float) -> void:
	game_speed = clampf(speed, 0.5, 10.0)
	print("[GameManager] 速度设置为: %.1fx" % game_speed)


func toggle_pause() -> void:
	set_pause(not is_paused)


# ==================== 角色管理 ====================

func add_character(character: Dictionary) -> void:
	if character and character.get("id", ""):
		all_characters[character["id"]] = character


func remove_character(character_id: String) -> void:
	all_characters.erase(character_id)


func get_character(character_id: String) -> Dictionary:
	return all_characters.get(character_id, {})


func get_family_characters(family_id: String) -> Array:
	var result: Array = []
	for char_id in all_characters:
		var character = all_characters[char_id]
		if character.get("family_id", "") == family_id:
			result.append(character)
	return result


func get_player_family() -> Dictionary:
	return all_families.get(player_family_id, {})


# ==================== 家族管理 ====================

func add_family(family: Dictionary) -> void:
	if family and family.get("id", ""):
		all_families[family["id"]] = family


func get_family(family_id: String) -> Dictionary:
	return all_families.get(family_id, {})


# ==================== 工具函数 ====================

func get_formatted_time() -> String:
	return "第%d年 %d月 %d日" % [game_time["year"], game_time["month"], game_time["day"]]


func get_total_days() -> int:
	return (game_time["year"] - 1) * MONTHS_PER_YEAR * DAYS_PER_MONTH + \
			(game_time["month"] - 1) * DAYS_PER_MONTH + \
			game_time["day"]


func set_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)


func toggle_speed() -> void:
	var speed_levels = [1.0, 1.5, 3.0]
	var current_idx = 0
	for i in range(speed_levels.size()):
		if absf(game_speed - speed_levels[i]) < 0.01:
			current_idx = i
			break
	var next_idx = (current_idx + 1) % speed_levels.size()
	game_speed = speed_levels[next_idx]
	speed_changed.emit(next_idx)
	# 自动截图
	ScreenshotSystem.auto_screenshot("speed_%.1fx" % game_speed)


func process_tick(delta: float) -> void:
	if not is_game_started or is_paused:
		return
	_time_accumulator += delta * game_speed
	if _time_accumulator >= TIME_PER_DAY:
		var days_to_process = int(_time_accumulator / TIME_PER_DAY)
		_time_accumulator -= days_to_process * TIME_PER_DAY
		for _i in range(days_to_process):
			_advance_one_day()
