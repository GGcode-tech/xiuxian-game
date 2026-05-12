## ActivityHandler - 具体活动实现（灵兽岛、竞技场、考试等）
## 从daily_activity_system.gd拆分出来
extends RefCounted


var _system: Node  # 持有DailyActivitySystem引用


func init(p_system: Node) -> void:
	_system = p_system


## 灵兽岛 - 捕捉灵兽
func capture_at_spirit_island() -> Dictionary:
	var result = _system.start_activity("activity_spirit_island")
	if not result.get("success", false):
		return result

	# 计算捕捉成功率
	var catch_chance = result.get("activity", {}).rewards.get("beast_catch_chance", 0.3)

	if randf() < catch_chance:
		# 成功捕捉 - 随机获取一个灵兽
		var beast_id = _get_random_wild_beast()
		_system.complete_activity("activity_spirit_island", true, 1.0)
		return {"success": true, "captured": true, "beast_id": beast_id}

	_system.complete_activity("activity_spirit_island", true, 0.5)
	return {"success": true, "captured": false}


func _get_random_wild_beast() -> String:
	var wild_beasts = [
		"beast_default",
		"beast_default",
		"beast_default",
		"beast_hanli",  # 稀有
	]
	return wild_beasts[randi() % wild_beasts.size()]


## 竞技场挑战
func challenge_arena(_opponent_id: String) -> Dictionary:
	var result = _system.start_activity("activity_arena")
	if not result.get("success", false):
		return result

	# 模拟战斗结果（实际应该调用战斗系统）
	var player_power = _calculate_player_power()
	var opponent_power = 1000 + randi() % 2000  # 模拟对手

	var victory = player_power > opponent_power

	if victory:
		_system.complete_activity("activity_arena", true, 1.5)
	else:
		_system.complete_activity("activity_arena", true, 0.3)

	return {
		"success": true,
		"victory": victory,
		"player_power": player_power,
		"opponent_power": opponent_power,
		"arena_points_change": 10 if victory else -5
	}


func _calculate_player_power() -> int:
	var player = _get_current_player()
	if not player:
		return 0

	var stats = player.base_stats
	return stats.get("attack", 10) * 2 + stats.get("max_hp", 100) + stats.get("defense", 5) * 3


func start_exam() -> Dictionary:
	var result = _system.start_activity("activity_exam")
	if not result.get("success", false):
		return result

	# 返回随机题目
	var question = _system.exam_questions[randi() % _system.exam_questions.size()]
	return {"success": true, "question": question}


func submit_exam_answer(question_index: int, answer_index: int) -> Dictionary:
	var question = _system.exam_questions[question_index]
	var correct = question.get("correct", 0) == answer_index

	if correct:
		_system.complete_activity("activity_exam", true, 1.5)
		return {"success": true, "correct": true, "reward": {"exp": 150, "spirit_stones": 50}}

	_system.complete_activity("activity_exam", true, 0.5)
	return {"success": true, "correct": false, "reward": {"exp": 50}}


func _get_current_player():
	return _system._get_current_player()
