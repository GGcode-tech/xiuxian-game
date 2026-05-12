## FamilySystem - 家族系统管理
## 提供家族创建、繁殖等核心功能
extends Node

# 创建新家族
func create_family(founder: Dictionary, family_name: String) -> Dictionary:
	var family: Dictionary = {
		"id": "family_%d" % Time.get_ticks_msec(),
		"name": family_name,
		"founder_id": founder.get("id", ""),
		"founded_year": GameManager.game_time["year"],
		"level": 1,
		"members": [founder.get("id", "")],
		"unlocked_buildings": [],
	}

	GameManager.add_family(family)
	GameManager.player_family_id = family["id"]

	return family

# 创建夫妻关系
func create_marriage(char1: Dictionary, char2: Dictionary) -> void:
	if char1.get("spouse_id", "") != "" or char2.get("spouse_id", "") != "":
		return

	char1["spouse_id"] = char2.get("id", "")
	char2["spouse_id"] = char1.get("id", "")

	var family_id = char1.get("family_id", "")
	var family = GameManager.get_family(family_id)
	if family:
		EventManager.add_notification(
			"喜结连理",
			"%s 与 %s 结为道侣！" % [char1.get("name", ""), char2.get("name", "")],
			"success"
		)

# 生育子女
func create_child(parents: Array, family: Dictionary) -> Dictionary:
	if parents.size() < 2:
		return {}

	var father = parents[0]
	var mother = parents[1]

	if father.get("age", 0) < 16 or mother.get("age", 0) < 16:
		return {}

	var child_data: Dictionary = {
		"family_id": family.get("id", ""),
		"generation": father.get("generation", 1) + 1,
		"parent_ids": [father.get("id", ""), mother.get("id", "")],
		"gender": 0 if randf() < 0.5 else 1,
	}

	var child = _create_child_character(child_data, father, mother)
	family["members"].append(child["id"])
	GameManager.add_character(child)

	father["children_ids"] = father.get("children_ids", [])
	father["children_ids"].append(child["id"])
	mother["children_ids"] = mother.get("children_ids", [])
	mother["children_ids"].append(child["id"])

	EventManager.add_notification(
		"新生命诞生",
		"%s 与 %s 的子女 %s 诞生了！" % [father.get("name", ""), mother.get("name", ""), child.get("name", "")],
		"success"
	)

	GameManager.character_born.emit(child, parents)

	return child

func _create_child_character(
	data: Dictionary,
	father: Dictionary,
	mother: Dictionary
) -> Dictionary:
	var spirit_root: Dictionary = {}
	var father_sr = father.get("spirit_root", {})
	var mother_sr = mother.get("spirit_root", {})
	for key in ["gold", "wood", "water", "fire", "earth"]:
		spirit_root[key] = (
			(father_sr.get(key, 0.3) +
			mother_sr.get(key, 0.3)) / 2.0 +
			randf_range(-0.1, 0.1))
		spirit_root[key] = clampf(spirit_root[key], 0.0, 1.0)

	var child: Dictionary = {
		"id": "char_%d_%d" % [Time.get_ticks_msec(), randi()],
		"name": "子女_%d" % Time.get_ticks_msec(),
		"gender": data.get("gender", 0),
		"age": 0,
		"family_id": data.get("family_id", ""),
		"generation": data.get("generation", 1),
		"parent_ids": data.get("parent_ids", []),
		"spouse_id": "",
		"children_ids": [],
		"spirit_root": spirit_root,
		"bloodline": father.get("bloodline", ""),
		"bloodline_purity": father.get("bloodline_purity", 0.0) * 0.5,
		"realm_id": "mortal",
		"realm_exp": 0,
		"base_stats": {
			"max_hp": 100, "max_mp": 50,
			"attack": 10, "defense": 5,
			"spirit": 10, "speed": 10, "luck": 0
		},
		"hp": 100,
		"mp": 50,
		"is_alive": true,
		"techniques": [],
		"items": [],
		"element": "wood",
		"role": "cultivator",
	}
	return child

# 学习功法
func learn_technique(character: Dictionary, tech_id: String) -> bool:
	if not character.has("techniques"):
		return false
	var techniques: Array = character.get("techniques", [])
	if tech_id in techniques:
		return false
	techniques.append(tech_id)
	character["techniques"] = techniques
	return true
