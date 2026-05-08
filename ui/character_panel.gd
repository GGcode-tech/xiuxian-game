## 角色UI组件 - 角色信息面板
extends Control

# UI元素
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var realm_label: Label = $Panel/VBox/RealmLabel
@onready var hp_bar: ProgressBar = $Panel/VBox/HPBar
@onready var mp_bar: ProgressBar = $Panel/VBox/MPBar
@onready var exp_bar: ProgressBar = $Panel/VBox/ExpBar
@onready var stats_container: VBoxContainer = $Panel/VBox/StatsContainer
@onready var techniques_container: VBoxContainer = $Panel/VBox/TechniquesContainer
@onready var inventory_container: GridContainer = $Panel/VBox/InventoryContainer

# 当前显示的角色
var current_character = null


func setup(character) -> void:
	current_character = character
	_update_display()


func _update_display() -> void:
	if not current_character:
		return
	
	var c = current_character
	
	# 基础信息（字典安全访问）
	name_label.text = c.get("name", "未知")
	var realm_id = c.get("realm_id", "")
	var realm = DataManager.get_realm(realm_id)
	realm_label.text = realm.name if realm else realm_id
	
	# 血条
	var base_stats = c.get("base_stats", {})
	hp_bar.max_value = base_stats.get("max_hp", 100)
	hp_bar.value = c.get("hp", 0)
	hp_bar.get_node("Label").text = "%d/%d" % [hp_bar.value, hp_bar.max_value]
	
	# 蓝条
	mp_bar.max_value = base_stats.get("max_mp", 50)
	mp_bar.value = c.get("mp", 0)
	mp_bar.get_node("Label").text = "%d/%d" % [mp_bar.value, mp_bar.max_value]
	
	# 经验条
	if realm:
		exp_bar.max_value = realm.required_exp if "required_exp" in realm else 100
		exp_bar.value = c.get("realm_exp", 0)
	
	# 属性
	_update_stats()
	
	# 功法
	_update_techniques()
	
	# 物品
	_update_inventory()


func _update_stats() -> void:
	for child in stats_container.get_children():
		child.queue_free()
	
	if not current_character:
		return
	
	var c = current_character
	var base_stats = c.get("base_stats", {})
	
	var stats = [
		["攻击", base_stats.get("attack", 0)],
		["防御", base_stats.get("defense", 0)],
		["灵力", base_stats.get("spirit", 0)],
		["速度", base_stats.get("speed", 0)],
		["年龄", c.get("age", 0)],
	]
	
	for stat in stats:
		var label = Label.new()
		label.text = "%s: %s" % [stat[0], str(stat[1])]
		stats_container.add_child(label)


func _update_techniques() -> void:
	for child in techniques_container.get_children():
		child.queue_free()
	
	if not current_character:
		return
	
	var techniques = current_character.get("techniques", [])
	for tech_id in techniques:
		var tech_data = DataManager.get_technique(tech_id)
		if tech_data:
			var label = Label.new()
			label.text = "%s" % tech_data.name if "name" in tech_data else tech_id
			techniques_container.add_child(label)


func _update_inventory() -> void:
	for child in inventory_container.get_children():
		child.queue_free()
	
	if not current_character:
		return
	
	var items = current_character.get("items", [])
	for item_id in items:
		var button = Button.new()
		button.text = item_id
		inventory_container.add_child(button)


func _on_breakthrough_pressed() -> void:
	# TODO: 突破功能（需要GameManager支持）
	pass


func _on_cultivate_pressed() -> void:
	# TODO: 修炼功能
	pass


func _process(_delta: float) -> void:
	if current_character and visible:
		# 实时更新血蓝条
		hp_bar.value = current_character.get("hp", 0)
		mp_bar.value = current_character.get("mp", 0)
