extends Node
## 副本系统 - 剧情副本、日常副本、波次战斗、掉落

## 波次数据
class WaveData extends RefCounted:
	var wave_number: int
	var enemies: Array[Dictionary]  # 敌人配置 [{id, name, level, count}]
	var waves_reward_given: bool = false


## 副本数据类
class DungeonData extends RefCounted:
	var id: String
	var name: String
	var novel_source: String    # 所属小说
	var dungeon_type: DungeonType
	var description: String
	var level_requirement: int = 1
	var recommended_power: int = 0
	var stamina_cost: int = 10   # 消耗体力
	var waves_count: int = 3     # 波次数量

	var rewards: Dictionary = {  # 通关奖励
		"spirit_stones": 100,
		"exp": 500,
		"items": []
	}

	var wave_config: Array[Dictionary] = []  # 波次配置
	var chapter_id: String = ""  # 所属章节
	var boss_wave: int = 3       # Boss所在波次


## 副本进度
class DungeonProgress extends RefCounted:
	var dungeon_id: String
	var is_completed: bool = false
	var completed_times: int = 0
	var best_time: int = 0       # 最快通关时间（秒）
	var last_completed_date: String = ""


## 信号
signal dungeon_started(dungeon_id: String, wave: int)
signal wave_started(wave_number: int, enemies_count: int)
signal wave_completed(wave_number: int, rewards: Dictionary)
signal dungeon_completed(dungeon_id: String, rewards: Dictionary)
signal dungeon_failed(dungeon_id: String, failed_wave: int)
signal stamina_changed(current: int, max_value: int)

## 副本类型
enum DungeonType {
	STORY,     # 剧情副本（一次性）
	DAILY,     # 日常副本（可重复）
	CHALLENGE, # 挑战副本（每周重置）
}

## 副本难度
enum DungeonDifficulty {
	EASY,     # 简单
	NORMAL,   # 普通
	HARD,     # 困难
	EXPERT,   # 专家
	HELL,     # 地狱
}

## 常量
const STAMINA_REGEN_INTERVAL: float = 5.0  # 每5分钟回复1点体力

## 副本配置数据
var dungeons_data: Dictionary = {}
var current_dungeon: DungeonData = null
var current_wave: int = 0
var dungeon_start_time: int = 0
var player_progress: Dictionary = {}  # dungeon_id -> DungeonProgress
var current_stamina: int = 100
var max_stamina: int = 100
var stamina_timer: float = 0.0

func _init() -> void:
	_init_default_dungeons()


func _init_default_dungeons() -> void:
	# 初始化默认副本（基于小说剧情场景）
	var default_dungeons: Array = [
		# ===== 凡人修仙传系列 =====
		{
			"id": "dungeon_xuegu",
			"name": "血色禁地",
			"novel_source": "凡人修仙传",
			"dungeon_type": DungeonType.STORY,
			"description": "越国七大派修士历练之地，危险与机遇并存",
			"level_requirement": 20,
			"recommended_power": 2000,
			"stamina_cost": 20,
			"waves_count": 5,
			"chapter_id": "ch_hanli_1",
			"boss_wave": 5,
			"rewards": {
				"spirit_stones": 500,
				"exp": 2000,
				"items": ["item_xuanwu", "item_jiuxuan"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_xianhui", "name": "纤绒虫", "level": 15, "count": 3}]},
				{"wave": 2, "enemies": [{"id": "enemy_jinlu", "name": "金尘虫", "level": 18, "count": 4}]},
				{"wave": 3, "enemies": [{"id": "enemy_bai serpent", "name": "百爪虫", "level": 20, "count": 3}]},
				{"wave": 4, "enemies": [{"id": "enemy_wuya", "name": "乌鸦", "level": 22, "count": 5}]},
				{"wave": 5, "enemies": [{"id": "enemy_boss_wuming", "name": "无名修士", "level": 25, "count": 1}]}
			]
		},
		{
			"id": "dungeon_luanhai",
			"name": "乱星海",
			"novel_source": "凡人修仙传",
			"dungeon_type": DungeonType.DAILY,
			"description": "妖兽横行的海域，资源丰富但危险",
			"level_requirement": 40,
			"recommended_power": 5000,
			"stamina_cost": 30,
			"waves_count": 4,
			"chapter_id": "ch_hanli_2",
			"boss_wave": 4,
			"rewards": {
				"spirit_stones": 800,
				"exp": 3000,
				"items": ["item_feijian"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_ha藻", "name": "海藻妖", "level": 35, "count": 4}]},
				{"wave": 2, "enemies": [{"id": "enemy_wugui", "name": "乌龟兽", "level": 38, "count": 3}]},
				{"wave": 3, "enemies": [{"id": "enemy_jianshou", "name": "尖手兽", "level": 42, "count": 4}]},
				{"wave": 4, "enemies": [{"id": "enemy_boss_xuanming", "name": "玄冥妖", "level": 50, "count": 1}]}
			]
		},
		{
			"id": "dungeon_zhuimo",
			"name": "坠魔殿",
			"novel_source": "凡人修仙传",
			"dungeon_type": DungeonType.STORY,
			"description": "上古修士的遗迹，藏有上古功法",
			"level_requirement": 60,
			"recommended_power": 10000,
			"stamina_cost": 40,
			"waves_count": 5,
			"chapter_id": "ch_hanli_3",
			"boss_wave": 5,
			"rewards": {
				"spirit_stones": 2000,
				"exp": 8000,
				"items": ["technique_huanjie"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_mogui", "name": "魔鬼", "level": 55, "count": 3}]},
				{"wave": 2, "enemies": [{"id": "enemy_moni", "name": "魔尼", "level": 58, "count": 4}]},
				{"wave": 3, "enemies": [{"id": "enemy_mojian", "name": "魔剑", "level": 62, "count": 3}]},
				{"wave": 4, "enemies": [{"id": "enemy_mowang", "name": "魔王", "level": 65, "count": 2}]},
				{"wave": 5, "enemies": [{"id": "enemy_boss_zhuimo", "name": "坠魔残念", "level": 70, "count": 1}]}
			]
		},
		# ===== 星辰变系列 =====
		{
			"id": "dungeon_qin Palace",
			"name": "秦王宫",
			"novel_source": "星辰变",
			"dungeon_type": DungeonType.STORY,
			"description": "秦王朝的皇宫，机关重重",
			"level_requirement": 15,
			"recommended_power": 1500,
			"stamina_cost": 15,
			"waves_count": 4,
			"chapter_id": "ch_qinyu_1",
			"boss_wave": 4,
			"rewards": {
				"spirit_stones": 300,
				"exp": 1500,
				"items": ["item_jinshi"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_wushi", "name": "武士", "level": 12, "count": 4}]},
				{"wave": 2, "enemies": [{"id": "enemy_shijian", "name": "侍剑", "level": 14, "count": 3}]},
				{"wave": 3, "enemies": [{"id": "enemy_shouwang", "name": "守将", "level": 16, "count": 2}]},
				{"wave": 4, "enemies": [{"id": "enemy_boss_qinwang", "name": "秦王", "level": 20, "count": 1}]}
			]
		},
		{
			"id": "dungeon_yuewu",
			"name": "月舞森林",
			"novel_source": "星辰变",
			"dungeon_type": DungeonType.DAILY,
			"description": "妖兽森林，资源丰富",
			"level_requirement": 25,
			"recommended_power": 3000,
			"stamina_cost": 25,
			"waves_count": 3,
			"chapter_id": "ch_qinyu_2",
			"boss_wave": 3,
			"rewards": {
				"spirit_stones": 400,
				"exp": 2000,
				"items": ["item_beast_core"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_lang", "name": "狼妖", "level": 22, "count": 5}]},
				{"wave": 2, "enemies": [{"id": "enemy_xiong", "name": "熊妖", "level": 25, "count": 3}]},
				{"wave": 3, "enemies": [{"id": "enemy_boss_hulv", "name": "狐狼王", "level": 30, "count": 1}]}
			]
		},
		# ===== 诛仙系列 =====
		{
			"id": "dungeon_CiYan",
			"name": "慈云寺",
			"novel_source": "诛仙",
			"dungeon_type": DungeonType.STORY,
			"description": "佛门圣地，暗藏危机",
			"level_requirement": 30,
			"recommended_power": 3500,
			"stamina_cost": 25,
			"waves_count": 4,
			"chapter_id": "ch_zhuxian_1",
			"boss_wave": 4,
			"rewards": {
				"spirit_stones": 600,
				"exp": 2500,
				"items": ["item_zhuyun"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_nigu", "name": "泥古怪", "level": 25, "count": 4}]},
				{"wave": 2, "enemies": [{"id": "enemy_luanshi", "name": "乱石妖", "level": 28, "count": 3}]},
				{"wave": 3, "enemies": [{"id": "enemy_sinian", "name": "死念", "level": 32, "count": 2}]},
				{"wave": 4, "enemies": [{"id": "enemy_boss_ciyan", "name": "慈云主持", "level": 35, "count": 1}]}
			]
		},
		{
			"id": "dungeon_stone",
			"name": "焚香谷",
			"novel_source": "诛仙",
			"dungeon_type": DungeonType.STORY,
			"description": "以火焰闻名，炼器圣地",
			"level_requirement": 50,
			"recommended_power": 6000,
			"stamina_cost": 35,
			"waves_count": 4,
			"chapter_id": "ch_zhuxian_2",
			"boss_wave": 4,
			"rewards": {
				"spirit_stones": 1000,
				"exp": 4000,
				"items": ["technique_benlei"]
			},
			"wave_config": [
				{"wave": 1, "enemies": [{"id": "enemy_huozhou", "name": "火州兽", "level": 45, "count": 4}]},
				{"wave": 2, "enemies": [{"id": "enemy_wenba", "name": "文八", "level": 48, "count": 3}]},
				{"wave": 3, "enemies": [{"id": "enemy_wuwu", "name": "武五", "level": 52, "count": 2}]},
				{"wave": 4, "enemies": [{"id": "enemy_boss_fenxiang", "name": "焚香谷主", "level": 55, "count": 1}]}
			]
		}
	]

	for dungeon in default_dungeons:
		dungeons_data[dungeon["id"]] = dungeon


## 加载副本数据（从game_database.json）
func load_dungeons_from_db() -> void:
	var db = DataManager.get_data("dungeons")
	if db and db is Dictionary:
		for dungeon_id in db:
			dungeons_data[dungeon_id] = db[dungeon_id]


func get_dungeon(dungeon_id: String) -> DungeonData:
	if dungeons_data.has(dungeon_id):
		return _create_dungeon_data(dungeons_data[dungeon_id])
	return null


func get_all_dungeons() -> Array:
	var result: Array = []
	for did in dungeons_data:
		result.append(_create_dungeon_data(dungeons_data[did]))
	return result


func get_dungeons_by_type(dungeon_type: DungeonType) -> Array:
	var result: Array = []
	for dungeon in dungeons_data.values():
		if dungeon.get("dungeon_type", DungeonType.STORY) == dungeon_type:
			result.append(_create_dungeon_data(dungeon))
	return result


func get_dungeons_by_novel(novel_name: String) -> Array:
	var result: Array = []
	for dungeon in dungeons_data.values():
		if dungeon.get("novel_source", "") == novel_name:
			result.append(_create_dungeon_data(dungeon))
	return result


func get_dungeons_by_chapter(chapter_id: String) -> Array:
	var result: Array = []
	for dungeon in dungeons_data.values():
		if dungeon.get("chapter_id", "") == chapter_id:
			result.append(_create_dungeon_data(dungeon))
	return result


func _create_dungeon_data(data: Dictionary) -> DungeonData:
	var dd = DungeonData.new()
	dd.id = data.get("id", "")
	dd.name = data.get("name", "")
	dd.novel_source = data.get("novel_source", "")
	dd.dungeon_type = data.get("dungeon_type", DungeonType.STORY)
	dd.description = data.get("description", "")
	dd.level_requirement = data.get("level_requirement", 1)
	dd.recommended_power = data.get("recommended_power", 0)
	dd.stamina_cost = data.get("stamina_cost", 10)
	dd.waves_count = data.get("waves_count", 3)
	dd.chapter_id = data.get("chapter_id", "")
	dd.boss_wave = data.get("boss_wave", dd.waves_count)
	dd.rewards = data.get("rewards", {})
	dd.wave_config = data.get("wave_config", [])
	return dd


## 开始副本
func start_dungeon(dungeon_id: String) -> Dictionary:
	var dungeon = get_dungeon(dungeon_id)
	if not dungeon:
		return {"success": false, "reason": "副本不存在"}

	# 检查体力
	if not _check_stamina(dungeon.stamina_cost):
		return {"success": false, "reason": "体力不足"}

	# 消耗体力
	_consume_stamina(dungeon.stamina_cost)

	current_dungeon = dungeon
	current_wave = 0
	dungeon_start_time = Time.get_ticks_msec() / 1000

	dungeon_started.emit(dungeon_id, current_wave)
	_start_next_wave()

	return {"success": true, "dungeon": dungeon}


func _start_next_wave() -> void:
	current_wave += 1

	if current_wave > current_dungeon.waves_count:
		_complete_dungeon()
		return

	var wave_enemies = _get_wave_enemies(current_wave)
	wave_started.emit(current_wave, wave_enemies.size())

	# 调用战斗系统
	_start_wave_combat(wave_enemies)


func _get_wave_enemies(wave_num: int) -> Array[Dictionary]:
	var wave_config = current_dungeon.wave_config
	for config in wave_config:
		if config.get("wave", 0) == wave_num:
			return config.get("enemies", [])
	return []


func _start_wave_combat(enemies: Array[Dictionary]) -> void:
	# 构建敌人列表（用于战斗系统）
	var enemy_team: Array = []
	for enemy in enemies:
		var count = enemy.get("count", 1)
		for i in range(count):
			var enemy_char = _create_enemy_character(enemy)
			enemy_team.append(enemy_char)

	# TODO: 调用combat_system进行战斗
	# CombatSystem.start_combat(player_team, enemy_team)


func _create_enemy_character(enemy: Dictionary) -> Dictionary:
	# 创建敌方角色（Dictionary格式，与主游戏一致）
	var level = enemy.get("level", 1)
	var ch := {
		"id": "enemy_%s_%d" % [enemy.get("id", "unknown"), randi()],
		"name": enemy.get("name", "敌人"),
		"level": level,
		"family_id": "",
		"realm_id": "mortal",
		"realm_exp": 0,
		"is_alive": true,
		"base_stats": {
			"max_hp": level * 50,
			"attack": level * 5,
			"defense": level * 3,
			"spirit": level * 3,
			"speed": level * 3,
			"luck": 0
		},
		"derived_stats": {
			"max_hp": level * 50,
			"attack": level * 5,
			"defense": level * 3,
			"spirit": level * 3,
			"speed": level * 3,
			"luck": 0
		},
		"hp": level * 50,
		"mp": level * 3 * 5,
		"status_effects": [],
		"cooldowns": {},
		"techniques": [],
		"items": [],
	}
	return ch


## 波次完成
func on_wave_completed() -> void:
	var wave_reward = _calculate_wave_reward(current_wave)
	wave_completed.emit(current_wave, wave_reward)
	_give_wave_reward(wave_reward)

	# 检查是否还有下一波
	if current_wave < current_dungeon.waves_count:
		_start_next_wave()
	else:
		_complete_dungeon()


## 副本完成
func _complete_dungeon() -> void:
	if not current_dungeon:
		return

	var time_taken = (Time.get_ticks_msec() / 1000) - dungeon_start_time
	var rewards = _calculate_dungeon_rewards(time_taken)

	_give_rewards(rewards)

	# 更新进度
	_update_progress(current_dungeon.id, time_taken)

	dungeon_completed.emit(current_dungeon.id, rewards)

	# 重置状态
	current_dungeon = null
	current_wave = 0


func _update_progress(dungeon_id: String, time_taken: int) -> void:
	var progress = player_progress.get(dungeon_id, DungeonProgress.new())
	progress.dungeon_id = dungeon_id
	progress.completed_times += 1

	if progress.best_time == 0 or time_taken < progress.best_time:
		progress.best_time = time_taken

	progress.last_completed_date = GameManager.get_formatted_time()
	player_progress[dungeon_id] = progress

	_save_to_game_db()


## 副本失败
func on_dungeon_failed() -> void:
	if current_dungeon:
		dungeon_failed.emit(current_dungeon.id, current_wave)
	current_dungeon = null
	current_wave = 0


## 计算奖励
func _calculate_wave_reward(wave_num: int) -> Dictionary:
	var base = 20 * wave_num
	return {
		"spirit_stones": base,
		"exp": base * 5
	}


func _calculate_dungeon_rewards(time_taken: int) -> Dictionary:
	var base_rewards = current_dungeon.rewards.duplicate()

	# 速度加成：时间越短奖励越高
	var time_bonus = maxf(1.0 - time_taken / 600.0, 0.5)  # 最少50%

	base_rewards["spirit_stones"] = int(base_rewards.get("spirit_stones", 0) * time_bonus)
	base_rewards["exp"] = int(base_rewards.get("exp", 0) * time_bonus)

	return base_rewards


func _give_wave_reward(reward: Dictionary) -> void:
	var player = _get_current_player()
	if player:
		player["realm_exp"] = player.get("realm_exp", 0) + reward.get("exp", 0)
		if reward.get("spirit_stones", 0) > 0:
			var lingshi_item = _create_lingshi_item(reward.get("spirit_stones", 0))
			if not player.has("items"):
				player["items"] = []
			player["items"].append(lingshi_item)


func _give_rewards(rewards: Dictionary) -> void:
	var player = _get_current_player()
	if player:
		player["realm_exp"] = player.get("realm_exp", 0) + rewards.get("exp", 0)
		var stones = rewards.get("spirit_stones", 0)
		if stones > 0:
			var lingshi = _create_lingshi_item(stones)
			if not player.has("items"):
				player["items"] = []
			player["items"].append(lingshi)
		var items = rewards.get("items", [])
		for item_id in items:
			var item = _create_item(item_id)
			if item:
				player.add_item(item)


func _create_lingshi_item(amount: int):
	var item = ItemInstance.new()
	item.item_id = "item_lingshi"
	item.count = amount
	item.display_name = "灵石"
	return item


func _create_item(item_id: String):
	var item_data = DataManager.get_item(item_id)
	if item_data.is_empty():
		return null

	var item = ItemInstance.new()
	item.item_id = item_id
	item.count = 1
	item.display_name = item_data.get("name", "未知物品")
	return item


func _process(delta: float) -> void:
	# 体力回复
	if current_stamina < max_stamina:
		stamina_timer += delta
		if stamina_timer >= STAMINA_REGEN_INTERVAL:
			stamina_timer = 0.0
			current_stamina = mini(current_stamina + 1, max_stamina)
			stamina_changed.emit(current_stamina, max_stamina)


func _check_stamina(cost: int) -> bool:
	return current_stamina >= cost


func _consume_stamina(cost: int) -> void:
	current_stamina = maxi(current_stamina - cost, 0)
	stamina_changed.emit(current_stamina, max_stamina)


func set_max_stamina(value: int) -> void:
	max_stamina = value
	current_stamina = mini(current_stamina, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)


func add_stamina_potion(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)


## 工具函数
func _get_current_player() -> Variant:
	var family = GameManager.get_player_family()
	if family.is_empty():
		return null
	var members = GameManager.get_family_characters(family.get("id", ""))
	if members.is_empty():
		return null
	for m in members:
		if m.get("is_alive", false):
			return m
	return null


## 获取副本进度
func get_dungeon_progress(dungeon_id: String) -> DungeonProgress:
	if player_progress.has(dungeon_id):
		return player_progress[dungeon_id]
	var prog = DungeonProgress.new()
	prog.dungeon_id = dungeon_id
	return prog


func is_dungeon_completed(dungeon_id: String) -> bool:
	return player_progress.has(dungeon_id) and player_progress[dungeon_id].is_completed


## 获取当前体力
func get_current_stamina() -> int:
	return current_stamina


func get_max_stamina() -> int:
	return max_stamina


## 保存/加载
func _save_to_game_db() -> void:
	var save_data = {
		"player_progress": {},
		"current_stamina": current_stamina,
		"max_stamina": max_stamina
	}

	for pid in player_progress:
		var prog = player_progress[pid]
		save_data["player_progress"][pid] = {
			"dungeon_id": prog.dungeon_id,
			"is_completed": prog.is_completed,
			"completed_times": prog.completed_times,
			"best_time": prog.best_time,
			"last_completed_date": prog.last_completed_date
		}

	SaveManager.set_data("dungeons", save_data)


func load_from_save(data: Dictionary) -> void:
	player_progress.clear()

	current_stamina = data.get("current_stamina", 100)
	max_stamina = data.get("max_stamina", 100)

	var progress_data = data.get("player_progress", {})
	for pid in progress_data:
		var prog = DungeonProgress.new()
		var pdata = progress_data[pid]
		prog.dungeon_id = pdata.get("dungeon_id", pid)
		prog.is_completed = pdata.get("is_completed", false)
		prog.completed_times = pdata.get("completed_times", 0)
		prog.best_time = pdata.get("best_time", 0)
		prog.last_completed_date = pdata.get("last_completed_date", "")
		player_progress[pid] = prog


## 获取副本类型名称
func get_dungeon_type_name(dtype: DungeonType) -> String:
	match dtype:
		DungeonType.STORY: return "剧情副本"
		DungeonType.DAILY: return "日常副本"
		DungeonType.CHALLENGE: return "挑战副本"
		_: return "未知"


## 获取副本难度名称
func get_difficulty_name(diff: DungeonDifficulty) -> String:
	match diff:
		DungeonDifficulty.EASY: return "简单"
		DungeonDifficulty.NORMAL: return "普通"
		DungeonDifficulty.HARD: return "困难"
		DungeonDifficulty.EXPERT: return "专家"
		DungeonDifficulty.HELL: return "地狱"
		_: return "未知"