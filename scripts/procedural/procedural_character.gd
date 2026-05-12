## 程序化角色生成器 - 低多边形修仙角色
## 生成各种NPC和角色模型

class_name ProceduralCharacter
extends Node

# 角色类型
enum CharacterType {
	CULTIVATOR,   # 修士
	ELDER,        # 长老
	DISCIPLE,     # 弟子
	VILLAGER,     # 村民
	GUARDIAN,     # 守卫
	ALCHEMIST,    # 炼丹师
	SWORDSMAN,    # 剑修
	ELDER_MONK,   # 老僧
}

# 生成角色
static func generate(
		char_type: CharacterType,
		color_secondary: Color = Color(0.5, 0.3, 0.2)
	) -> MeshInstance3D:
	match char_type:
		CharacterType.CULTIVATOR:
			return _generate_cultivator(color_secondary)
		CharacterType.ELDER:
			return _generate_elder(color_secondary)
		CharacterType.DISCIPILE:
			return _generate_disciple(color_secondary)
		CharacterType.VILLAGER:
			return _generate_villager()
		CharacterType.GUARDIAN:
			return _generate_guardian()
		CharacterType.ALCHEMIST:
			return _generate_alchemist()
		CharacterType.SWORDSMAN:
			return _generate_swordsman()
		CharacterType.ELDER_MONK:
			return _generate_elder_monk()
		_:
			return _generate_cultivator(color_secondary)

# 通用角色生成
static func _generate_base_character(body_color: Color, height: float = 1.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 头部
	_add_sphere(st, Vector3(0, 1.6, 0) * height, 0.2 * height, 1)

	# 躯干
	_add_box(st, Vector3(0, 1.2, 0) * height, Vector3(0.35, 0.5, 0.2) * height)

	# 腿
	_add_box(st, Vector3(-0.1, 0.45, 0) * height, Vector3(0.12, 0.6, 0.15) * height)
	_add_box(st, Vector3(0.1, 0.45, 0) * height, Vector3(0.12, 0.6, 0.15) * height)

	# 手臂
	_add_box(st, Vector3(-0.28, 1.1, 0) * height, Vector3(0.1, 0.4, 0.1) * height)
	_add_box(st, Vector3(0.28, 1.1, 0) * height, Vector3(0.1, 0.4, 0.1) * height)

	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)

	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

# 修士
static func _generate_cultivator(robe_color: Color) -> MeshInstance3D:
	var instance := _generate_base_character(robe_color)
	# 添加道袍下摆
	_add_robe_bottom(instance, robe_color)
	# 发髻
	_add_topknot(instance, Color(0.1, 0.08, 0.05))
	return instance

# 长老
static func _generate_elder(robe_color: Color) -> MeshInstance3D:
	var instance := _generate_base_character(robe_color, 0.95)  # 稍矮
	# 长袍
	_add_long_robe(instance, robe_color)
	# 白发
	_add_long_hair(instance, Color(0.95, 0.95, 0.9))
	# 胡须
	_add_beard(instance)
	return instance

# 弟子
static func _generate_disciple(robe_color: Color) -> MeshInstance3D:
	var instance := _generate_base_character(robe_color, 0.85)  # 较矮年轻
	_add_robe_bottom(instance, robe_color)
	_add_topknot(instance, Color(0.15, 0.1, 0.05))
	return instance

# 村民
static func _generate_villager() -> MeshInstance3D:
	var instance := _generate_base_character(Color(0.5, 0.4, 0.35), 0.9)
	_add_robe_bottom(instance, Color(0.4, 0.35, 0.3))
	return instance

# 守卫
static func _generate_guardian() -> MeshInstance3D:
	var instance := _generate_base_character(Color(0.3, 0.35, 0.4))
	# 护甲
	_add_armor(instance, Color(0.4, 0.4, 0.45))
	# 头盔
	_add_helmet(instance, Color(0.5, 0.5, 0.55))
	return instance

# 炼丹师
static func _generate_alchemist() -> MeshInstance3D:
	var instance := _generate_base_character(Color(0.6, 0.4, 0.3))
	_add_long_robe(instance, Color(0.5, 0.6, 0.5))  # 浅绿袍
	_add_topknot(instance, Color(0.2, 0.15, 0.1))
	return instance

# 剑修
static func _generate_swordsman() -> MeshInstance3D:
	var instance := _generate_base_character(Color(0.25, 0.25, 0.35))
	# 窄袖
	_add_robe_bottom(instance, Color(0.2, 0.2, 0.3))
	# 高马尾
	_add_topknot(instance, Color(0.1, 0.08, 0.05), true)
	# 剑
	_add_sword(instance)
	return instance

# 老僧
static func _generate_elder_monk() -> MeshInstance3D:
	var instance := _generate_base_character(Color(0.75, 0.6, 0.4), 0.9)
	_add_long_robe(instance, Color(0.8, 0.65, 0.45))
	# 光头已在基础模型
	return instance

# ===== 装饰组件 =====

static func _add_robe_bottom(instance: MeshInstance3D, color: Color) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 下摆
	_add_box(st, Vector3(0, 0.25, 0), Vector3(0.5, 0.3, 0.35))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_long_robe(instance: MeshInstance3D, color: Color) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 长袍下摆到脚
	_add_box(st, Vector3(0, 0.35, 0), Vector3(0.55, 0.5, 0.45))
	# 大袖
	_add_box(st, Vector3(-0.35, 1.0, 0), Vector3(0.25, 0.35, 0.15))
	_add_box(st, Vector3(0.35, 1.0, 0), Vector3(0.25, 0.35, 0.15))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_topknot(instance: MeshInstance3D, hair_color: Color, tall := false) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var height := 0.25 if tall else 0.15
	_add_sphere(st, Vector3(0, 1.78 if tall else 1.72, 0), 0.08, 1)
	_add_box(st, Vector3(0, 1.82 if tall else 1.78, -0.05), Vector3(0.06, height, 0.06))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hair_color
	mat.roughness = 0.9
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_long_hair(instance: MeshInstance3D, hair_color: Color) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_box(st, Vector3(0, 1.5, -0.15), Vector3(0.25, 0.35, 0.1))
	_add_box(st, Vector3(0, 1.35, 0.1), Vector3(0.1, 0.6, 0.08))  # 辫子

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = hair_color
	mat.roughness = 0.85
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_beard(instance: MeshInstance3D) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_box(st, Vector3(0, 1.45, 0.15), Vector3(0.12, 0.15, 0.08))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.9)
	mat.roughness = 0.9
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_armor(instance: MeshInstance3D, armor_color: Color) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 胸甲
	_add_box(st, Vector3(0, 1.2, -0.05), Vector3(0.45, 0.45, 0.18))
	# 肩甲
	_add_box(st, Vector3(-0.32, 1.3, 0), Vector3(0.15, 0.15, 0.2))
	_add_box(st, Vector3(0.32, 1.3, 0), Vector3(0.15, 0.15, 0.2))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = armor_color
	mat.roughness = 0.4
	mat.metallic = 0.6
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_helmet(instance: MeshInstance3D, helmet_color: Color) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	_add_sphere(st, Vector3(0, 1.65, 0), 0.22, 1)
	_add_box(st, Vector3(0, 1.9, 0), Vector3(0.08, 0.25, 0.08))  # 缨

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = helmet_color
	mat.roughness = 0.3
	mat.metallic = 0.7
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

static func _add_sword(instance: MeshInstance3D) -> void:
	var mesh := instance.mesh as ArrayMesh
	if mesh == null:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# 剑身
	_add_box(st, Vector3(0.35, 0.7, 0), Vector3(0.03, 0.8, 0.015))
	# 剑柄
	_add_box(st, Vector3(0.35, 1.15, 0), Vector3(0.04, 0.15, 0.03))
	# 护手
	_add_box(st, Vector3(0.35, 1.22, 0), Vector3(0.12, 0.03, 0.04))

	st.generate_normals()
	var surf_mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.75, 0.8)
	mat.roughness = 0.2
	mat.metallic = 0.9
	surf_mesh.surface_set_material(0, mat)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf_mesh.surface_get_arrays(0))

# ===== 基础几何 =====

static func _add_box(st: SurfaceTool, center: Vector3, extents: Vector3) -> void:
	var h := extents * 0.5
	var v := func offset(p: Vector3) -> Vector3: return center + p

	var verts := PackedVector3Array([
		v.call(Vector3(-h.x, -h.y, -h.z)),
		v.call(Vector3(h.x, -h.y, -h.z)),
		v.call(Vector3(h.x, -h.y, h.z)),
		v.call(Vector3(-h.x, -h.y, h.z)),
		v.call(Vector3(-h.x, h.y, -h.z)),
		v.call(Vector3(h.x, h.y, -h.z)),
		v.call(Vector3(h.x, h.y, h.z)),
		v.call(Vector3(-h.x, h.y, h.z)),
	])

	var indices := [
		0,1,2, 0,2,3, 4,6,5, 4,7,6,
		0,4,5, 0,5,1, 1,5,6, 1,6,2,
		2,6,7, 2,7,3, 3,7,4, 3,4,0
	]
	for i in indices:
		st.add_vertex(verts[i])

static func _add_sphere(
		st: SurfaceTool, center: Vector3,
		radius: float, _subdivisions: int = 1
	) -> void:
	var phi := (1.0 + sqrt(5.0)) / 2.0

	var verts := PackedVector3Array([
		Vector3(-1, phi, 0), Vector3(1, phi, 0),
		Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi),
		Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1),
		Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
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
