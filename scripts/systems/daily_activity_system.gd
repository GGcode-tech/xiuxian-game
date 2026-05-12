extends Node
## 日常活动系统 - 宗门任务、灵兽岛、竞技场、体力系统、活跃度

## 活动数据类
class ActivityData extends RefCounted:
	var id: String
	var name: String
	var description: String
	var activity_type: ActivityType
	var open_days: Array[int]  # 开放日期 [1,2,3,4,5,6,7]表示周一到周日都开放
	var open_time_start: int = 0  # 开放时间（小时），0表示整天
	var open_time_end: int = 24
	var level_requirement: int = 1
	var stamina_cost: int = 0
	var max_daily_count: int = 1  # 每日最大参与次数

	var rewards: Dictionary = {}  # 奖励配置
	var difficulty: int = 1       # 难度等级

	var requirements: Dictionary = {}  # 参与条件


## 活动实例（玩家参与记录）
class ActivityInstance extends RefCounted:
	var activity_id: String
	var today_count: int = 0      # 今日参与次数
	var last_reset_date: String = ""  # 上次重置日期
	var cooldown_until: int = 0   # 冷却截止时间戳


## 活跃度奖励
class VitalityReward extends RefCounted:
	var required_points: int
	var reward_items: Dictionary  # {item_id: count}
	var is_claimed: bool = false


## 信号
signal activity_started(activity_id: String)
signal activity_completed(activity_id: String, rewards: Dictionary)
signal activity_failed(activity_id: String, reason: String)
signal activity_claimed(activity_id: String)
signal vitality_changed(current: int, target: int)
signal vitality_reward_claimed(reward_index: int)
signal daily_reset()
signal stamina_changed(current: int, max_value: int)


## 活动类型
enum ActivityType {
	SECT_QUEST,    # 宗门任务
	SPIRIT_ISLAND, # 灵兽岛
	ARENA,         # 竞技场
	EXAM,          # 灵根测试（答题）
	ESCORT,        # 物资运输
	PRACTICE,      # 修炼副本
	TREASURE,      # 寻宝
}

## 活动状态
enum ActivityStatus {
	LOCKED,      # 未解锁
	AVAILABLE,   # 可参与
	IN_PROGRESS, # 进行中
	COMPLETED,   # 已完成
	COOLDOWN,    # 冷却中
}

## 常量
const STAMINA_REGEN_INTERVAL: float = 300.0  # 每5分钟回复1点体力

## 活动配置
var activities_data: Dictionary = {}
var vitality_rewards: Array[VitalityReward] = []
var daily_vitality: int = 0
var weekly_vitality: int = 0
var claimed_daily_rewards: Array[int] = []
var claimed_weekly_rewards: Array[int] = []
var player_activities: Dictionary = {}  # activity_id -> ActivityInstance
var exam_questions: Array[Dictionary] = [
	{"question": "炼气期共有几层？", "answers": ["9层", "13层", "7层", "12层"], "correct": 1},
	{"question": "筑基期需要什么丹药辅助？", "answers": ["筑基丹", "结丹期", "化神丹", "元婴丹"], "correct": 0},
	{"question": "灵根分为几种属性？", "answers": ["3种", "4种", "5种", "6种"], "correct": 2},
	{"question": "以下哪个是最高境界？", "answers": ["大乘期", "渡劫期", "飞升期", "真仙境"], "correct": 3},
]

var current_stamina: int = 100
var max_stamina: int = 100
var stamina_timer: float = 0.0


var _handler: RefCounted = preload("daily_activity_handler.gd").new()


func _init() -> void:
	_handler.init(self)
	_init_default_activities()


func _init_default_activities() -> void:
	var default_activities: Array = [
		{
			"id": "activity_sect_quest",
			"name": "宗门任务",
			"description": "完成宗门委托，获取贡献度和灵石",
			"activity_type": ActivityType.SECT_QUEST,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 10,
			"stamina_cost": 10,
			"max_daily_count": 10,
			"rewards": {
				"contribution": 20,
				"spirit_stones": 50
			},
			"difficulty": 1
		},
		{
			"id": "activity_spirit_island",
			"name": "灵兽岛",
			"description": "捕捉野生灵兽，有机会获得稀有灵兽",
			"activity_type": ActivityType.SPIRIT_ISLAND,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 15,
			"stamina_cost": 20,
			"max_daily_count": 1,
			"rewards": {
				"beast_catch_chance": 0.3,
				"spirit_stones": 100,
				"exp": 200
			},
			"difficulty": 2
		},
		{
			"id": "activity_arena",
			"name": "天梯竞技",
			"description": "与其他玩家切磋，提升排名获取丰厚奖励",
			"activity_type": ActivityType.ARENA,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 25,
			"stamina_cost": 15,
			"max_daily_count": 5,
			"rewards": {
				"arena_points": 10,
				"spirit_stones": 80
			},
			"difficulty": 3
		},
		{
			"id": "activity_exam",
			"name": "灵根测试",
			"description": "回答修仙知识问题，测试灵根资质",
			"activity_type": ActivityType.EXAM,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 5,
			"stamina_cost": 5,
			"max_daily_count": 3,
			"rewards": {
				"exp": 100,
				"spirit_stones": 30
			},
			"difficulty": 1
		},
		{
			"id": "activity_escort",
			"name": "物资运输",
			"description": "护送物资到指定地点，可能遭遇劫匪",
			"activity_type": ActivityType.ESCORT,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 6,
			"open_time_end": 22,
			"level_requirement": 20,
			"stamina_cost": 25,
			"max_daily_count": 3,
			"rewards": {
				"spirit_stones": 200,
				"exp": 300
			},
			"difficulty": 2
		},
		{
			"id": "activity_practice",
			"name": "修炼副本",
			"description": "进入虚拟修炼空间，磨砺实战能力",
			"activity_type": ActivityType.PRACTICE,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 30,
			"stamina_cost": 30,
			"max_daily_count": 2,
			"rewards": {
				"exp": 500,
				"technique_exp": 50
			},
			"difficulty": 3
		},
		{
			"id": "activity_treasure",
			"name": "探索寻宝",
			"description": "探索随机地点，可能发现稀有宝物",
			"activity_type": ActivityType.TREASURE,
			"open_days": [1,2,3,4,5,6,7],
			"open_time_start": 0,
			"open_time_end": 24,
			"level_requirement": 35,
			"stamina_cost": 35,
			"max_daily_count": 1,
			"rewards": {
				"spirit_stones": 300,
				"rare_item_chance": 0.15
			},
			"difficulty": 4
		}
	]

	for activity in default_activities:
		activities_data[activity["id"]] = activity

	# 初始化活跃度奖励
	_init_vitality_rewards()


func _init_vitality_rewards() -> void:
	vitality_rewards = [
		_create_vitality_reward(30, {"spirit_stones": 50}),
		_create_vitality_reward(60, {"spirit_stones": 100, "item_xuanwu": 1}),
		_create_vitality_reward(100, {"spirit_stones": 200, "exp": 500}),
		_create_vitality_reward(150, {"spirit_stones": 300, "item_jiuxuan": 1}),
		_create_vitality_reward(200, {"spirit_stones": 500, "rare_item": 1})
	]


func _create_vitality_reward(points: int, items: Dictionary) -> VitalityReward:
	var reward = VitalityReward.new()
	reward.required_points = points
	reward.reward_items = items
	reward.is_claimed = false
	return reward


## 获取活动配置
func get_activity(activity_id: String) -> ActivityData:
	if activities_data.has(activity_id):
		return _create_activity_data(activities_data[activity_id])
	return null


func get_all_activities() -> Array:
	var result: Array = []
	for aid in activities_data:
		result.append(_create_activity_data(activities_data[aid]))
	return result


func get_activities_by_type(activity_type: ActivityType) -> Array:
	var result: Array = []
	for activity in activities_data.values():
		if activity.get("activity_type", ActivityType.SECT_QUEST) == activity_type:
			result.append(_create_activity_data(activity))
	return result


func get_available_activities() -> Array:
	var result: Array = []
	var current_time = Time.get_datetime_dict_from_system()
	var current_day = current_time.get("weekday", 1)  # 1=周一
	var current_hour = current_time.get("hour", 12)

	for activity in activities_data.values():
		var act_data = _create_activity_data(activity)

		# 检查日期
		if not current_day in act_data.open_days:
			continue

		# 检查时间
		if current_hour < act_data.open_time_start or current_hour >= act_data.open_time_end:
			continue

		# 检查等级
		var player = _get_current_player()
		if player and player.get_realm_tier() * 10 < act_data.level_requirement:
			continue

		result.append(act_data)

	return result


func _create_activity_data(data: Dictionary) -> ActivityData:
	var ad = ActivityData.new()
	ad.id = data.get("id", "")
	ad.name = data.get("name", "")
	ad.description = data.get("description", "")
	ad.activity_type = data.get("activity_type", ActivityType.SECT_QUEST)
	ad.open_days = data.get("open_days", [1,2,3,4,5,6,7])
	ad.open_time_start = data.get("open_time_start", 0)
	ad.open_time_end = data.get("open_time_end", 24)
	ad.level_requirement = data.get("level_requirement", 1)
	ad.stamina_cost = data.get("stamina_cost", 0)
	ad.max_daily_count = data.get("max_daily_count", 1)
	ad.rewards = data.get("rewards", {})
	ad.difficulty = data.get("difficulty", 1)
	ad.requirements = data.get("requirements", {})
	return ad


func get_activity_instance(activity_id: String) -> ActivityInstance:
	return player_activities.get(activity_id, null)


func _get_or_create_instance(activity_id: String) -> ActivityInstance:
	if not player_activities.has(activity_id):
		var inst = ActivityInstance.new()
		inst.activity_id = activity_id
		player_activities[activity_id] = inst
	return player_activities[activity_id]


## 参与活动
func start_activity(activity_id: String) -> Dictionary:
	var activity = get_activity(activity_id)
	var error_reason = ""
	var instance: ActivityInstance = null

	if not activity:
		error_reason = "活动不存在"
	else:
		# 检查开放时间
		var current_time = Time.get_datetime_dict_from_system()
		var current_day = current_time.get("weekday", 1)
		if not current_day in activity.open_days:
			error_reason = "今日未开放"
		else:
			var current_hour = current_time.get("hour", 12)
			if current_hour < activity.open_time_start or current_hour >= activity.open_time_end:
				error_reason = "活动未在开放时间内"
			else:
				# 检查等级
				var player = _get_current_player()
				if not player:
					error_reason = "玩家不存在"
				elif player.get_realm_tier() * 10 < activity.level_requirement:
					error_reason = "等级不足"
				else:
					# 检查次数限制
					instance = _get_or_create_instance(activity_id)
					_check_daily_reset(instance)

					if instance.today_count >= activity.max_daily_count:
						error_reason = "今日参与次数已用完"
					elif instance.cooldown_until > Time.get_unix_time_from_datetime_dict(current_time):
						error_reason = "活动冷却中"
					elif not _check_stamina(activity.stamina_cost):
						error_reason = "体力不足"

	if error_reason:
		return {"success": false, "reason": error_reason}

	# 消耗体力
	_consume_stamina(activity.stamina_cost)

	# 增加参与次数
	instance.today_count += 1

	activity_started.emit(activity_id)
	_save_to_game_db()

	return {"success": true, "activity": activity}


## 完成活动
func complete_activity(activity_id: String,
		success: bool = true,
		bonus_multiplier: float = 1.0) -> void:
	var activity = get_activity(activity_id)
	if not activity:
		return

	var rewards = {}

	if success:
		rewards = _calculate_rewards(activity, bonus_multiplier)
		_give_rewards(rewards)
		activity_completed.emit(activity_id, rewards)

		# 增加活跃度
		_add_vitality(activity.difficulty * 10)
	else:
		activity_failed.emit(activity_id, "活动失败")

	_save_to_game_db()


func _calculate_rewards(activity: ActivityData, multiplier: float) -> Dictionary:
	var base_rewards = activity.rewards.duplicate()

	# 应用难度加成
	var difficulty_bonus = 1.0 + activity.difficulty * 0.2
	var final_multiplier = multiplier * difficulty_bonus

	for key in base_rewards:
		if key != "beast_catch_chance" and key != "rare_item_chance":
			if base_rewards[key] is int or base_rewards[key] is float:
				base_rewards[key] = int(base_rewards[key] * final_multiplier)

	return base_rewards


func _give_rewards(rewards: Dictionary) -> void:
	var player = _get_current_player()
	if not player:
		return

	# 灵石
	if rewards.has("spirit_stones"):
		var lingshi = _create_lingshi_item(rewards.get("spirit_stones", 0))
		player.add_item(lingshi)

	# 经验
	if rewards.has("exp"):
		player.add_exp(rewards.get("exp", 0))

	# 贡献度（需要门派系统）
	if rewards.has("contribution"):
		SectSystem.add_contribution(rewards.get("contribution", 0))

	# 竞技场积分
	if rewards.has("arena_points"):
		# 需要竞技场系统支持
		pass

	# 物品掉落
	if rewards.has("items"):
		for item_id in rewards.get("items", []):
			var item = _create_item(item_id)
			if item:
				player.add_item(item)


func _check_daily_reset(instance: ActivityInstance) -> void:
	var today = GameManager.get_formatted_time().substr(0, 10)  # YYYY-MM-DD
	if instance.last_reset_date != today:
		instance.today_count = 0
		instance.last_reset_date = today


## 灵兽岛 - 捕捉灵兽
func capture_at_spirit_island() -> Dictionary:
	return _handler.capture_at_spirit_island()


## 竞技场挑战
func challenge_arena(_opponent_id: String) -> Dictionary:
	return _handler.challenge_arena(_opponent_id)


func start_exam() -> Dictionary:
	return _handler.start_exam()


func submit_exam_answer(question_index: int, answer_index: int) -> Dictionary:
	return _handler.submit_exam_answer(question_index, answer_index)


## 活跃度系统
func _add_vitality(amount: int) -> void:
	daily_vitality += amount
	weekly_vitality += amount
	vitality_changed.emit(daily_vitality, _get_daily_vitality_target())


func _get_daily_vitality_target() -> int:
	return 200  # 每日活跃度目标


func get_vitality_reward_status() -> Array[Dictionary]:
	var result: Array = []
	for i in range(vitality_rewards.size()):
		var reward = vitality_rewards[i]
		result.append({
			"index": i,
			"required": reward.required_points,
			"current": daily_vitality,
			"claimed": i in claimed_daily_rewards,
			"can_claim": daily_vitality >= reward.required_points and not (i in claimed_daily_rewards)
		})
	return result


func claim_vitality_reward(index: int) -> bool:
	if index < 0 or index >= vitality_rewards.size():
		return false

	if index in claimed_daily_rewards:
		return false

	var reward = vitality_rewards[index]
	if daily_vitality < reward.required_points:
		return false

	claimed_daily_rewards.append(index)
	_give_rewards(reward.reward_items)
	vitality_reward_claimed.emit(index)
	_save_to_game_db()
	return true


func _process(delta: float) -> void:
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


func add_stamina(amount: int) -> void:
	current_stamina = mini(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)


func get_current_stamina() -> int:
	return current_stamina


func get_max_stamina() -> int:
	return max_stamina


## 每日重置
func do_daily_reset() -> void:
	daily_vitality = 0
	claimed_daily_rewards.clear()

	# 重置所有活动次数
	for activity_id in player_activities:
		var inst = player_activities[activity_id]
		inst.today_count = 0

	daily_reset.emit()
	_save_to_game_db()


## 每周重置
func _weekly_reset() -> void:
	weekly_vitality = 0
	claimed_weekly_rewards.clear()
	_save_to_game_db()


## 工具函数
func _get_current_player() -> Character:
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


## 获取活动类型名称
func _get_activity_type_name(atype: ActivityType) -> String:
	var names = {
		ActivityType.SECT_QUEST: "宗门任务",
		ActivityType.SPIRIT_ISLAND: "灵兽岛",
		ActivityType.ARENA: "天梯竞技",
		ActivityType.EXAM: "灵根测试",
		ActivityType.ESCORT: "物资运输",
		ActivityType.PRACTICE: "修炼副本",
		ActivityType.TREASURE: "探索寻宝",
	}
	return names.get(atype, "未知")


## 获取活动状态
func _get_activity_status(activity_id: String) -> ActivityStatus:
	var activity = get_activity(activity_id)
	if not activity:
		return ActivityStatus.LOCKED

	var instance = _get_or_create_instance(activity_id)
	_check_daily_reset(instance)

	if instance.today_count >= activity.max_daily_count:
		return ActivityStatus.COMPLETED

	# 检查冷却
	var current_time = Time.get_datetime_dict_from_system()
	if instance.cooldown_until > Time.get_unix_time_from_datetime_dict(current_time):
		return ActivityStatus.COOLDOWN

	# 检查等级
	var player = _get_current_player()
	if player and player.get_realm_tier() * 10 < activity.level_requirement:
		return ActivityStatus.LOCKED

	# 检查体力
	if not _check_stamina(activity.stamina_cost):
		return ActivityStatus.COOLDOWN

	return ActivityStatus.AVAILABLE


## 保存/加载
func _save_to_game_db() -> void:
	var save_data = {
		"player_activities": {},
		"daily_vitality": daily_vitality,
		"weekly_vitality": weekly_vitality,
		"claimed_daily_rewards": claimed_daily_rewards,
		"claimed_weekly_rewards": claimed_weekly_rewards,
		"current_stamina": current_stamina,
		"max_stamina": max_stamina
	}

	for aid in player_activities:
		var inst = player_activities[aid]
		save_data["player_activities"][aid] = {
			"activity_id": inst.activity_id,
			"today_count": inst.today_count,
			"last_reset_date": inst.last_reset_date,
			"cooldown_until": inst.cooldown_until
		}

	SaveManager.set_data("daily_activities", save_data)


func load_from_save(data: Dictionary) -> void:
	player_activities.clear()

	daily_vitality = data.get("daily_vitality", 0)
	weekly_vitality = data.get("weekly_vitality", 0)
	claimed_daily_rewards = Array(data.get("claimed_daily_rewards", []))
	claimed_weekly_rewards = Array(data.get("claimed_weekly_rewards", []))
	current_stamina = data.get("current_stamina", 100)
	max_stamina = data.get("max_stamina", 100)

	var activities_data = data.get("player_activities", {})
	for aid in activities_data:
		var inst = ActivityInstance.new()
		var adata = activities_data[aid]
		inst.activity_id = adata.get("activity_id", aid)
		inst.today_count = adata.get("today_count", 0)
		inst.last_reset_date = adata.get("last_reset_date", "")
		inst.cooldown_until = adata.get("cooldown_until", 0)
		player_activities[aid] = inst


## 获取玩家活动统计
func get_activity_stats() -> Dictionary:
	return {
		"daily_vitality": daily_vitality,
		"daily_target": _get_daily_vitality_target(),
		"weekly_vitality": weekly_vitality,
		"completed_today": player_activities.values() \
			.filter(func(inst): return inst.today_count > 0) \
			.size(),
		"total_activities": activities_data.size()
	}
