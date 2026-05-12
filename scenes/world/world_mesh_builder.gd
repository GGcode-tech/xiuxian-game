## WorldMeshBuilder - 程序化网格构建辅助类
## 从world.gd拆分出来的网格生成函数
class_name WorldMeshBuilder
extends RefCounted


# ==================== 回退程序化生成（当GLB加载失败时） ====================

func create_building_fallback(building_type: int, size: float) -> MeshInstance3D:
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


func create_tree_fallback(tree_type: int, size: float) -> MeshInstance3D:
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


func create_rock_fallback(rock_type: int, size: float) -> MeshInstance3D:
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


func create_plant(_plant_type: int) -> MeshInstance3D:
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


func create_character_mesh(_char_type: int, color: Color) -> MeshInstance3D:
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


func create_player_aura(player_node: Node3D) -> void:
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


func create_effect_mesh(_effect_type: int, size: float, color_key: String) -> MeshInstance3D:
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


func _add_sphere(st: SurfaceTool, center: Vector3, radius: float, _subdivisions: int = 1) -> void:
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
