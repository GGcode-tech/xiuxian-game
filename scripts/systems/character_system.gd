## CharacterSystem - 角色系统管理
## 提供角色创建、属性计算等核心功能
extends Node

## 创建新角色（使用字典模拟）
static func create_character(data: Dictionary):
	var ch = {}
	ch["id"] = data.get("id", _generate_id())
	ch["name"] = data.get("name", "未知")
	ch["gender"] = data.get("gender", 0)
	ch["age"] = data.get("age", 0)
	ch["family_id"] = data.get("family_id", "")
	ch["generation"] = data.get("generation", 1)
	ch["parent_ids"] = data.get("parent_ids", [])
	ch["spirit_root"] = data.get("spirit_root", {"gold": 0.3, "wood": 0.3, "water": 0.3, "fire": 0.3, "earth": 0.3})
	ch["bloodline"] = data.get("bloodline", "")
	ch["bloodline_purity"] = data.get("bloodline_purity", 0.0)
	ch["realm_id"] = data.get("realm_id", "mortal")
	ch["realm_exp"] = data.get("realm_exp", 0)
	ch["base_stats"] = {"max_hp": 100, "max_mp": 50, "attack": 10, "defense": 5, "spirit": 10, "speed": 10, "luck": 0}
	ch["hp"] = 100
	ch["mp"] = 50
	ch["traits"] = []
	ch["techniques"] = []
	ch["items"] = []
	return ch

## 学习功法
static func learn_technique(character, tech_id: String) -> bool:
	if not character.has("techniques"):
		return false
	if tech_id in character["techniques"]:
		return false
	character["techniques"].append(tech_id)
	return true

## 生成唯一ID
static func _generate_id() -> String:
	return "char_%d_%d" % [Time.get_ticks_msec(), randi()]

## 计算角色战力
static func calculate_power(character) -> int:
	var power = 0
	power += character.get("derived_stats", {}).get("attack", 10)
	power += character.get("derived_stats", {}).get("defense", 5)
	power += int(character.get("derived_stats", {}).get("max_hp", 100) * 0.5)
	power += int(power * character.get("bloodline_purity", 0.0) * 0.3)
	return power
