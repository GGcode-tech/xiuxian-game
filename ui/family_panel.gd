## 家族管理面板 - 家族信息和操作
extends Control

@onready var family_name_label: Label = $Panel/VBox/FamilyNameLabel
@onready var level_label: Label = $Panel/VBox/LevelLabel
@onready var member_list: ItemList = $Panel/VBox/HBox/MemberList
@onready var resource_grid: GridContainer = $Panel/VBox/ResourceGrid
@onready var building_list: ItemList = $Panel/VBox/HBox/BuildingList
@onready var territory_list: ItemList = $Panel/VBox/HBox/TerritoryList

var current_family = null


func setup(family) -> void:
	current_family = family
	_update_display()


func _update_display() -> void:
	if not current_family:
		return
	
	family_name_label.text = current_family.name
	level_label.text = "等级: %d" % current_family.level
	
	_update_members()
	_update_resources()
	_update_buildings()
	_update_territories()


func _update_members() -> void:
	member_list.clear()
	
	if not current_family:
		return
	
	for member_id in current_family.members:
		var character = GameManager.get_character(member_id)
		if character and character.is_alive:
			var realm = DataManager.get_realm(character.realm_id)
			var realm_name = realm.name if realm else character.realm_id
			var text = "%s [%s] %d岁" % [character.name, realm_name, character.age]
			member_list.add_item(text)


func _update_resources() -> void:
	for child in resource_grid.get_children():
		child.queue_free()
	
	if not current_family:
		return
	
	var resource_names = {
		"spirit_stone": "灵石",
		"spirit_grass": "灵草",
		"spirit_ore": "灵矿",
		"blood_essence": "精血",
		"contribution": "贡献"
	}
	
	for resource_id in current_family.resources:
		var name_label = Label.new()
		name_label.text = resource_names.get(resource_id, resource_id)
		resource_grid.add_child(name_label)
		
		var value_label = Label.new()
		value_label.text = str(current_family.resources[resource_id])
		resource_grid.add_child(value_label)


func _update_buildings() -> void:
	building_list.clear()
	
	if not current_family:
		return
	
	for building_id in current_family.unlocked_buildings:
		building_list.add_item(building_id)


func _update_territories() -> void:
	territory_list.clear()
	
	if not current_family:
		return
	
	for territory_id in current_family.territories:
		var territory_data: Dictionary = MapData.territories_data.get(territory_id, {})
		if not territory_data.is_empty():
			territory_list.add_item(territory_data.get("name", ""))


func _on_member_selected(index: int) -> void:
	if not current_family:
		return
	
	var member_id = current_family.members[index]
	var character = GameManager.get_character(member_id)
	if character:
		# 打开角色详情面板
		EventManager.ui_request_character_detail.emit(character)


func _on_recruit_pressed() -> void:
	# TODO: 招募新成员
	pass


func _on_build_pressed() -> void:
	# TODO: 建造建筑
	pass


func _on_explore_pressed() -> void:
	# TODO: 探索领地
	pass
