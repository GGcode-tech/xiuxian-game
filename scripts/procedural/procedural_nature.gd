## 程序化自然生成器 - 仙侠风格自然物体
## 生成树木、岩石、花草等

class_name ProceduralNature
extends Node

# 树木类型
enum TreeType {
	PINE,         # 松树
	BAMBOO,       # 竹子
	WILLOW,       # 柳树
	PEACH,        # 桃树
	PAGODA_TREE,  # 国槐
	GINKGO,       # 银杏
	SPIRIT_TREE,  # 灵树
}

# 岩石类型
enum RockType {
	BOULDER,      # 巨石
	CLIFF,        # 峭壁
	STEPPING,     # 踏脚石
	SPIRIT_STONE, # 灵石
	TAIHU,        # 太湖石
}

# 花草类型
enum PlantType {
	GRASS,        # 草丛
	LOTUS,        # 荷花
	PLUM,         # 梅花
	BAMBOO_LEAF,  # 竹叶
	SPIRIT_HERB,  # 灵草
}

# 生成树木
static func generate_tree(tree_type: TreeType, size: float = 1.0) -> MeshInstance3D:
	match tree_type:
		TreeType.PINE:
			return _generate_pine(size)
		TreeType.BAMBOO:
			return _generate_bamboo(size)
		TreeType.WILLOW:
			return _generate_willow(size)
		TreeType.PEACH:
			return _generate_peach(size)
		TreeType.PAGODA_TREE:
			return _generate_pagoda_tree(size)
		TreeType.GINKGO:
			return _generate_ginkgo(size)
		TreeType.SPIRIT_TREE:
			return _generate_spirit_tree(size)
		_:
			return _generate_pine(size)

# 生成岩石
static func generate_rock(rock_type: RockType, size: float = 1.0) -> MeshInstance3D:
	match rock_type:
		RockType.BOULDER:
			return _generate_boulder(size)
		RockType.CLIFF:
			return _generate_cliff(size)
		RockType.STEPPING:
			return _generate_stepping(size)
		RockType.SPIRIT_STONE:
			return _generate_spirit_stone(size)
		RockType.TAIHU:
			return _generate_taihu(size)
		_:
			return _generate_boulder(size)

# 生成花草
static func generate_plant(plant_type: PlantType, size: float = 1.0) -> MeshInstance3D:
	match plant_type:
		PlantType.GRASS:
			return _generate_grass(size)
		PlantType.LOTUS:
			return _generate_lotus(size)
		PlantType.PLUM:
			return _generate_plum(size)
		PlantType.BAMBOO_LEAF:
			return _generate_bamboo_leaf(size)
		PlantType.SPIRIT_HERB:
			return _generate_spirit_herb(size)
		_:
			return _generate_grass(size)

# ===== 树木生成 =====

# 松树
static func _generate_pine(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 树干
	_add_box(st, Vector3(0, 1.0, 0) * size, Vector3(0.25, 2.0, 0.25) * size)

	# 层叠树冠 (松塔形)
	for i in range(4):
		var y := 2.5 + i * 0.8
		var scale := 1.5 - i * 0.3
		_add_cone(st, Vector3(0, y, 0) * size, scale * size, 1.2 * size, false, 8)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.25)
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 竹子
static func _generate_bamboo(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 竹竿 (多节)
	var segments := 5
	for i in range(segments):
		var y := i * 0.6 + 0.5
		_add_cylinder(st, Vector3(0, y, 0) * size, 0.12 * size, 0.5 * size, 6)
		# 节环
		_add_cylinder(st, Vector3(0, y + 0.28, 0) * size, 0.14 * size, 0.04 * size, 6)

	# 竹叶
	for i in range(3):
		var angle := TAU * i / 3
		var base := Vector3(cos(angle), 3.2, sin(angle)) * size
		_add_leaf(st, base, 0.4 * size, angle + PI/2)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.65, 0.35)
	mat.roughness = 0.7
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 柳树
static func _generate_willow(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 弯曲树干
	_add_cylinder(st, Vector3(0, 1.5, 0) * size, 0.3 * size, 3.0 * size, 8)

	# 树冠
	_add_sphere(st, Vector3(0, 3.5, 0) * size, 1.0 * size, 1)
	_add_sphere(st, Vector3(0.4, 3.3, 0.3) * size, 0.6 * size, 1)
	_add_sphere(st, Vector3(-0.4, 3.3, 0.3) * size, 0.6 * size, 1)

	# 下垂的柳条
	for i in range(12):
		var angle := TAU * i / 12
		var base := Vector3(cos(angle) * 0.8, 3.2, sin(angle) * 0.8) * size
		_add_willow_branch(st, base, 1.5 * size, angle)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.6, 0.35)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 桃树
static func _generate_peach(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 树干
	_add_cylinder(st, Vector3(0, 1.0, 0) * size, 0.2 * size, 2.0 * size, 6)

	# 枝干
	_add_box(st, Vector3(0.5, 2.2, 0) * size, Vector3(1.0, 0.15, 0.15) * size)
	_add_box(st, Vector3(-0.4, 2.0, 0.3) * size, Vector3(0.8, 0.12, 0.12) * size)

	# 花冠 (粉色)
	_add_sphere(st, Vector3(0.8, 2.8, 0) * size, 0.8 * size, 1)
	_add_sphere(st, Vector3(-0.6, 2.6, 0.4) * size, 0.7 * size, 1)
	_add_sphere(st, Vector3(0, 2.9, -0.3) * size, 0.6 * size, 1)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	# 分离材质：树干棕色+花冠粉色
	var mat_wood := StandardMaterial3D.new()
	mat_wood.albedo_color = Color(0.4, 0.3, 0.2)
	mat_wood.roughness = 0.9
	mesh.surface_set_material(0, mat_wood)

	instance.mesh = mesh
	return instance

# 国槐
static func _generate_pagoda_tree(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 粗壮树干
	_add_cylinder(st, Vector3(0, 1.5, 0) * size, 0.4 * size, 3.0 * size, 8)

	# 伞形树冠
	_add_dome(st, Vector3(0, 4.0, 0) * size, 2.5 * size, 2.0 * size, 12, 4)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.55, 0.3)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 银杏
static func _generate_ginkgo(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 树干
	_add_cylinder(st, Vector3(0, 1.5, 0) * size, 0.35 * size, 3.0 * size, 8)

	# 扇形树冠 (用多个椭球)
	var colors := [Color(0.9, 0.85, 0.2), Color(0.95, 0.9, 0.3), Color(0.85, 0.8, 0.15)]
	for i in range(6):
		var angle := TAU * i / 6
		var pos := Vector3(cos(angle) * 1.2, 4.0 + randf_range(0, 0.5), sin(angle) * 1.2) * size
		_add_sphere(st, pos, randf_range(0.6, 0.9) * size, 1)

	_add_sphere(st, Vector3(0, 4.5, 0) * size, 1.2 * size, 1)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.2)  # 金黄色
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 灵树 (发光的神秘树)
static func _generate_spirit_tree(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 扭曲的发光树干
	_add_cylinder(st, Vector3(0, 1.5, 0) * size, 0.25 * size, 3.0 * size, 6)

	# 发光球体树冠
	_add_sphere(st, Vector3(0, 3.8, 0) * size, 1.2 * size, 1)
	_add_sphere(st, Vector3(0.6, 3.5, 0.4) * size, 0.7 * size, 1)
	_add_sphere(st, Vector3(-0.5, 3.6, -0.3) * size, 0.6 * size, 1)

	# 悬浮的能量结晶
	_add_icosphere(st, Vector3(1.0, 4.2, 0) * size, 0.15 * size, 1)
	_add_icosphere(st, Vector3(-0.8, 4.5, 0.5) * size, 0.12 * size, 1)
	_add_icosphere(st, Vector3(0, 4.8, -0.6) * size, 0.13 * size, 1)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.8)  # 青绿发光
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.8, 0.6)
	mat.emission_energy = 0.5
	mat.roughness = 0.3
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# ===== 岩石生成 =====

# 巨石
static func _generate_boulder(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 不规则多边形
	var seed_val := randi()
	var noise_scale := 0.8 + randf() * 0.4

	_add_dodecahedron(st, Vector3(0, 0.5, 0) * size, size * noise_scale)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.52)
	mat.roughness = 0.95
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 峭壁
static func _generate_cliff(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 不规则峭壁
	_add_box(st, Vector3(0, 1.5, 0) * size, Vector3(2.0, 3.0, 1.5) * size)
	_add_box(st, Vector3(0.5, 2.8, 0.6) * size, Vector3(1.2, 0.8, 0.4) * size)
	_add_box(st, Vector3(-0.6, 1.2, -0.4) * size, Vector3(0.8, 1.5, 0.6) * size)
	_add_box(st, Vector3(0.3, 0.6, -0.5) * size, Vector3(1.5, 0.8, 0.5) * size)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.42, 0.4)
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 踏脚石
static func _generate_stepping(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 扁平石头
	_add_cylinder(st, Vector3(0, 0.1, 0) * size, 0.5 * size, 0.2 * size, 6)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.52, 0.5)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 灵石
static func _generate_spirit_stone(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 晶体形状
	_add_octahedron(st, Vector3(0, 0.4, 0) * size, size * 0.5)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.7, 1.0)  # 蓝色灵石
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.5, 0.8)
	mat.emission_energy = 0.8
	mat.roughness = 0.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 太湖石
static func _generate_taihu(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 多孔形状
	_add_dodecahedron(st, Vector3(0, 1.0, 0) * size, size * 0.6)
	_add_dodecahedron(st, Vector3(0.3, 0.5, 0.2) * size, size * 0.4)
	_add_dodecahedron(st, Vector3(-0.2, 1.4, -0.1) * size, size * 0.35)
	_add_dodecahedron(st, Vector3(0.1, 0.8, -0.3) * size, size * 0.3)
	_add_icosphere(st, Vector3(-0.5, 1.2, 0.3) * size, size * 0.25, 1)
	_add_icosphere(st, Vector3(0.4, 1.6, -0.2) * size, size * 0.2, 1)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.82)
	mat.roughness = 0.7
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# ===== 花草生成 =====

# 草丛
static func _generate_grass(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 多个草叶
	for i in range(6):
		var angle := TAU * i / 6 + randf_range(-0.2, 0.2)
		var x := cos(angle) * 0.1
		var z := sin(angle) * 0.1
		_add_grass_blade(st, Vector3(x, 0, z) * size, (0.3 + randf() * 0.2) * size, angle)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.6, 0.25)
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 荷花
static func _generate_lotus(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 花瓣
	for i in range(8):
		var angle := TAU * i / 8
		_add_lotus_petal(st, Vector3(0, 0.3, 0) * size, size * 0.3, angle)

	# 花心
	_add_sphere(st, Vector3(0, 0.35, 0) * size, 0.08 * size, 1)

	# 茎
	_add_cylinder(st, Vector3(0, -0.2, 0) * size, 0.03 * size, 0.6 * size, 6)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.9)  # 粉白色
	mat.roughness = 0.6
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 梅花
static func _generate_plum(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 枝干
	_add_box(st, Vector3(0, 0.3, 0) * size, Vector3(0.4, 0.05, 0.05) * size)
	_add_box(st, Vector3(0.1, 0.5, 0) * size, Vector3(0.03, 0.25, 0.03) * size)

	# 花朵
	for i in range(3):
		var pos := Vector3(randf_range(-0.2, 0.3), 0.35 + i * 0.12, randf_range(-0.05, 0.05)) * size
		_add_flower_head(st, pos, size * 0.08)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.75, 0.8)  # 粉红
	mat.roughness = 0.7
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 竹叶
static func _generate_bamboo_leaf(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 几片竹叶
	for i in range(4):
		var angle := TAU * i / 4
		_add_leaf(st, Vector3(0, 0.1, 0) * size, 0.15 * size, angle)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.65, 0.35)
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# 灵草
static func _generate_spirit_herb(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 茎
	_add_box(st, Vector3(0, 0.15, 0) * size, Vector3(0.02, 0.3, 0.02) * size)

	# 叶片
	for i in range(4):
		var angle := TAU * i / 4
		_add_leaf(st, Vector3(0, 0.25, 0) * size, 0.12 * size, angle)

	# 发光果实
	_add_icosphere(st, Vector3(0, 0.35, 0) * size, 0.05 * size, 1)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.5)  # 亮绿色
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 0.3)
	mat.emission_energy = 0.6
	mat.roughness = 0.5
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	return instance

# ===== 几何工具 =====

static func _add_box(st: SurfaceTool, center: Vector3, extents: Vector3) -> void:
	var h := extents * 0.5
	var verts := PackedVector3Array([
		center + Vector3(-h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z),
		center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z),
		center + Vector3(-h.x, h.y, h.z),
	])
	var indices := [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
	for i in indices:
		st.add_vertex(verts[i])

static func _add_cylinder(
		st: SurfaceTool, center: Vector3,
		radius: float, height: float,
		segments: int = 12
	) -> void:
	var h := height * 0.5
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		var c1 := cos(a1) * radius
		var s1 := sin(a1) * radius
		var c2 := cos(a2) * radius
		var s2 := sin(a2) * radius
		st.add_vertex(center + Vector3(c1, -h, s1))
		st.add_vertex(center + Vector3(c2, -h, s2))
		st.add_vertex(center + Vector3(c1, h, s1))
		st.add_vertex(center + Vector3(c2, -h, s2))
		st.add_vertex(center + Vector3(c2, h, s2))
		st.add_vertex(center + Vector3(c1, h, s1))

static func _add_cone(
		st: SurfaceTool, apex: Vector3,
		radius: float, height: float,
		_hollow: bool, segments: int = 8
	) -> void:
	var base_y := apex.y - height
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		var c1 := cos(a1) * radius
		var s1 := sin(a1) * radius
		var c2 := cos(a2) * radius
		var s2 := sin(a2) * radius
		st.add_vertex(apex)
		st.add_vertex(Vector3(c1, base_y, s1) + Vector3(apex.x, 0, apex.z))
		st.add_vertex(Vector3(c2, base_y, s2) + Vector3(apex.x, 0, apex.z))

static func _add_sphere(
		st: SurfaceTool, center: Vector3,
		radius: float, _subdivisions: int = 1
	) -> void:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var verts := PackedVector3Array([
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 9), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	])
	for i in range(verts.size()):
		verts[i] = verts[i].normalized() * radius + center
	var faces := [
		0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11,
		1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8,
		3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9,
		4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1
	]
	for i in range(0, faces.size(), 3):
		st.add_vertex(verts[faces[i]])
		st.add_vertex(verts[faces[i+1]])
		st.add_vertex(verts[faces[i+2]])

static func _add_dome(
		st: SurfaceTool, center: Vector3,
		radius: float, height: float,
		segments: int = 8, rings: int = 4
	) -> void:
	for ring in range(rings):
		var r1 := float(ring) / rings
		var r2 := float(ring + 1) / rings
		var y1 := sin(PI * 0.5 * r1) * height
		var y2 := sin(PI * 0.5 * r2) * height
		var rad1 := cos(PI * 0.5 * r1) * radius
		var rad2 := cos(PI * 0.5 * r2) * radius
		for seg in range(segments):
			var a1 := TAU * seg / segments
			var a2 := TAU * (seg + 1) / segments
			var p1 := center + Vector3(cos(a1) * rad1, y1, sin(a1) * rad1)
			var p2 := center + Vector3(cos(a2) * rad1, y1, sin(a2) * rad1)
			var p3 := center + Vector3(cos(a1) * rad2, y2, sin(a1) * rad1)
			var p4 := center + Vector3(cos(a2) * rad2, y2, sin(a2) * rad2)
			st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)
			st.add_vertex(p2); st.add_vertex(p4); st.add_vertex(p3)

static func _add_icosphere(
		st: SurfaceTool, center: Vector3,
		radius: float, _subdivisions: int = 1
	) -> void:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var verts := PackedVector3Array([
		Vector3(-1, phi, 0), Vector3(1, phi, 0), Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi), Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1), Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	])
	for i in range(verts.size()):
		verts[i] = verts[i].normalized() * radius + center
	var faces := [
		0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11,
		1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8,
		3,9,4, 3,4,2, 3,2,6, 3,6,8, 3,8,9,
		4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1
	]
	for i in range(0, faces.size(), 3):
		st.add_vertex(verts[faces[i]])
		st.add_vertex(verts[faces[i+1]])
		st.add_vertex(verts[faces[i+2]])

static func _add_dodecahedron(st: SurfaceTool, center: Vector3, radius: float) -> void:
	var phi := (1.0 + sqrt(5.0)) / 2.0
	var inv_phi := 1.0 / phi
	var verts := PackedVector3Array([
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(1, -1, -1),
		Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, 1), Vector3(-1, -1, -1),
		Vector3(0, inv_phi, phi), Vector3(0, inv_phi, -phi),
		Vector3(0, -inv_phi, phi), Vector3(0, -inv_phi, -phi),
		Vector3(inv_phi, phi, 0), Vector3(inv_phi, -phi, 0),
		Vector3(-inv_phi, phi, 0), Vector3(-inv_phi, -phi, 0),
		Vector3(phi, 0, inv_phi), Vector3(phi, 0, -inv_phi),
		Vector3(-phi, 0, inv_phi), Vector3(-phi, 0, -inv_phi),
	])
	for i in range(verts.size()):
		verts[i] = verts[i].normalized() * radius + center
	# 12个五边形面（简化为三角形）
	var faces := [
		0,8,10, 0,10,2, 0,2,16, 0,16,17, 0,17,8,
		1,9,11, 1,11,3, 1,3,17, 1,17,16, 1,16,9,
		4,8,9, 4,9,5, 4,5,15, 4,15,14, 4,14,8,
		6,10,11, 6,11,7, 6,7,19, 6,19,18, 6,18,10,
	]
	for i in range(0, faces.size(), 3):
		st.add_vertex(verts[faces[i]])
		st.add_vertex(verts[faces[i+1]])
		st.add_vertex(verts[faces[i+2]])

static func _add_octahedron(st: SurfaceTool, center: Vector3, radius: float) -> void:
	var verts := PackedVector3Array([
		center + Vector3(0, radius * 1.5, 0),
		center + Vector3(0, -radius * 0.5, 0),
		center + Vector3(radius, 0.5, 0),
		center + Vector3(-radius, 0.5, 0),
		center + Vector3(0, 0.5, radius),
		center + Vector3(0, 0.5, -radius),
	])
	var faces := [0,2,4, 0,4,3, 0,3,5, 0,5,2, 1,4,2, 1,3,4, 1,5,3, 1,2,5]
	for i in range(0, faces.size(), 3):
		st.add_vertex(verts[faces[i]])
		st.add_vertex(verts[faces[i+1]])
		st.add_vertex(verts[faces[i+2]])

static func _add_leaf(st: SurfaceTool, base: Vector3, length: float, rotation: float) -> void:
	var tip := base + Vector3(cos(rotation) * length, length * 0.3, sin(rotation) * length)
	var mid_x := cos(rotation) * length * 0.5
	var mid_s := sin(rotation) * length * 0.5
	var mid := base + Vector3(mid_x, length * 0.15, mid_s)
	var w := length * 0.2
	st.add_vertex(base + Vector3(cos(rotation + PI/2) * w, 0, sin(rotation + PI/2) * w))
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(cos(rotation - PI/2) * w, 0, sin(rotation - PI/2) * w))

static func _add_grass_blade(
		st: SurfaceTool, base: Vector3,
		height: float, rotation: float
	) -> void:
	var tip := base + Vector3(0, height, 0)
	var w := height * 0.1
	st.add_vertex(base + Vector3(cos(rotation + PI/2) * w, 0, sin(rotation + PI/2) * w))
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(cos(rotation - PI/2) * w, 0, sin(rotation - PI/2) * w))

static func _add_willow_branch(
		st: SurfaceTool, base: Vector3,
		length: float, rotation: float
	) -> void:
	var segments := 5
	for i in range(segments):
		var t1 := float(i) / segments
		var t2 := float(i + 1) / segments
		var y1 := -length * t1 * t1  # 下垂曲线
		var y2 := -length * t2 * t2
		var x1 := cos(rotation) * length * t1
		var x2 := cos(rotation) * length * t2
		var z1 := sin(rotation) * length * t1
		var z2 := sin(rotation) * length * t2
		st.add_vertex(base + Vector3(x1, y1, z1))
		st.add_vertex(base + Vector3(x2, y2, z2))
		st.add_vertex(base + Vector3(x1 + 0.02, y1, z1 + 0.02))

static func _add_lotus_petal(st: SurfaceTool, center: Vector3, size: float, angle: float) -> void:
	var base := center + Vector3(cos(angle) * size * 0.5, 0, sin(angle) * size * 0.5)
	var tip := center + Vector3(cos(angle) * size * 1.2, size * 0.6, sin(angle) * size * 1.2)
	var w := size * 0.3
	st.add_vertex(base + Vector3(cos(angle + PI/2) * w, 0, sin(angle + PI/2) * w))
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(cos(angle - PI/2) * w, 0, sin(angle - PI/2) * w))

static func _add_flower_head(st: SurfaceTool, center: Vector3, size: float) -> void:
	for i in range(5):
		var a := TAU * i / 5
		var tip := center + Vector3(cos(a) * size, size * 0.5, sin(a) * size)
		st.add_vertex(center)
		st.add_vertex(tip)
		st.add_vertex(center + Vector3(cos(a + 0.6) * size * 0.8, size * 0.4, sin(a + 0.6) * size * 0.8))
