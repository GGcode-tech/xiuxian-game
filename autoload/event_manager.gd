## 事件管理器 - 处理游戏内随机事件和事件分发
extends Node

signal event_triggered(event: Dictionary, context: Dictionary)
signal event_choice_made(event: Dictionary, choice: int, result: Dictionary)
signal notification_added(title: String, content: String, type: String)

var _active_events: Array[Dictionary] = []
var _event_queue: Array[Dictionary] = []
var max_active_events: int = 5
var notifications: Array[Dictionary] = []
var max_notifications: int = 100


func _ready() -> void:
	print("[EventManager] 初始化完成")


func process_daily_events() -> void:
	_check_character_events()
	_check_family_events()
	_check_world_events()


func process_monthly_events() -> void:
	_check_monthly_events()


func process_yearly_events() -> void:
	_check_yearly_events()


func _check_character_events() -> void:
	var all_events = DataManager.get_all_events()
	for event_data in all_events:
		if event_data.get("event_type", "") != "character":
			continue
		for char_id in GameManager.all_characters:
			var character = GameManager.all_characters[char_id]
			if character.get("is_alive", false):
				if _can_trigger_character_event(event_data, character):
					if randf() <= event_data.get("trigger_chance", 0.0):
						_trigger_event(event_data, {"character": character})
						break


func _check_family_events() -> void:
	var all_events = DataManager.get_all_events()
	for event_data in all_events:
		if event_data.get("event_type", "") != "family":
			continue
		for family_id in GameManager.all_families:
			var family = GameManager.all_families[family_id]
			if family:
				if _can_trigger_family_event(event_data, family):
					if randf() <= event_data.get("trigger_chance", 0.0):
						_trigger_event(event_data, {"family": family})
						break


func _check_world_events() -> void:
	var all_events = DataManager.get_all_events()
	for event_data in all_events:
		if event_data.get("event_type", "") != "world":
			continue
		if _can_trigger_world_event(event_data):
			if randf() <= event_data.get("trigger_chance", 0.0):
				_trigger_event(event_data, {"world": true})


func _check_monthly_events() -> void:
	pass


func _check_yearly_events() -> void:
	pass


func _can_trigger_character_event(event: Dictionary, character: Dictionary) -> bool:
	var triggers = event.get("triggers", {})
	var character_realm_id = character.get("realm_id", "")

	if triggers.get("min_realm", "") != "":
		var current_realm = DataManager.get_realm(character_realm_id)
		var min_realm = DataManager.get_realm(triggers.get("min_realm", ""))
		if current_realm and min_realm:
			if current_realm.get("tier", 0) < min_realm.get("tier", 0):
				return false

	if triggers.get("min_age", 0) > 0 and character.get("age", 0) < triggers.get("min_age", 0):
		return false

	if triggers.get("required_trait", "") != "":
		var traits: Array = character.get("traits", [])
		if not triggers.get("required_trait", "") in traits:
			return false

	if triggers.get("max_age", 0) > 0 and character.get("age", 0) > triggers.get("max_age", 0):
		return false

	return true


func _can_trigger_family_event(event: Dictionary, family: Dictionary) -> bool:
	var triggers = event.get("triggers", {})
	if triggers.get("min_family_level", 0) > 0 and family.get("level", 0) < triggers.get("min_family_level", 0):
		return false
	if triggers.get("min_members", 0) > 0 and family.get("members", []).size() < triggers.get("min_members", 0):
		return false
	return true


func _can_trigger_world_event(event: Dictionary) -> bool:
	var triggers = event.get("triggers", {})
	if triggers.get("min_year", 0) > 0 and GameManager.game_time.get("year", 1) < triggers.get("min_year", 0):
		return false
	return true


func _trigger_event(event: Dictionary, context: Dictionary) -> void:
	if _active_events.size() >= max_active_events:
		_event_queue.append({"event": event, "context": context})
		return

	_active_events.append({"event": event, "context": context})
	event_triggered.emit(event, context)
	add_notification(event.get("title", ""), event.get("description", ""), "event")
	print("[EventManager] 触发事件: %s" % event.get("title", ""))


func make_choice(event_index: int, choice_index: int) -> Dictionary:
	if event_index < 0 or event_index >= _active_events.size():
		return {"success": false, "reason": "无效的事件索引"}

	var event_data = _active_events[event_index].get("event", {})
	var context = _active_events[event_index].get("context", {})
	var choices: Array = event_data.get("choices", [])

	if choice_index < 0 or choice_index >= choices.size():
		return {"success": false, "reason": "无效的选择索引"}

	var choice: Dictionary = choices[choice_index]

	if not _check_choice_requirements(choice, context):
		return {"success": false, "reason": "不满足选择条件"}

	var result = _calculate_outcome(choice, context)
	_apply_outcome(result, context)
	_active_events.remove_at(event_index)
	_process_queue()
	event_choice_made.emit(event_data, choice_index, result)
	return {"success": true, "result": result}


func _check_choice_requirements(choice: Dictionary, context: Dictionary) -> bool:
	var requirements: Dictionary = choice.get("requirements", {})
	for key in requirements:
		var required = requirements[key]
		var character = context.get("character")
		match key:
			"min_realm":
				if character:
					var realm = DataManager.get_realm(character.get("realm_id", ""))
					if realm and realm.get("tier", 0) < required:
						return false
			"min_resources":
				pass
			"has_item":
				if character:
					var items: Array = character.get("items", [])
					if not required in items:
						return false
	return true


func _calculate_outcome(choice: Dictionary, context: Dictionary) -> Dictionary:
	var outcomes: Array = choice.get("outcomes", [])
	if outcomes.is_empty():
		return {"text": "什么也没发生。", "effects": []}

	var total_weight := 0.0
	for outcome in outcomes:
		total_weight += outcome.get("probability", 0.0)

	var roll = randf() * total_weight
	var cumulative := 0.0
	for outcome in outcomes:
		cumulative += outcome.get("probability", 0.0)
		if roll <= cumulative:
			return {"text": outcome.get("text", ""), "effects": outcome.get("effects", []).duplicate()}

	return {"text": outcomes[0].get("text", ""), "effects": outcomes[0].get("effects", []).duplicate()}


func _apply_outcome(result: Dictionary, context: Dictionary) -> void:
	var character: Dictionary = context.get("character", {})
	var family: Dictionary = context.get("family", {})

	for effect in result.get("effects", []):
		var effect_type = effect.get("type", "")
		var value = effect.get("value", 0)
		var id = effect.get("id", "")

		match effect_type:
			"add_exp":
				if character:
					var exp = character.get("realm_exp", 0) + value
					character["realm_exp"] = exp
			"add_resource":
				if family:
					var resources: Dictionary = family.get("resources", {})
					resources[id] = resources.get(id, 0) + value
					family["resources"] = resources
			"add_item":
				if character:
					var items: Array = character.get("items", [])
					items.append(id)
					character["items"] = items
			"learn_technique":
				if character:
					FamilySystem.learn_technique(character, id)
			"modify_trait":
				if character:
					var traits: Array = character.get("traits", [])
					if not id in traits:
						traits.append(id)
						character["traits"] = traits
			"damage":
				if character:
					var hp = character.get("hp", 0) - value
					character["hp"] = maxi(0, hp)
					if hp <= 0:
						character["is_alive"] = false
			"heal":
				if character:
					var hp = character.get("hp", 0)
					var max_hp = character.get("base_stats", {}).get("max_hp", 100)
					character["hp"] = mini(max_hp, hp + value)
			"breakthrough_boost":
				if character:
					var boost = character.get("breakthrough_boost", 0.0) + value
					character["breakthrough_boost"] = boost


func _process_queue() -> void:
	if not _event_queue.is_empty() and _active_events.size() < max_active_events:
		var next: Dictionary = _event_queue.pop_front()
		_active_events.append(next)
		event_triggered.emit(next.get("event", {}), next.get("context", {}))


func add_notification(title: String, content: String, type: String = "info") -> void:
	var notification: Dictionary = {
		"title": title,
		"content": content,
		"type": type,
		"timestamp": GameManager.get_total_days(),
		"time_text": GameManager.get_formatted_time()
	}
	notifications.append(notification)
	if notifications.size() > max_notifications:
		notifications.pop_front()
	notification_added.emit(title, content, type)


func get_notifications(count: int = 10) -> Array:
	var start = maxi(0, notifications.size() - count)
	return notifications.slice(start)


func clear_notifications() -> void:
	notifications.clear()


func get_active_events() -> Array[Dictionary]:
	return _active_events


func get_event_count() -> int:
	return _active_events.size()
