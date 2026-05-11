## 世界节点 - 管理3D世界渲染和交互
## 使用Kenney GLB模型替换程序化几何体
extends Node3D

# 3D场景节点
@onready var terrain: Node3D = $Terrain
@onready var buildings: Node3D = $Buildings
@onready var characters_node: Node3D = $Characters
@onready var nature: Node3D = $Nature
@onready var effects: Node3D = $Effects
@onready var camera: Camera3D = $Camera3D
@onready var environment: WorldEnvironment = $WorldEnvironment
@onready var lighting: DirectionalLight3D = $Lighting

# 缓存
var _character_nodes: Dictionary = {}
var _building_nodes: Dictionary = {}
var _npc_nodes: Dictionary = {}

# 地形参数
@export var terrain_size: float = 100.0
@export var tree_count: int = 50
@export var rock_count: int = 20

# Kenney模型路径常量
const KENNEY_BUILDINGS = "res://assets/models/kenney_buildings/"
const KENNEY_NATURE = "res://assets/models/kenney_nature/"
const KENNEY_DECOR = "res://assets/models/kenney_decor/"
const KENNEY_PLANTS = "res://assets/models/kenney_plants/"
const KENNEY_TERRAIN = "res://assets/models/kenney_terrain/"
const OGA_TEMPLE = "res://assets/models/opengameart_temple/"
const OGA_BAMBOO = "res://assets/models/opengameart_bamboo/"
const OGA_DRAGON = "res://assets/models/opengameart_dragon/"

# 模型缓存
var _model_cache: Dictionary = {}


func initialize() -> void:
	_generate_terrain()
	_place_buildings()
	_generate_nature()
	_place_decorations()
	_spawn_characters()
	_spawn_npcs()
	_setup_camera()


# ==================== GLB模型加载 ====================

# 相机控制参数
var _camera_zoom_speed: float = 5.0
var _camera_min_height: float = 5.0
var _camera_max_height: float = 60.0

# 玩家角色节点引用
var _player_node: Node3D = null
var _move_target: Vector3 = Vector3.ZERO
var _is_moving: bool = false
var _move_speed: float = 8.0

func _load_glb_model(path: String) -> Node3D:
	"""加载GLB模型，带缓存（load()返回PackedScene，可安全instantiate）"""
	if _model_cache.has(path):
		var cached_scene = _model_cache[path]
		if cached_scene:
			return cached_scene.instantiate()

	if not ResourceLoader.exists(path):
		push_warning("[World] GLB模型不存在: %s" % path)
		return null

	var scene = load(path)
	if scene is PackedScene:
		_model_cache[path] = scene
		return scene.instantiate()

	push_warning("[World] GLB加载后不是PackedScene: %s" % path)
	return null


func _get_building_model(building_type: int) -> Node3D:
	"""根据建筑类型返回对应的GLB模型"""
	var model_map: Dictionary = {
		0: KENNEY_BUILDINGS + "gate.glb",           # 山门
		1: KENNEY_BUILDINGS + "tower-square.glb",    # 主殿
		2: KENNEY_BUILDINGS + "tower-square.glb",    # 祭坛5
		3: KENNEY_BUILDINGS + "tower-hexagon.glb",   # 藏经阁
		4: KENNEY_BUILDINGS + "tower-square.glb",    # 炼丹房
		5: KENNEY_BUILDINGS + "tower-square.glb",    # 炼器房
		6: KENNEY_BUILDINGS + "tower-square-roof.glb", # 修炼塔
		7: KENNEY_BUILDINGS + "bridge-straight.glb", # 观景亭
		8: KENNEY_BUILDINGS + "wall.glb",            # 居室
	}

	var path = model_map.get(building_type, KENNEY_BUILDINGS + "tower-square.glb")
	return _load_glb_model(path)


func _get_tree_model(tree_type: int) -> Node3D:
	"""根据树木类型返回对应的GLB模型"""
	var model_map: Dictionary = {
		0: KENNEY_NATURE + "tree_pineDefaultA.glb",      # 松树
		1: KENNEY_NATURE + "tree_default.glb",            # 普通树
		2: KENNEY_NATURE + "tree_oak.glb",                # 橡树/柳树
		3: KENNEY_PLANTS + "tree_pine_tall_a.glb",        # 高大古松
		4: KENNEY_PLANTS + "tree_thin.glb",               # 细长树/竹形
		5: KENNEY_PLANTS + "tree_fat.glb",                # 粗壮古树
		6: KENNEY_PLANTS + "tree_detailed.glb",           # 精细树
		7: KENNEY_PLANTS + "tree_tall.glb",               # 参天大树
		8: KENNEY_PLANTS + "tree_cone.glb",               # 尖锥松
		9: KENNEY_PLANTS + "tree_blocks.glb",             # 方块树(秋冬感)
		10: KENNEY_PLANTS + "tree_simple.glb",            # 简约树
		11: KENNEY_PLANTS + "tree_small.glb",             # 小树苗
		12: KENNEY_PLANTS + "tree_pine_small_a.glb",      # 小松树
		13: KENNEY_PLANTS + "tree_oak_fall.glb",          # 秋色橡树
		14: KENNEY_PLANTS + "tree_default_fall.glb",      # 秋色树
	}

	var path = model_map.get(tree_type, KENNEY_NATURE + "tree_default.glb")
	return _load_glb_model(path)


func _get_rock_model(rock_type: int) -> Node3D:
	"""根据岩石类型返回对应的GLB模型"""
	var model_map: Dictionary = {
		0: KENNEY_NATURE + "rock_largeA.glb",        # 大岩石
		1: KENNEY_NATURE + "rock_smallA.glb",        # 小岩石
		2: KENNEY_NATURE + "rock_tallA.glb",         # 高岩石
		3: KENNEY_NATURE + "stone_largeA.glb",       # 灵石
		4: KENNEY_TERRAIN + "rock_large_b.glb",      # 大岩石B
		5: KENNEY_TERRAIN + "rock_large_c.glb",      # 大岩石C
		6: KENNEY_TERRAIN + "rock_tall_b.glb",       # 高岩石B
		7: KENNEY_TERRAIN + "rock_tall_c.glb",       # 高岩石C
		8: KENNEY_TERRAIN + "stone_large_b.glb",     # 大灵石B
		9: KENNEY_TERRAIN + "stone_large_c.glb",     # 大灵石C
	}

	var path = model_map.get(rock_type, KENNEY_NATURE + "rock_smallA.glb")
	return _load_glb_model(path)


# ==================== 地形生成 ====================

func _generate_terrain() -> void:
	var ground := CSGBox3D.new()
	ground.size = Vector3(terrain_size, 0.5, terrain_size)
	ground.position.y = -0.25
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.45, 0.72, 0.30)
	ground.material = ground_mat
	terrain.add_child(ground)

	var pond := CSGCylinder3D.new()
	pond.radius = 8.0
	pond.height = 0.1
	pond.position = Vector3(20, 0.05, 15)
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.30, 0.60, 0.90, 0.65)
	water_mat.roughness = 0.1
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pond.material = water_mat
	terrain.add_child(pond)

	for i in range(5):
		var lotus := _create_plant(0)
		lotus.position = Vector3(18 + randf() * 4, 0.1, 13 + randf() * 4)
		nature.add_child(lotus)


# ==================== 建筑放置 ====================

func _place_buildings() -> void:
	var family = GameManager.get_player_family()
	if not family:
		_create_default_buildings()
		return
	_place_family_buildings(family)


func _create_default_buildings() -> void:
	var layout: Array = [
		{"type": 0, "pos": Vector3(0, 0, 30), "name": "山门"},
		{"type": 1, "pos": Vector3(0, 0, 15), "name": "主殿"},
		{"type": 2, "pos": Vector3(0, 0, 0), "name": "祭坛"},
		{"type": 3, "pos": Vector3(-15, 0, 10), "name": "藏经阁"},
		{"type": 4, "pos": Vector3(15, 0, 10), "name": "炼丹房"},
		{"type": 5, "pos": Vector3(20, 0, -5), "name": "炼器房"},
		{"type": 6, "pos": Vector3(-20, 0, -5), "name": "修炼塔"},
		{"type": 7, "pos": Vector3(0, 0, -15), "name": "观景亭"},
		{"type": 8, "pos": Vector3(-10, 0, -20), "name": "居室A"},
		{"type": 8, "pos": Vector3(10, 0, -20), "name": "居室B"},
	]

	for item in layout:
		var building_node: Node3D = _get_building_model(item["type"])
		if building_node:
			building_node.position = item["pos"]
			building_node.scale = Vector3(3.0, 3.0, 3.0)  # 放大3倍
			building_node.set_meta("building_name", item["name"])
			buildings.add_child(building_node)
			_building_nodes[item["name"]] = building_node
			_add_building_collision(building_node)
		else:
			# 回退到程序化几何体
			var building: MeshInstance3D = _create_building_fallback(item["type"], 1.0)
			building.position = item["pos"]
			building.set_meta("building_name", item["name"])
			buildings.add_child(building)
			_building_nodes[item["name"]] = building
			_add_building_collision(building)


func _place_family_buildings(family: Dictionary) -> void:
	var main_hall := _get_building_model(1)
	if main_hall:
		main_hall.position = Vector3(0, 0, 10)
		main_hall.scale = Vector3(3.5, 3.5, 3.5)
		main_hall.set_meta("building_name", "主殿")
		buildings.add_child(main_hall)
		_add_building_collision(main_hall)
		_building_nodes["主殿"] = main_hall

	var building_positions: Dictionary = {
		"alchemy": Vector3(12, 0, 5),
		"forge": Vector3(-12, 0, 5),
		"library": Vector3(0, 0, -10),
		"pagoda": Vector3(15, 0, -5),
		"residence": Vector3(-15, 0, -5),
	}

	for building_id in family.get("unlocked_buildings", []):
		if building_positions.has(building_id):
			var building_type := _get_building_type(building_id)
			var building_node := _get_building_model(building_type)
			if building_node:
				building_node.position = building_positions[building_id]
				building_node.scale = Vector3(3.0, 3.0, 3.0)
				var b_name := _get_building_name(building_id)
				building_node.set_meta("building_name", b_name)
				buildings.add_child(building_node)
				_add_building_collision(building_node)
				_building_nodes[b_name] = building_node


func _get_building_type(building_id: String) -> int:
	match building_id:
		"alchemy": return 4
		"forge": return 5
		"library": return 3
		"pagoda": return 6
		"residence": return 8
		_: return 1


func _get_building_name(building_id: String) -> String:
	match building_id:
		"alchemy": return "炼丹房"
		"forge": return "炼器房"
		"library": return "藏经阁"
		"pagoda": return "修炼塔"
		"residence": return "居室"
		_: return "主殿"


func _add_building_collision(node: Node3D) -> void:
	"""给建筑节点添加StaticBody3D碰撞体（碰撞层=2）"""
	var body := StaticBody3D.new()
	body.name = node.name + "_body"
	body.collision_layer = 2   # layer 2 = buildings
	body.collision_mask = 0    # 建筑不需要检测其他物理体
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 6, 6)
	shape.shape = box
	body.add_child(shape)
	node.add_child(body)


# ==================== 装饰物放置 ====================

func _place_decorations() -> void:
	"""放置灵泉、灯笼、旗帜、摊位等装饰"""
	# 灵泉（中心广场）
	_place_deco(KENNEY_DECOR + "fountain-round.glb", Vector3(0, 0, -2), 2.5)

	# 灯笼（主要路口）
	_place_deco(KENNEY_DECOR + "lantern.glb", Vector3(-8, 0, 12), 1.5)
	_place_deco(KENNEY_DECOR + "lantern.glb", Vector3(8, 0, 12), 1.5)
	_place_deco(KENNEY_DECOR + "lantern.glb", Vector3(0, 0, 22), 1.5)
	_place_deco(KENNEY_DECOR + "lantern.glb", Vector3(-12, 0, -8), 1.5)
	_place_deco(KENNEY_DECOR + "lantern.glb", Vector3(12, 0, -8), 1.5)

	# 旗帜（山门两侧）
	_place_deco(KENNEY_DECOR + "banner-red.glb", Vector3(-4, 0, 28), 2.0)
	_place_deco(KENNEY_DECOR + "banner-green.glb", Vector3(4, 0, 28), 2.0)
	_place_deco(KENNEY_DECOR + "flag.glb", Vector3(-3, 0, 32), 1.5)
	_place_deco(KENNEY_DECOR + "flag.glb", Vector3(3, 0, 32), 1.5)

	# 集市摊位（广场两侧）
	_place_deco(KENNEY_DECOR + "stall-red.glb", Vector3(10, 0, -15), 2.0)
	_place_deco(KENNEY_DECOR + "stall-green.glb", Vector3(-10, 0, -15), 2.0)
	_place_deco(KENNEY_DECOR + "stall.glb", Vector3(6, 0, -18), 1.5)
	_place_deco(KENNEY_DECOR + "stall-bench.glb", Vector3(-6, 0, -18), 1.5)

	# 石柱（主殿两侧）
	_place_deco(KENNEY_DECOR + "pillar-stone.glb", Vector3(-5, 0, 10), 2.0)
	_place_deco(KENNEY_DECOR + "pillar-stone.glb", Vector3(5, 0, 10), 2.0)

	# 推车（小径旁）
	_place_deco(KENNEY_DECOR + "cart.glb", Vector3(18, 0, 3), 1.5)

	# 篱笆（居室周围）
	_place_deco(KENNEY_DECOR + "fence.glb", Vector3(-14, 0, -23), 2.0)
	_place_deco(KENNEY_DECOR + "fence.glb", Vector3(-8, 0, -23), 2.0)
	_place_deco(KENNEY_DECOR + "fence-gate.glb", Vector3(-11, 0, -23), 2.0)
	_place_deco(KENNEY_DECOR + "fence.glb", Vector3(8, 0, -23), 2.0)
	_place_deco(KENNEY_DECOR + "fence.glb", Vector3(14, 0, -23), 2.0)

	# 雕像（祭坛旁）
	_place_deco(KENNEY_TERRAIN + "statue_obelisk.glb", Vector3(-6, 0, -1), 2.0)
	_place_deco(KENNEY_TERRAIN + "statue_obelisk.glb", Vector3(6, 0, -1), 2.0)

	# 石桥（灵泉旁）
	_place_deco(KENNEY_TERRAIN + "bridge_stone.glb", Vector3(12, 0.1, 15), 2.0)
	_place_deco(KENNEY_TERRAIN + "bridge_wood.glb", Vector3(-12, 0.1, 15), 2.0)

	# 花盆（主殿门前）
	_place_deco(KENNEY_TERRAIN + "pot_large.glb", Vector3(-3, 0, 14), 1.5)
	_place_deco(KENNEY_TERRAIN + "pot_large.glb", Vector3(3, 0, 14), 1.5)


func _place_deco(model_path: String, pos: Vector3, scale: float) -> void:
	"""放置单个装饰物到buildings节点"""
	var node := _load_glb_model(model_path)
	if node:
		node.position = pos
		node.scale = Vector3(scale, scale, scale)
		buildings.add_child(node)


func _add_character_collision(node: Node3D) -> void:
	"""给角色节点添加StaticBody3D碰撞体（碰撞层=3）"""
	var body := StaticBody3D.new()
	body.name = "CharacterBody"
	body.collision_layer = 4   # layer 3 = characters
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.5
	shape.shape = sphere
	body.add_child(shape)
	node.add_child(body)


# ==================== NPC生成 ====================

func _spawn_npcs() -> void:
	"""从NPCSystem生成代表性NPC到3D世界"""
	var all_npcs = NPCSystem.get_all_npcs()
	if all_npcs.is_empty():
		print("[World] NPCSystem无NPC数据，跳过NPC生成")
		return

	# 选取10-15个代表性NPC（不同来源各取几个）
	var sources = NPCSystem.get_all_sources()
	var selected: Array = []
	var per_source = maxi(1, 12 / maxi(sources.size(), 1))

	for source in sources:
		var npcs = NPCSystem.get_npcs_by_source(source)
		for i in range(mini(per_source, npcs.size())):
			selected.append(npcs[i])
		if selected.size() >= 12:
			break

	# 如果不够，从所有NPC中补充
	if selected.size() < 10:
		var all_ids = all_npcs.keys()
		all_ids.shuffle()
		for nid in all_ids:
			if selected.size() >= 12:
				break
			var already = false
			for s in selected:
				if s.get("id", "") == nid:
					already = true
					break
			if not already:
				selected.append(all_npcs[nid])

	print("[World] 生成NPC数量: %d" % selected.size())

	for i in range(selected.size()):
		var npc = selected[i]
		_spawn_npc_node(npc, i)


func _spawn_npc_node(npc: Dictionary, index: int) -> void:
	var container := Node3D.new()

	# 角色模型（使用已有模板）
	var npc_color = _get_npc_color(npc)
	var mesh := _create_character_mesh(0, npc_color)
	mesh.scale = Vector3(2.0, 2.0, 2.0)
	container.add_child(mesh)

	# 名字标签（3D文字）
	var label3d = Label3D.new()
	label3d.text = npc.get("name", "?")
	label3d.font_size = 48
	label3d.position = Vector3(0, 4.5, 0)
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.modulate = Color(0.5, 1.0, 0.5)  # 亮绿区分NPC
	container.add_child(label3d)

	# 随机位置（建筑周围散开）
	var angle = (float(index) / 12.0) * TAU + randf_range(-0.3, 0.3)
	var dist = randf_range(15.0, 35.0)
	container.position = Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	# 碰撞和元数据
	_add_character_collision(container)
	container.set_meta("character_id", npc.get("id", ""))
	container.set_meta("is_npc", true)

	characters_node.add_child(container)
	_npc_nodes[npc.get("id", "")] = container
	_character_nodes[npc.get("id", "")] = container


func _get_npc_color(npc: Dictionary) -> Color:
	"""根据NPC来源分配不同颜色"""
	var source = npc.get("source", "")
	var color_map: Dictionary = {
		"凡人修仙传": Color(0.45, 0.7, 1.0),
		"遮天": Color(0.85, 0.45, 0.7),
		"完美世界": Color(0.7, 0.85, 0.35),
		"斗破苍穹": Color(1.0, 0.55, 0.25),
		"盘龙": Color(0.55, 0.55, 1.0),
		"仙逆": Color(0.7, 0.45, 0.9),
		"大主宰": Color(0.9, 0.75, 0.3),
		"一念永恒": Color(0.4, 0.85, 0.7),
		"我欲封天": Color(1.0, 0.7, 0.4),
		"武动乾坤": Color(0.8, 0.6, 0.4),
		"长生界": Color(0.6, 0.7, 0.9),
		"神墓": Color(0.9, 0.45, 0.45),
	}
	return color_map.get(source, Color(0.6, 0.7, 0.85))


# ==================== 自然物生成 ====================

func _generate_nature() -> void:
	# 树木：15种类型随机
	for i in range(tree_count):
		var tree_type := randi() % 15 as int
		var tree_node := _get_tree_model(tree_type)
		if tree_node:
			tree_node.position = Vector3(randf_range(-terrain_size * 0.4, terrain_size * 0.4), 0, randf_range(-terrain_size * 0.4, terrain_size * 0.4))
			tree_node.rotate_y(randf() * TAU)
			var scale = randf_range(1.5, 3.0)
			tree_node.scale = Vector3(scale, scale, scale)
			if abs(tree_node.position.x) < 10 and abs(tree_node.position.z) < 20:
				tree_node.position.x += 15 * (1 if tree_node.position.x > 0 else -1)
			nature.add_child(tree_node)
		else:
			var tree := _create_tree_fallback(tree_type % 3, randf_range(0.6, 1.4))
			tree.position = Vector3(randf_range(-terrain_size * 0.4, terrain_size * 0.4), 0, randf_range(-terrain_size * 0.4, terrain_size * 0.4))
			tree.rotate_y(randf() * TAU)
			if abs(tree.position.x) < 10 and abs(tree.position.z) < 20:
				tree.position.x += 15 * (1 if tree.position.x > 0 else -1)
			nature.add_child(tree)

	# 岩石：10种类型随机
	for i in range(rock_count):
		var rock_type := randi() % 10 as int
		var rock_node := _get_rock_model(rock_type)
		if rock_node:
			rock_node.position = Vector3(randf_range(-terrain_size * 0.35, terrain_size * 0.35), 0, randf_range(-terrain_size * 0.35, terrain_size * 0.35))
			rock_node.rotate_y(randf() * TAU)
			rock_node.scale = Vector3(1.5, 1.5, 1.5)
			nature.add_child(rock_node)
		else:
			var rock := _create_rock_fallback(rock_type % 4, randf_range(0.4, 1.2))
			rock.position = Vector3(randf_range(-terrain_size * 0.35, terrain_size * 0.35), 0, randf_range(-terrain_size * 0.35, terrain_size * 0.35))
			rock.rotate_y(randf() * TAU)
			nature.add_child(rock)

	# 灵石：5个
	for i in range(5):
		var spirit_type := 3 + randi() % 3  # 灵石变体
		var spirit_stone := _get_rock_model(spirit_type)
		if spirit_stone:
			spirit_stone.position = Vector3(randf_range(-terrain_size * 0.3, terrain_size * 0.3), 0.3, randf_range(-terrain_size * 0.3, terrain_size * 0.3))
			spirit_stone.scale = Vector3(2.0, 2.0, 2.0)
			nature.add_child(spirit_stone)
		else:
			var spirit_stone_fallback := _create_rock_fallback(3, 0.8)
			spirit_stone_fallback.position = Vector3(randf_range(-terrain_size * 0.3, terrain_size * 0.3), 0.3, randf_range(-terrain_size * 0.3, terrain_size * 0.3))
			nature.add_child(spirit_stone_fallback)

	# 灵花：8-12朵
	_place_plants_batch("flower_purple", KENNEY_PLANTS + "flower_purple.glb", 4, 0.8)
	_place_plants_batch("flower_red", KENNEY_PLANTS + "flower_red.glb", 4, 0.8)
	_place_plants_batch("flower_yellow", KENNEY_PLANTS + "flower_yellow.glb", 4, 0.8)

	# 灵芝/蘑菇：5-8个
	_place_plants_batch("mushroom", KENNEY_PLANTS + "mushroom_red.glb", 3, 1.2)
	_place_plants_batch("mushroom_group", KENNEY_PLANTS + "mushroom_tan_group.glb", 3, 1.0)
	_place_plants_batch("mushroom_tall", KENNEY_PLANTS + "mushroom_red_tall.glb", 2, 1.0)

	# 莲花：在水边放4朵
	_place_plants_batch("lily", KENNEY_PLANTS + "lily_large.glb", 4, 1.5, Vector3(18, 0.15, 13), 6.0)

	# 灌木：10-15丛
	_place_plants_batch("bush", KENNEY_PLANTS + "bush.glb", 6, 1.5)
	_place_plants_batch("bush_large", KENNEY_PLANTS + "bush_large.glb", 5, 1.8)

	# 草丛：大量
	_place_plants_batch("grass", KENNEY_PLANTS + "grass.glb", 8, 1.0)
	_place_plants_batch("grass_large", KENNEY_PLANTS + "grass_large.glb", 6, 1.2)

	# 营火：在炼丹房和广场各放一个
	_place_single("campfire", KENNEY_PLANTS + "campfire_stones.glb", Vector3(15, 0, 8), 2.0)
	_place_single("campfire2", KENNEY_PLANTS + "campfire_logs.glb", Vector3(-5, 0, -12), 1.5)


func _place_plants_batch(name_prefix: String, model_path: String, count: int, scale: float, center: Vector3 = Vector3.ZERO, radius: float = 0.0) -> void:
	"""批量放置植物类装饰"""
	for i in range(count):
		var node := _load_glb_model(model_path)
		if not node:
			continue
		if radius > 0.0:
			node.position = center + Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius))
		else:
			node.position = Vector3(randf_range(-terrain_size * 0.35, terrain_size * 0.35), 0, randf_range(-terrain_size * 0.35, terrain_size * 0.35))
		node.rotate_y(randf() * TAU)
		node.scale = Vector3(scale, scale, scale)
		nature.add_child(node)


func _place_single(_name: String, model_path: String, pos: Vector3, scale: float) -> void:
	"""放置单个装饰物"""
	var node := _load_glb_model(model_path)
	if node:
		node.position = pos
		node.scale = Vector3(scale, scale, scale)
		nature.add_child(node)


# ==================== 角色生成 ====================

func _spawn_characters() -> void:
	var family = GameManager.get_player_family()
	print("[World] _spawn_characters: family=%s" % str(family))
	if family.is_empty():
		_create_default_characters()
		return

	for member_id in family.get("members", []):
		var character = GameManager.get_character(member_id)
		print("[World] spawning member %s: %s" % [member_id, character.get("name", "?")])
		if character and not character.is_empty() and character.get("is_alive", false):
			_spawn_character_node(character)
		else:
			print("[World] SKIP: character empty or dead")

	if _player_node == null:
		push_warning("[World] ⚠️ _player_node 未设置！请检查角色数据")


func _create_default_characters() -> void:
	var default_positions: Array = [
		Vector3(2, 0, 8),
		Vector3(-3, 0, 5),
		Vector3(0, 0, 0),
	]
	var types: Array = [1, 0, 2]
	var colors: Array = [
		Color(0.9, 0.6, 0.3),
		Color(0.4, 0.7, 1.0),
		Color(0.5, 0.85, 0.4),
	]

	for i in range(3):
		var char_node := Node3D.new()
		var mesh := _create_character_mesh(types[i], colors[i])
		char_node.add_child(mesh)
		char_node.position = default_positions[i]
		char_node.set_meta("character_id", "default_%d" % i)
		characters_node.add_child(char_node)
		_add_character_collision(char_node)
	# 第一个角色设为玩家
		if i == 0 and _player_node == null:
			_player_node = char_node
			_add_player_aura(char_node)


func _spawn_character_node(character: Dictionary) -> void:
	var container := Node3D.new()
	var mesh := _create_character_mesh(_get_character_type(character), _get_character_color(character))
	mesh.scale = Vector3(2.0, 2.0, 2.0)  # 放大2倍
	container.add_child(mesh)
	# 名字标签（3D文字）
	var label3d = Label3D.new()
	label3d.text = character.get("name", "?")
	label3d.font_size = 48
	label3d.position = Vector3(0, 4.5, 0)  # 头顶上方
	label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label3d.modulate = Color(1, 1, 0.6)
	container.add_child(label3d)
	# 放在靠近摄像机的位置
	container.position = Vector3(randf_range(-5, 5), 0, randf_range(15, 25))
	characters_node.add_child(container)
	_add_character_collision(container)
	container.set_meta("character_id", character.get("id", ""))
	_character_nodes[character.get("id", "")] = container
	# 如果是玩家角色（第一代修炼者），设置引用
	if character.get("generation", 0) == 1 and character.get("role", "") == "cultivator":
		_player_node = container
		_add_player_aura(container)
	print("[World] ✅ spawned character '%s' at %s" % [character.get("name", "?"), container.position])


func _get_character_type(character: Dictionary) -> int:
	if character.get("age", 0) > 200:
		return 1
	if character.get("realm_exp", 0) >= 5:
		return 6
	if character.get("role", "") == "alchemist":
		return 5
	return 0


func _get_character_color(character: Dictionary) -> Color:
	var color_map: Dictionary = {
		"fire": Color(1.0, 0.45, 0.2),
		"water": Color(0.3, 0.6, 1.0),
		"wood": Color(0.4, 0.8, 0.3),
		"metal": Color(0.9, 0.9, 0.95),
		"earth": Color(0.85, 0.7, 0.4),
	}
	return color_map.get(character.get("element", ""), Color(0.6, 0.7, 0.85))


# ==================== 回退程序化生成（当GLB加载失败时） ====================

func _create_building_fallback(building_type: int, size: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match building_type:
		0: _add_box_mesh(st, Vector3(0, 1.5, 0), Vector3(2, 3, 0.5) * size)
		1: _add_box_mesh(st, Vector3(0, 2.5, 0), Vector3(4, 5, 3) * size)
		2: _add_box_mesh(st, Vector3(0, 1, 0), Vector3(3, 2, 3) * size)
		3: _add_box_mesh(st, Vector3(0, 3, 0), Vector3(3, 6, 2) * size)
		4: _add_box_mesh(st, Vector3(0, 1.5, 0), Vector3(3, 3, 3) * size)
		5: _add_box_mesh(st, Vector3(0, 2, 0), Vector3(3, 4, 3) * size)
		6: _add_box_mesh(st, Vector3(0, 4, 0), Vector3(2, 8, 2) * size)
		7: _add_box_mesh(st, Vector3(0, 1.5, 0), Vector3(3, 3, 3) * size)
		8: _add_box_mesh(st, Vector3(0, 1.5, 0), Vector3(2, 3, 2) * size)
		_: _add_box_mesh(st, Vector3(0, 2, 0), Vector3(3, 4, 3) * size)

	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.72, 0.50)
	mat.roughness = 0.75
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mesh_instance


func _create_tree_fallback(tree_type: int, size: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match tree_type:
		0: # 松树
			_add_cylinder_mesh(st, Vector3(0, 1.0, 0), 0.15 * size, 2.0 * size)
			_add_cone_mesh(st, Vector3(0, 2.5 * size, 0), 0.8 * size, 1.5 * size)
		1: # 竹子
			_add_cylinder_mesh(st, Vector3(0, 1.5, 0), 0.1 * size, 3.0 * size)
		2: # 柳树
			_add_cylinder_mesh(st, Vector3(0, 1.0, 0), 0.12 * size, 2.0 * size)
			_add_sphere_mesh(st, Vector3(0, 2.5 * size, 0), 1.0 * size)
		_: _add_cone_mesh(st, Vector3(0, 2 * size, 0), 0.7 * size, 2.0 * size)

	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.75, 0.25)
	mat.roughness = 0.9
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	return mesh_instance


func _create_rock_fallback(rock_type: int, size: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	match rock_type:
		0: _add_icosphere_mesh(st, Vector3(0, 0.4 * size, 0), 0.5 * size)
		1: _add_box_mesh(st, Vector3(0, 0.2 * size, 0), Vector3(0.4, 0.4, 0.3) * size)
		2: _add_sphere_mesh(st, Vector3(0, 0.3 * size, 0), 0.4 * size)
		3: # 灵石
			_add_icosphere_mesh(st, Vector3(0, 0.3 * size, 0), 0.3 * size)
		_: _add_box_mesh(st, Vector3(0, 0.3 * size, 0), Vector3(0.5, 0.5, 0.4) * size)

	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var mat := StandardMaterial3D.new()
	if rock_type == 3:
		mat.albedo_color = Color(0.5, 0.95, 1.0)
		mat.emission = Color(0.2, 0.7, 0.9)
		mat.emission_energy_multiplier = 3.0
	else:
		mat.albedo_color = Color(0.70, 0.68, 0.65)
	mat.roughness = 0.9
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	return mesh_instance


func _create_plant(plant_type: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_sphere_mesh(st, Vector3(0, 0.15, 0), 0.15)
	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.5)
	mat.roughness = 0.8
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	return mesh_instance


func _create_character_mesh(char_type: int, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 头部（球形，稍大）
	_add_sphere(st, Vector3(0, 1.7, 0), 0.22, 2)
	# 发髻（头顶小球）
	_add_sphere(st, Vector3(0, 1.95, 0), 0.12, 1)
	# 身体/道袍（上窄下宽的梯形躯干）
	_add_box(st, Vector3(0, 1.2, 0), Vector3(0.35, 0.55, 0.22))
	# 道袍下摆（更宽）
	_add_box(st, Vector3(0, 0.7, 0), Vector3(0.5, 0.45, 0.28))
	# 腿部
	_add_box(st, Vector3(-0.12, 0.3, 0), Vector3(0.1, 0.55, 0.12))
	_add_box(st, Vector3(0.12, 0.3, 0), Vector3(0.1, 0.55, 0.12))
	# 袖子（宽大的左右袖口）
	_add_box(st, Vector3(-0.35, 1.15, 0), Vector3(0.2, 0.25, 0.18))
	_add_box(st, Vector3(0.35, 1.15, 0), Vector3(0.2, 0.25, 0.18))
	# 手臂
	_add_box(st, Vector3(-0.25, 1.05, 0), Vector3(0.08, 0.35, 0.08))
	_add_box(st, Vector3(0.25, 1.05, 0), Vector3(0.08, 0.35, 0.08))

	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.metallic = 0.15
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return mesh_instance


func _add_player_aura(player_node: Node3D) -> void:
	"""给玩家角色添加灵气光效和脚下光环"""
	# 脚下光环
	var ring_mesh := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring_radius := 0.6
	var ring_segments := 32
	for i in range(ring_segments):
		var a1 := (i / float(ring_segments)) * TAU
		var a2 := ((i + 1) / float(ring_segments)) * TAU
		var inner_r := ring_radius - 0.08
		st.add_vertex(Vector3(cos(a1) * ring_radius, 0.05, sin(a1) * ring_radius))
		st.add_vertex(Vector3(cos(a2) * ring_radius, 0.05, sin(a2) * ring_radius))
		st.add_vertex(Vector3(cos(a1) * inner_r, 0.05, sin(a1) * inner_r))
		st.add_vertex(Vector3(cos(a2) * inner_r, 0.05, sin(a2) * inner_r))
		st.add_vertex(Vector3(cos(a1) * inner_r, 0.05, sin(a1) * inner_r))
		st.add_vertex(Vector3(cos(a2) * ring_radius, 0.05, sin(a2) * ring_radius))
	st.generate_normals()
	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.6, 0.9, 1.0, 0.7)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.4, 0.8, 1.0)
	ring_mat.emission_energy = 3.0
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arr_mesh.surface_set_material(0, ring_mat)
	ring_mesh.mesh = arr_mesh
	player_node.add_child(ring_mesh)

	# 头顶境界指示光点
	var glow := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.95, 0.5)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.9, 0.4)
	glow_mat.emission_energy = 4.0
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere.surface_set_material(0, glow_mat)
	glow.mesh = sphere
	glow.position = Vector3(0, 2.3, 0)
	player_node.add_child(glow)


# ==================== 几何辅助 ====================

func _add_box(st: SurfaceTool, center: Vector3, extents: Vector3) -> void:
	var h := extents * 0.5
	var verts := PackedVector3Array([
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z), center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z), center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
	])
	var indices := [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
	for idx in indices:
		st.add_vertex(verts[idx])


func _add_sphere(st: SurfaceTool, center: Vector3, radius: float, subdivisions: int = 1) -> void:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var verts := PackedVector3Array([
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	])
	for i in range(verts.size()):
		verts[i] = verts[i].normalized() * radius + center
	var faces := [0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11, 1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1]
	for i in range(0, faces.size(), 3):
		st.add_vertex(verts[faces[i]])
		st.add_vertex(verts[faces[i+1]])
		st.add_vertex(verts[faces[i+2]])


func _add_box_mesh(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var verts := PackedVector3Array([
		center + Vector3(-h.x,-h.y,-h.z), center + Vector3(h.x,-h.y,-h.z),
		center + Vector3(h.x,-h.y,h.z), center + Vector3(-h.x,-h.y,h.z),
		center + Vector3(-h.x,h.y,-h.z), center + Vector3(h.x,h.y,-h.z),
		center + Vector3(h.x,h.y,h.z), center + Vector3(-h.x,h.y,h.z),
	])
	var idx := [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
	for i in idx:
		st.add_vertex(verts[i])


func _add_cylinder_mesh(st: SurfaceTool, center: Vector3, radius: float, height: float) -> void:
	var sides := 8
	var half_h := height * 0.5
	for i in range(sides):
		var a1 := (float(i) / sides) * TAU
		var a2 := (float(i + 1) / sides) * TAU
		var v1 := center + Vector3(cos(a1) * radius, half_h, sin(a1) * radius)
		var v2 := center + Vector3(cos(a2) * radius, half_h, sin(a2) * radius)
		var v3 := center + Vector3(cos(a2) * radius, -half_h, sin(a2) * radius)
		var v4 := center + Vector3(cos(a1) * radius, -half_h, sin(a1) * radius)
		st.add_vertex(v1); st.add_vertex(v2); st.add_vertex(v3)
		st.add_vertex(v1); st.add_vertex(v3); st.add_vertex(v4)


func _add_cone_mesh(st: SurfaceTool, center: Vector3, radius: float, height: float) -> void:
	var sides := 8
	var top := center + Vector3(0, height, 0)
	for i in range(sides):
		var a1 := (float(i) / sides) * TAU
		var a2 := (float(i + 1) / sides) * TAU
		var v1 := center + Vector3(0, 0, 0)
		var v2 := center + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var v3 := center + Vector3(cos(a2) * radius, 0, sin(a2) * radius)
		var v4 := top
		var v5 := center + Vector3(cos(a1) * radius, 0, sin(a1) * radius)
		var v6 := center + Vector3(cos(a2) * radius, 0, sin(a2) * radius)
		st.add_vertex(v1); st.add_vertex(v2); st.add_vertex(v3)
		st.add_vertex(v4); st.add_vertex(v5); st.add_vertex(v6)


func _add_sphere_mesh(st: SurfaceTool, center: Vector3, radius: float) -> void:
	_add_sphere(st, center, radius, 1)


func _add_icosphere_mesh(st: SurfaceTool, center: Vector3, radius: float) -> void:
	_add_sphere(st, center, radius, 0)


# ==================== 相机 ====================

# 相机跟随参数
var _camera_offset: Vector3 = Vector3(0, 25, 25)  # 相机相对玩家的偏移
var _camera_look_ahead: float = 5.0  # 相机看向玩家前方距离
var _camera_smoothing: float = 5.0  # 相机跟随平滑速度

func _setup_camera() -> void:
	# 初始相机位置：跟随玩家
	if _player_node:
		camera.position = _player_node.position + _camera_offset
		camera.look_at(_player_node.position + Vector3(0, 0, _camera_look_ahead), Vector3.UP)
	else:
		camera.position = Vector3(0, 25, 30)
		camera.look_at(Vector3(0, 0, 5), Vector3.UP)


# ==================== 输入控制 ====================

func _unhandled_input(event: InputEvent) -> void:
	# 滚轮缩放（移到 _input 由 main_scene 处理）
	pass


func _process(delta: float) -> void:
	# 平滑移动角色到目标位置
	if _is_moving and _player_node:
		var current = _player_node.position
		var direction = _move_target - current
		direction.y = 0  # 保持在地面高度
		var distance = direction.length()
		if distance < 0.3:
			_player_node.position.x = _move_target.x
			_player_node.position.z = _move_target.z
			_is_moving = false
		else:
			# 角色朝向移动方向
			_player_node.look_at(Vector3(_move_target.x, _player_node.position.y, _move_target.z), Vector3.UP)
			var step = _move_speed * delta
			_player_node.position += direction.normalized() * step

	# 相机跟随玩家（人物始终在画面中心）
	if _player_node and camera:
		var target_cam_pos = _player_node.position + _camera_offset
		camera.position = camera.position.lerp(target_cam_pos, _camera_smoothing * delta)
		camera.look_at(_player_node.position + Vector3(0, 0, _camera_look_ahead), Vector3.UP)


func _raycast_ground(screen_pos: Vector2) -> Vector3:
	"""从屏幕坐标射线检测地面(y=0)交点"""
	if not camera:
		return Vector3.INF

	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)

	# 计算与 y=0 平面的交点
	if abs(ray_dir.y) < 0.001:
		return Vector3.INF

	var t = -ray_origin.y / ray_dir.y
	if t < 0:
		return Vector3.INF

	var hit_pos = ray_origin + ray_dir * t
	# 限制在地图范围内
	hit_pos.x = clampf(hit_pos.x, -terrain_size * 0.45, terrain_size * 0.45)
	hit_pos.z = clampf(hit_pos.z, -terrain_size * 0.45, terrain_size * 0.45)
	hit_pos.y = 0
	return hit_pos


func _move_player_to(target_pos: Vector3) -> void:
	"""移动玩家角色到指定位置"""
	_move_target = target_pos
	_is_moving = true
	# 显示移动目标指示（可选）


func raycast_objects(screen_pos: Vector2) -> Dictionary:
	"""从屏幕坐标射线检测，返回命中的建筑/角色信息"""
	if not camera:
		return {}
	var space_state = get_world_3d().direct_space_state
	var ray_origin = camera.project_ray_origin(screen_pos)
	var ray_end = ray_origin + camera.project_ray_normal(screen_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 6  # 0b110: layer2(buildings) + layer3(characters)
	var result = space_state.intersect_ray(query)
	if result.is_empty():
		return {}
	var collider = result["collider"]
	# 向上遍历找带meta的节点
	var node = collider
	while node:
		if node.has_meta("building_name"):
			return {"type": "building", "name": node.get_meta("building_name"), "node": node, "position": result["position"]}
		if node.has_meta("character_id"):
			return {"type": "character", "id": node.get_meta("character_id"), "node": node, "position": result["position"]}
		node = node.get_parent()
	return {}


func move_player_from_screen(screen_pos: Vector2) -> bool:
	"""从屏幕坐标移动玩家（供外部调用）"""
	if not _player_node:
		return false
	var target_pos = _raycast_ground(screen_pos)
	if target_pos != Vector3.INF:
		_move_player_to(target_pos)
		return true
	return false


func _zoom_camera(amount: float) -> void:
	if not camera:
		return
	var new_y = _camera_offset.y + amount
	new_y = clampf(new_y, _camera_min_height, _camera_max_height)
	_camera_offset.y = new_y
	# 同步调整前后偏移，保持视角一致
	_camera_offset.z = new_y  # z偏移 = y偏移，保持约45度俯角


func get_character_node(character_id: String) -> Node3D:
	return _character_nodes.get(character_id)


func get_building_node(building_name: String) -> Node3D:
	return _building_nodes.get(building_name)


func update_character_position(character_id: String, pos: Vector3) -> void:
	var node = get_character_node(character_id)
	if node:
		node.position = pos


func remove_character_node(character_id: String) -> void:
	var node = _character_nodes.get(character_id)
	if node:
		node.queue_free()
		_character_nodes.erase(character_id)


func show_effect(effect_type: int, position: Vector3, size: float = 1.0, color_key: String = "qi_blue") -> void:
	var effect := _create_effect_mesh(effect_type, size, color_key)
	effect.position = position
	effects.add_child(effect)
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(effect.queue_free)


func _create_effect_mesh(effect_type: int, size: float, color_key: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_sphere(st, Vector3(0, 0, 0), 0.5 * size, 1)
	st.generate_normals()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var color_map: Dictionary = {
		"qi_blue": Color(0.4, 0.7, 1.0),
		"fire": Color(1.0, 0.5, 0.15),
		"wood": Color(0.4, 0.85, 0.3),
		"gold": Color(1.0, 0.9, 0.3),
	}
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_map.get(color_key, Color(0.3, 0.6, 0.9))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 3.0
	array_mesh.surface_set_material(0, mat)
	mesh_instance.mesh = array_mesh
	return mesh_instance


func update_time_of_day(hour: float) -> void:
	var angle = (hour / 24.0) * 360.0 - 90.0
	lighting.rotation_degrees.x = angle
	var intensity := clampf(sin(hour / 24.0 * PI), 0.1, 1.0)
	lighting.light_energy = intensity

	if hour < 6 or hour > 20:
		environment.environment.ambient_light_color = Color(0.08, 0.08, 0.20)
	elif hour < 8 or hour > 18:
		environment.environment.ambient_light_color = Color(0.25, 0.18, 0.15)
	else:
		environment.environment.ambient_light_color = Color(0.55, 0.55, 0.60)
