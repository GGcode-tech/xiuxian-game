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
	# 自动截图
	ScreenshotSystem.auto_screenshot("15_家族")


func _update_display() -> void:
	if not current_family:
		return

	family_name_label.text = current_family.get("name", "未知家族")
	level_label.text = "等级: %d" % current_family.get("level", 1)

	_update_members()
	_update_resources()
	_update_buildings()
	_update_territories()


func _update_members() -> void:
	member_list.clear()

	if not current_family:
		return

	var members = current_family.get("members", [])
	for member_id in members:
		var character = GameManager.get_character(member_id)
		if character and not character.is_empty() and character.get("is_alive", false):
			var realm_id = character.get("realm_id", "")
			var realm = DataManager.get_realm(realm_id)
			var realm_name = realm.name if realm else realm_id
			var char_name = character.get("name", "未知")
			var age = character.get("age", 0)
			var text = "%s [%s] %d岁" % [char_name, realm_name, age]
			member_list.add_item(text)


func _update_resources() -> void:
	for child in resource_grid.get_children():
		child.queue_free()

	if not current_family:
		return

	# 从玩家角色获取资源
	var player = _get_player_character()
	if player.is_empty():
		return

	var resources = player.get("resources", {})
	var resource_names = {
		"spirit_stone": "灵石",
		"essence": "精华",
		"spirit_jade": "灵玉",
		"stamina": "体力",
		"energy": "精力"
	}

	for resource_id in resources:
		var name_label = Label.new()
		name_label.text = resource_names.get(resource_id, resource_id)
		resource_grid.add_child(name_label)

		var value_label = Label.new()
		value_label.text = str(resources[resource_id])
		resource_grid.add_child(value_label)


func _get_player_character() -> Dictionary:
	for cid in GameManager.all_characters:
		var c = GameManager.all_characters[cid]
		if c.get("generation", 0) == 1 and c.get("role", "") == "cultivator":
			return c
	return {}


func _update_buildings() -> void:
	building_list.clear()

	if not current_family:
		return

	var buildings = current_family.get("unlocked_buildings", [])
	for building_id in buildings:
		building_list.add_item(building_id)

	if buildings.is_empty():
		building_list.add_item("暂无建筑")


func _update_territories() -> void:
	territory_list.clear()

	if not current_family:
		return

	# 家族数据中没有 territories 字段，显示提示
	territory_list.add_item("暂无领地")


func _on_member_selected(index: int) -> void:
	if not current_family:
		return

	var members = current_family.get("members", [])
	if index < members.size():
		var member_id = members[index]
		var character = GameManager.get_character(member_id)
		if character and not character.is_empty():
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
