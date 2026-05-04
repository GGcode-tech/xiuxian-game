## 炼丹系统 - 炼丹配方和炼制逻辑
class_name AlchemySystem extends Node

enum Result {
	PERFECT,
	SUCCESS,
	PARTIAL,
	FAILURE,
	EXPLOSION
}

var recipes: Dictionary = {}

func _ready() -> void:
	_load_recipes()

func _load_recipes() -> void:
	recipes = DataManager.alchemy_recipes

func attempt_alchemy(character, recipe_id: String, quantity: int = 1, use_best_materials: bool = false) -> Dictionary:
	var recipe = recipes.get(recipe_id)
	if not recipe:
		return {"success": false, "reason": "配方不存在"}
	
	var can_result = _check_alchemy_requirements(character, recipe)
	if not can_result.ok:
		return {"success": false, "reason": can_result.reason}
	
	if not _check_materials(character, recipe, quantity):
		return {"success": false, "reason": "材料不足"}
	
	_consume_materials(character, recipe, quantity, use_best_materials)
	
	var success_rate = _calculate_success_rate(character, recipe, use_best_materials)
	
	var results = []
	for i in range(quantity):
		var roll = randf()
		var result_type: Result
		var output_count: int = 0
		var quality_bonus: int = 0
		
		if roll < success_rate * 0.3:
			result_type = Result.PERFECT
			output_count = 1
			quality_bonus = 1
		elif roll < success_rate:
			result_type = Result.SUCCESS
			output_count = 1
		elif roll < success_rate + (1 - success_rate) * 0.4:
			result_type = Result.PARTIAL
			output_count = 1
		elif roll < success_rate + (1 - success_rate) * 0.85:
			result_type = Result.FAILURE
			output_count = 0
		else:
			result_type = Result.EXPLOSION
			output_count = 0
			_handle_explosion(character, recipe)
		
		results.append({
			"type": result_type,
			"output_count": output_count,
			"quality_bonus": quality_bonus
		})
	
	var total_output = {}
	for result in results:
		if result.output_count > 0:
			for output_id in recipe.outputs:
				if not total_output.has(output_id):
					total_output[output_id] = 0
				total_output[output_id] += result.output_count
				var item = ItemInstance.create(output_id, result.output_count)
				item.quality += result.quality_bonus
				character.add_item(item)
	
	var exp_gain = recipe.difficulty * 10
	
	return {
		"success": true,
		"results": results,
		"output": total_output,
		"exp_gain": exp_gain
	}

func _check_alchemy_requirements(character, recipe: Dictionary) -> Dictionary:
	var realm = DataManager.get_realm(character.realm_id)
	if realm and realm.tier < recipe.min_realm_tier:
		return {"ok": false, "reason": "境界不足"}
	
	if character.get_technique_level(recipe.required_technique) < recipe.required_technique_level:
		return {"ok": false, "reason": "功法等级不足"}
	
	return {"ok": true}

func _check_materials(character, recipe: Dictionary, quantity: int) -> bool:
	for material_id in recipe.materials:
		var required = recipe.materials[material_id] * quantity
		if character.get_item_count(material_id) < required:
			var family = GameManager.get_family(character.family_id)
			if not family or family.get_resource(material_id) < required:
				return false
	return true

func _consume_materials(character, recipe: Dictionary, quantity: int, best: bool) -> void:
	for material_id in recipe.materials:
		var required = recipe.materials[material_id] * quantity
		var remaining = required
		remaining -= character.remove_item(material_id, remaining) * 0
		# 先从角色背包扣除
		var from_inv = mini(character.get_item_count(material_id), remaining)
		character.remove_item(material_id, from_inv)
		remaining -= from_inv
		# 再从家族仓库扣除
		if remaining > 0:
			var family = GameManager.get_family(character.family_id)
			if family:
				family.consume_resource(material_id, remaining)

func _calculate_success_rate(character, recipe: Dictionary, best: bool) -> float:
	var rate = 0.5  # 基础50%成功率
	
	var realm = DataManager.get_realm(character.realm_id)
	if realm:
		rate += (realm.tier - recipe.min_realm_tier) * 0.05
	
	var tech_level = character.get_technique_level(recipe.required_technique)
	rate += tech_level * 0.03
	
	if best:
		rate += 0.1
	
	rate += character.bloodline_purity * 0.05
	rate += character.derived_stats.get("spirit", 10) * 0.002
	
	return clamp(rate, 0.05, 0.95)

func _handle_explosion(character, recipe: Dictionary) -> void:
	var damage = int(character.base_stats.max_hp * (0.1 + recipe.difficulty * 0.05))
	character.take_damage(damage)
	
	EventManager.add_notification(
		"炸炉！",
		"%s 炼丹失败炸炉，受到%d点伤害！" % [character.name, damage],
		"danger"
	)

func get_recipe_list(character) -> Array:
	var available = []
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		if _check_alchemy_requirements(character, recipe).ok:
			available.append(recipe)
	return available
