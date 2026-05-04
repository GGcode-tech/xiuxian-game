## 程序化演示场景 - 展示所有生成的3D资源
## 运行此场景可查看生成的建筑、角色、自然物、特效

extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var light: DirectionalLight3D = $DirectionalLight3D

var display_objects: Array[Node3D] = []
var current_category := 0
var rotation_angle := 0.0

const CATEGORIES := ["建筑", "角色", "自然", "特效"]

func _ready() -> void:
	_setup_scene()
	_display_category(0)
	print("按 ← → 切换分类，↑ ↓ 切换类型，R 重新生成")

func _setup_scene() -> void:
	# 相机
	camera = Camera3D.new()
	camera.position = Vector3(0, 5, 12)
	camera.look_at(Vector3.ZERO)
	add_child(camera)
	
	# 光照
	light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO)
	light.shadow_enabled = true
	add_child(light)
	
	# 环境光
	var env_light := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_LIGHT_SKY
	env.ambient_light_color = Color(0.4, 0.4, 0.5)
	env_light.environment = env
	add_child(env_light)
	
	# 地面
	var floor_mesh := CSGBox3D.new()
	floor_mesh.size = Vector3(30, 0.1, 30)
	floor_mesh.position.y = -0.05
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.4, 0.35)
	floor_mesh.material = floor_mat
	add_child(floor_mesh)

func _display_category(category_index: int) -> void:
	current_category = category_index
	
	# 清除旧对象
	for obj in display_objects:
		obj.queue_free()
	display_objects.clear()
	
	match category_index:
		0: _display_buildings()
		1: _display_characters()
		2: _display_nature()
		3: _display_effects()

func _display_buildings() -> void:
	var types := [
		ProceduralBuilding.BuildingType.HALL,
		ProceduralBuilding.BuildingType.PAGODA,
		ProceduralBuilding.BuildingType.PAVILION,
		ProceduralBuilding.BuildingType.ALTAR,
		ProceduralBuilding.BuildingType.GATE,
		ProceduralBuilding.BuildingType.FORGE,
		ProceduralBuilding.BuildingType.ALCHEMY_ROOM,
		ProceduralBuilding.BuildingType.LIBRARY,
	]
	
	var names := ["大殿", "宝塔", "亭阁", "祭坛", "山门", "炼器房", "炼丹房", "藏经阁"]
	
	for i in range(types.size()):
		var building := ResourceManager.create_building(types[i], 0.8)
		building.position = Vector3((i % 4 - 1.5) * 5, 0, (i / 4 - 0.5) * 6)
		add_child(building)
		display_objects.append(building)
		
		# 标签
		var label := _create_label(names[i])
		label.position = building.position + Vector3(0, 6, 0)
		add_child(label)
		display_objects.append(label)

func _display_characters() -> void:
	var types := [
		ProceduralCharacter.CharacterType.CULTIVATOR,
		ProceduralCharacter.CharacterType.ELDER,
		ProceduralCharacter.CharacterType.DISCIPILE,
		ProceduralCharacter.CharacterType.VILLAGER,
		ProceduralCharacter.CharacterType.GUARDIAN,
		ProceduralCharacter.CharacterType.ALCHEMIST,
		ProceduralCharacter.CharacterType.SWORDSMAN,
		ProceduralCharacter.CharacterType.ELDER_MONK,
	]
	
	var names := ["修士", "长老", "弟子", "村民", "守卫", "炼丹师", "剑修", "老僧"]
	var colors := [
		Color(0.3, 0.5, 0.7),  # 蓝袍
		Color(0.6, 0.4, 0.2),  # 棕袍
		Color(0.4, 0.6, 0.4),  # 绿袍
		Color(0.5, 0.4, 0.35), # 灰袍
		Color(0.35, 0.35, 0.4), # 铁甲
		Color(0.5, 0.6, 0.5),  # 青袍
		Color(0.25, 0.25, 0.35), # 黑袍
		Color(0.75, 0.6, 0.4), # 僧袍
	]
	
	for i in range(types.size()):
		var char_node := Node3D.new()
		var character := ResourceManager.create_character(types[i], colors[i])
		character.scale = Vector3(2.0, 2.0, 2.0)  # 放大显示
		char_node.add_child(character)
		char_node.position = Vector3((i % 4 - 1.5) * 4, 0, (i / 4 - 0.5) * 4)
		add_child(char_node)
		display_objects.append(char_node)
		
		var label := _create_label(names[i])
		label.position = char_node.position + Vector3(0, 4, 0)
		add_child(label)
		display_objects.append(label)

func _display_nature() -> void:
	# 树木
	var tree_types := [
		ProceduralNature.TreeType.PINE,
		ProceduralNature.TreeType.BAMBOO,
		ProceduralNature.TreeType.WILLOW,
		ProceduralNature.TreeType.PEACH,
		ProceduralNature.TreeType.GINKGO,
		ProceduralNature.TreeType.SPIRIT_TREE,
	]
	var tree_names := ["松树", "竹子", "柳树", "桃树", "银杏", "灵树"]
	
	for i in range(tree_types.size()):
		var tree := ResourceManager.create_tree(tree_types[i], 1.0)
		tree.position = Vector3((i % 3 - 1) * 4, 0, (i / 3 - 1.5) * 6)
		add_child(tree)
		display_objects.append(tree)
		
		var label := _create_label(tree_names[i])
		label.position = tree.position + Vector3(0, 5, 0)
		add_child(label)
		display_objects.append(label)
	
	# 岩石
	var rock_types := [
		ProceduralNature.RockType.BOULDER,
		ProceduralNature.RockType.TAIHU,
		ProceduralNature.RockType.SPIRIT_STONE,
	]
	var rock_names := ["巨石", "太湖石", "灵石"]
	
	for i in range(rock_types.size()):
		var rock := ResourceManager.create_rock(rock_types[i], 1.5)
		rock.position = Vector3(i * 3 - 3, 0, 4)
		add_child(rock)
		display_objects.append(rock)
		
		var label := _create_label(rock_names[i])
		label.position = rock.position + Vector3(0, 3, 0)
		add_child(label)
		display_objects.append(label)
	
	# 花草
	var plant_types := [
		ProceduralNature.PlantType.GRASS,
		ProceduralNature.PlantType.LOTUS,
		ProceduralNature.PlantType.SPIRIT_HERB,
	]
	var plant_names := ["草丛", "荷花", "灵草"]
	
	for i in range(plant_types.size()):
		var plant := ResourceManager.create_plant(plant_types[i], 2.0)
		plant.position = Vector3(i * 3 + 6, 0, 4)
		add_child(plant)
		display_objects.append(plant)
		
		var label := _create_label(plant_names[i])
		label.position = plant.position + Vector3(0, 2, 0)
		add_child(label)
		display_objects.append(label)

func _display_effects() -> void:
	var types := [
		ProceduralEffects.EffectType.QI_ORB,
		ProceduralEffects.EffectType.GLIDING_SWORD,
		ProceduralEffects.EffectType.ALCHEMY_FLAME,
		ProceduralEffects.EffectType.BREAKTHROUGH,
		ProceduralEffects.EffectType.DAN,
		ProceduralEffects.EffectType.YUANYING,
		ProceduralEffects.EffectType.PORTAL,
		ProceduralEffects.EffectType.MEDITATION_AURA,
	]
	var names := ["灵气球", "飞剑", "丹火", "突破", "金丹", "元婴", "传送门", "光环"]
	var colors := ["qi_blue", "qi_gold", "fire_red", "breakthrough_white", "qi_gold", "qi_blue", "qi_purple", "qi_green"]
	
	for i in range(types.size()):
		var effect := ResourceManager.create_effect(types[i], 0.8, colors[i])
		effect.position = Vector3((i % 4 - 1.5) * 4, 2, (i / 4 - 0.5) * 5)
		add_child(effect)
		display_objects.append(effect)
		
		var label := _create_label(names[i])
		label.position = effect.position + Vector3(0, 4, 0)
		add_child(label)
		display_objects.append(label)

func _create_label(text: String) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.modulate = Color(1, 1, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.fixed_size = true
	return label

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_display_category((current_category - 1) % CATEGORIES.size())
			KEY_RIGHT:
				_display_category((current_category + 1) % CATEGORIES.size())
			KEY_R:
				_display_category(current_category)

func _process(delta: float) -> void:
	rotation_angle += delta * 0.2
	camera.position.x = sin(rotation_angle) * 15
	camera.position.z = cos(rotation_angle) * 15
	camera.look_at(Vector3(0, 2, 0))
