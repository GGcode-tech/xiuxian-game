## 角色UI组件 - 角色信息面板
extends Control

# 修炼参数
const BASE_CULTIVATE_EXP: int = 10   # 每次点击修炼获得基础经验

var current_character = null

# UI元素
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var realm_label: Label = $Panel/VBox/RealmLabel
@onready var hp_bar: ProgressBar = $Panel/VBox/HPBar
@onready var mp_bar: ProgressBar = $Panel/VBox/MPBar
@onready var exp_bar: ProgressBar = $Panel/VBox/ExpBar
@onready var stats_container: VBoxContainer = $Panel/VBox/StatsContainer
@onready var techniques_container: VBoxContainer = $Panel/VBox/TechniquesContainer
@onready var inventory_container: GridContainer = $Panel/VBox/InventoryContainer


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
	realm_label.text = realm.get("name", realm_id) if not realm.is_empty() else realm_id

	# 血条
	var base_stats = c.get("base_stats", {})
	hp_bar.max_value = base_stats.get("max_hp", 100)
	hp_bar.value = c.get("hp", 0)
	hp_bar.get_node("Label").text = "%d/%d" % [hp_bar.value, hp_bar.max_value]

	# 蓝条
	mp_bar.max_value = base_stats.get("max_mp", 50)
	mp_bar.value = c.get("mp", 0)
	mp_bar.get_node("Label").text = "%d/%d" % [mp_bar.value, mp_bar.max_value]

	# 经验条 - 显示当前境界经验和下一级所需
	if not realm.is_empty():
		var req_exp = realm.get("required_exp", 100)
		# 炼气期 required_exp=0，用默认值
		if req_exp <= 0:
			req_exp = 100
		exp_bar.max_value = req_exp
		exp_bar.value = c.get("realm_exp", 0)
		exp_bar.get_node("Label").text = "修炼: %d / %d" % [c.get("realm_exp", 0), req_exp]

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
		if not tech_data.is_empty():
			var label = Label.new()
			label.text = tech_data.get("name", tech_id)
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


# ==================== 修炼/突破功能 ====================

func _on_cultivate_pressed() -> void:
	"""修炼按钮：增加经验"""
	if not current_character:
		return

	# 计算修炼获得的经验（基础值 + 灵根加成）
	var spirit_root = current_character.get("spirit_root", {})
	var root_bonus = 0.0
	for element in spirit_root:
		root_bonus += spirit_root[element]
	# 灵根总值 0~1.5 之间 → 加成 100%~250%
	var exp_gain = int(BASE_CULTIVATE_EXP * (1.0 + root_bonus))

	# 增加修炼经验
	current_character["realm_exp"] = current_character.get("realm_exp", 0) + exp_gain

	# 同步到 GameManager 的角色数据
	var char_id = current_character.get("id", "")
	if char_id != "" and GameManager.all_characters.has(char_id):
		GameManager.all_characters[char_id]["realm_exp"] = current_character["realm_exp"]

	# 更新显示
	_update_display()

	# 显示提示
	_show_toast("修炼中... 获得 %d 经验" % exp_gain)


func _on_breakthrough_pressed() -> void:
	"""突破按钮：尝试提升境界"""
	if not current_character:
		return

	var realm_id = current_character.get("realm_id", "")
	var realm = DataManager.get_realm(realm_id)
	if realm.is_empty():
		_show_toast("当前境界数据异常")
		return

	var current_exp = current_character.get("realm_exp", 0)
	var required_exp = realm.get("required_exp", 100)
	# 炼气期 required_exp=0，用默认值
	if required_exp <= 0:
		required_exp = 100

	# 检查经验是否足够
	if current_exp < required_exp:
		_show_toast("修炼经验不足！需要 %d / 当前 %d" % [required_exp, current_exp])
		return

	# 获取下一个境界
	var next_realm = DataManager.get_next_realm(realm_id)
	if next_realm.is_empty():
		_show_toast("已达最高境界，无法突破！")
		return

	# 计算突破概率
	var base_rate = next_realm.get("base_breakthrough_rate", 0.1)
	# 超额经验加成：经验超出越多，概率越高
	var excess_ratio = float(current_exp - required_exp) / float(required_exp)
	var bonus_rate = excess_ratio * 0.2  # 每超出100%，+20%概率
	var breakthrough_rate = clampf(base_rate + bonus_rate, 0.01, 0.95)

	# 尝试突破
	var roll = randf()
	if roll < breakthrough_rate:
		# 突破成功！
		var new_realm_id = next_realm.get("id", "")
		current_character["realm_id"] = new_realm_id
		# 经验溢出保留一部分
		current_character["realm_exp"] = int(current_exp * 0.1)

		# 应用境界加成到 base_stats
		_apply_realm_bonuses(current_character, next_realm)

		# 同步到 GameManager
		var char_id = current_character.get("id", "")
		if char_id != "" and GameManager.all_characters.has(char_id):
			GameManager.all_characters[char_id]["realm_id"] = new_realm_id
			GameManager.all_characters[char_id]["realm_exp"] = current_character["realm_exp"]
			GameManager.all_characters[char_id]["base_stats"] = current_character["base_stats"]

		# 发射突破信号
		GameManager.realm_breakthrough.emit(current_character, new_realm_id)

		_show_toast("🎉 突破成功！当前境界：%s" % next_realm.get("name", new_realm_id))
	else:
		# 突破失败
		var fail_penalty = next_realm.get("failure_penalty", {})
		var exp_loss_rate = fail_penalty.get("exp_loss_rate", 0.2)
		var exp_loss = int(current_exp * exp_loss_rate)
		current_character["realm_exp"] = maxi(0, current_exp - exp_loss)

		# 受伤概率
		var injury_chance = fail_penalty.get("injury_chance", 0.0)
		if randf() < injury_chance:
			var hp_loss = int(current_character.get("hp", 100) * 0.1)
			current_character["hp"] = maxi(1, current_character.get("hp", 100) - hp_loss)

		# 同步到 GameManager
		var char_id = current_character.get("id", "")
		if char_id != "" and GameManager.all_characters.has(char_id):
			GameManager.all_characters[char_id]["realm_exp"] = current_character["realm_exp"]
			GameManager.all_characters[char_id]["hp"] = current_character.get("hp", 100)

		_show_toast("突破失败... 损失 %d 经验" % exp_loss)

	# 更新显示
	_update_display()


func _apply_realm_bonuses(character: Dictionary, realm: Dictionary) -> void:
	"""将境界加成应用到角色基础属性"""
	var base_stats = character.get("base_stats", {})
	base_stats["max_hp"] = base_stats.get("max_hp", 100) + realm.get("max_hp_bonus", 0)
	base_stats["attack"] = base_stats.get("attack", 10) + realm.get("attack_bonus", 0)
	base_stats["max_mp"] = base_stats.get("max_mp", 50) + realm.get("max_mp_bonus", 0)
	base_stats["defense"] = base_stats.get("defense", 5) + realm.get("defense_bonus", 0)
	base_stats["spirit"] = base_stats.get("spirit", 10) + realm.get("spirit_bonus", 0)
	base_stats["speed"] = base_stats.get("speed", 10) + realm.get("speed_bonus", 0)
	character["base_stats"] = base_stats
	# 回满血蓝
	character["hp"] = base_stats.get("max_hp", 100)
	character["mp"] = base_stats.get("max_mp", 50)


func _show_toast(text: String) -> void:
	"""显示简短提示（在角色面板内）"""
	# 查找或创建提示标签
	var toast = get_node_or_null("ToastLabel")
	if not toast:
		toast = Label.new()
		toast.name = "ToastLabel"
		# 定位在面板上方
		toast.anchors_preset = Control.PRESET_CENTER_TOP
		toast.offset_left = -150
		toast.offset_top = -30
		toast.offset_right = 150
		toast.offset_bottom = -5
		toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		toast.add_theme_font_size_override("font_size", 14)
		add_child(toast)

	toast.text = text
	toast.visible = true
	toast.modulate = Color.WHITE

	# 2秒后淡出
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): toast.visible = false)


func _process(_delta: float) -> void:
	if current_character and visible:
		# 实时更新血蓝条
		hp_bar.value = current_character.get("hp", 0)
		mp_bar.value = current_character.get("mp", 0)
