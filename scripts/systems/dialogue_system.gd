## 对话系统 - 管理NPC对话逻辑、选项效果
extends Node

# 选项配置
const CHOICES: Array = ["交好", "请教", "告辞"]

## 开始对话，返回对话数据
func start_dialogue(npc_id: String) -> Dictionary:
	var npc_data = NPCSystem.get_npc(npc_id)
	if npc_data.is_empty():
		return {}

	# 从对话池随机选一条主文本
	var dialogue_text = NPCSystem.get_npc_dialogue(npc_id)
	if dialogue_text.is_empty():
		dialogue_text = "……"

	# 生成选项
	var choices: Array = []
	for choice_text in CHOICES:
		choices.append(choice_text)

	return {
		"npc_data": npc_data,
		"text": dialogue_text,
		"choices": choices,
	}


## 处理玩家选择，返回回复文本和效果
func process_choice(npc_id: String, choice_index: int) -> Dictionary:
	var npc_data = NPCSystem.get_npc(npc_id)
	var npc_name = npc_data.get("name", "未知")

	match choice_index:
		0:  # 交好
			NPCSystem.change_relationship(npc_id, 5)
			var responses: Array = [
				"%s微微一笑：「你倒是个友善之人，日后若有缘，再叙。」" % npc_name,
				"%s点头道：「难得有人主动示好，这份心意我记下了。」" % npc_name,
				"%s拱手回礼：「承蒙厚爱，他日定当回报。」" % npc_name,
			]
			var resp = responses[randi() % responses.size()]
			return {
				"response_text": resp,
				"effects": [{"type": "relationship", "npc_id": npc_id, "amount": 5}],
			}

		1:  # 请教
			var techniques = npc_data.get("techniques", [])
			if techniques.size() > 0:
				# 获得修炼经验
				var exp_gain = randi_range(10, 30)
				var resp_text = "%s取出一卷残卷递给你：「此法虽不完整，但对你应有裨益。」\n[color=#44ff88]修炼经验 +%d[/color]" % [npc_name, exp_gain]
				return {
					"response_text": resp_text,
					"effects": [{"type": "realm_exp", "amount": exp_gain}],
				}
			else:
				var responses2: Array = [
					"%s摇头道：「修行之道，需自悟自强，我能教你的有限。」" % npc_name,
					"%s沉吟片刻：「此中玄妙，非三言两语能说清，你自行领悟吧。」" % npc_name,
				]
				var resp2 = responses2[randi() % responses2.size()]
				var exp_gain = randi_range(5, 10)
				resp2 += "\n[color=#44ff88]修炼经验 +%d[/color]" % exp_gain
				return {
					"response_text": resp2,
					"effects": [{"type": "realm_exp", "amount": exp_gain}],
				}

		2:  # 告辞
			var responses: Array = [
				"%s抱拳道：「后会有期。」" % npc_name,
				"%s微微颔首：「保重。」" % npc_name,
			]
			var resp = responses[randi() % responses.size()]
			return {
				"response_text": resp,
				"effects": [],
			}

		_:
			return {
				"response_text": "……",
				"effects": [],
			}


## 应用效果到玩家角色
func apply_effects(effects: Array) -> Array:
	var notifications: Array = []
	for effect in effects:
		match effect.get("type", ""):
			"relationship":
				var npc_name = NPCSystem.get_npc(effect.get("npc_id", "")).get("name", "NPC")
				notifications.append("与%s关系 +%d" % [npc_name, effect.get("amount", 0)])
			"realm_exp":
				# 给玩家角色增加修炼经验
				var player_id = _get_player_id()
				if not player_id.is_empty():
					var char = GameManager.get_character(player_id)
					if not char.is_empty():
						char["realm_exp"] = char.get("realm_exp", 0) + effect.get("amount", 0)
				notifications.append("修炼经验 +%d" % effect.get("amount", 0))
	return notifications


func _get_player_id() -> String:
	for cid in GameManager.all_characters:
		var c = GameManager.all_characters[cid]
		if c.get("generation", 0) == 1 and c.get("role", "") == "cultivator":
			return cid
	return ""
