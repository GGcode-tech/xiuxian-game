## 3D角色节点 - 游戏世界中的角色表示
extends CharacterBody3D

@onready var name_label: Label3D = $NameLabel
@onready var realm_indicator: MeshInstance3D = $RealmIndicator

var character_data = null

func setup(character) -> void:
	character_data = character
	name_label.text = character.name
	_update_realm_indicator()

func _update_realm_indicator() -> void:
	if not character_data:
		return
	var realm = DataManager.get_realm(character_data.realm_id)
	if realm:
		# 根据境界设置指示器颜色
		var colors = {
			"refining_qi": Color.CYAN,
			"foundation": Color.LIME,
			"core_formation": Color.GOLD,
			"nascent_soul": Color.MEDIUM_PURPLE,
			"spirit_transformation": Color.ORANGE_RED,
			"void_refining": Color.DEEP_PINK,
			"body_integration": Color.RED,
			"mahayana": Color.WHITE,
			"tribulation": Color.YELLOW,
			"ascension": Color.VIOLET,
		}
		var indicator_material = StandardMaterial3D.new()
		indicator_material.emission_enabled = true
		indicator_material.emission = colors.get(character_data.realm_id, Color.WHITE)
		indicator_material.emission_energy = 2.0
		realm_indicator.material_override = indicator_material

func _physics_process(_delta: float) -> void:
	# 简单空闲动画 - 上下浮动
	if character_data and character_data.is_alive:
		position.y = 0.0 + sin(Time.get_ticks_msec() / 500.0) * 0.05
