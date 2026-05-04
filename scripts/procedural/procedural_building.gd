## 程序化建筑生成器 - 修仙风格宗门建筑
## 生成各种仙侠风格的3D建筑网格

class_name ProceduralBuilding
extends Node

# 建筑类型枚举
enum BuildingType {
	HALL,           # 大殿
	PAGODA,         # 宝塔
	PAVILION,       # 亭阁
	ALTAR,          # 祭坛
	RESIDENCE,      # 居室
	PILLAR,         # 石柱
	GATE,           # 山门
	FORGE,          # 炼器房
	ALCHEMY_ROOM,   # 炼丹房
	LIBRARY         # 藏经阁
}

# 生成建筑
static func generate(building_type: BuildingType, size: float = 1.0) -> MeshInstance3D:
	match building_type:
		BuildingType.HALL:
			return _generate_hall(size)
		BuildingType.PAGODA:
			return _generate_pagoda(size)
		BuildingType.PAVILION:
			return _generate_pavilion(size)
		BuildingType.ALTAR:
			return _generate_altar(size)
		BuildingType.RESIDENCE:
			return _generate_residence(size)
		BuildingType.PILLAR:
			return _generate_pillar(size)
		BuildingType.GATE:
			return _generate_gate(size)
		BuildingType.FORGE:
			return _generate_forge(size)
		BuildingType.ALCHEMY_ROOM:
			return _generate_alchemy_room(size)
		BuildingType.LIBRARY:
			return _generate_library(size)
		_:
			return _generate_hall(size)

# 生成大殿
static func _generate_hall(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	
	# 主体
	var base_st := SurfaceTool.new()
	base_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 台阶基座
	_add_box(base_st, Vector3(0, 0.3, 0), Vector3(6, 0.6, 8) * size)
	
	# 主体建筑
	_add_box(base_st, Vector3(0, 2.5, 0), Vector3(5, 4, 7) * size)
	
	# 屋顶 (简化的飞檐)
	_add_pyramid_roof(base_st, Vector3(0, 5.5, 0), Vector3(6, 1.5, 8) * size, 0.3)
	
	base_st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, base_st.commit_to_arrays())
	
	# 材质
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.6)  # 木质色
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return instance

# 生成宝塔
static func _generate_pagoda(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var floors := 5
	var floor_height := 1.5 * size
	var base_radius := 3.0 * size
	
	for i in range(floors):
		var y := i * floor_height + floor_height / 2 + 0.5
		var radius := base_radius * (1.0 - i * 0.15)
		
		# 塔身
		_add_cylinder(st, Vector3(0, y, 0), radius, floor_height * 0.8)
		
		# 飞檐
		var roof_y := y + floor_height * 0.4
		_add_cone(st, Vector3(0, roof_y + 0.3, 0), radius * 1.3, 0.6, true)
	
	# 塔顶
	_add_cone(st, Vector3(0, floors * floor_height + 1, 0), base_radius * 0.3, 2.0)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.65, 0.55)
	mat.roughness = 0.7
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成亭阁
static func _generate_pavilion(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 四根柱子
	var pillar_positions := [Vector3(-1.5, 0, -1.5), Vector3(1.5, 0, -1.5), 
		Vector3(-1.5, 0, 1.5), Vector3(1.5, 0, 1.5)]
	for pos in pillar_positions:
		_add_cylinder(st, pos * size, 0.15 * size, 3.0 * size)
	
	# 穹顶
	_add_dome(st, Vector3(0, 3.5, 0) * size, 2.5 * size, 1.2 * size)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.3)  # 朱红色
	mat.roughness = 0.6
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成祭坛
static func _generate_altar(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 三层台阶
	for i in range(3):
		var scale := 1.0 - i * 0.25
		var y := 0.3 + i * 0.4
		_add_cylinder(st, Vector3(0, y, 0) * size, 2.0 * scale * size, 0.4 * size)
	
	# 中央石柱
	_add_cylinder(st, Vector3(0, 2.0, 0) * size, 0.3 * size, 2.0 * size)
	
	# 顶部光球装饰 (用低多边形球体)
	_add_icosphere(st, Vector3(0, 3.5, 0) * size, 0.5 * size, 1)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.85, 0.7)  # 白玉色
	mat.roughness = 0.3
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成居室
static func _generate_residence(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 简单的房屋
	_add_box(st, Vector3(0, 1.2, 0) * size, Vector3(4, 2.4, 3) * size)
	_add_pyramid_roof(st, Vector3(0, 3.0, 0) * size, Vector3(4.5, 1.0, 3.5) * size, 0.2)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.4)
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成石柱
static func _generate_pillar(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 基座
	_add_box(st, Vector3(0, 0.25, 0) * size, Vector3(1.2, 0.5, 1.2) * size)
	
	# 柱身
	_add_cylinder(st, Vector3(0, 2.5, 0) * size, 0.4 * size, 4.0 * size)
	
	# 顶部
	_add_box(st, Vector3(0, 5.0, 0) * size, Vector3(1.0, 0.4, 1.0) * size)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.75)
	mat.roughness = 0.7
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成山门
static func _generate_gate(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 左右两柱
	_add_box(st, Vector3(-3, 3, 0) * size, Vector3(1, 8, 1) * size)
	_add_box(st, Vector3(3, 3, 0) * size, Vector3(1, 8, 1) * size)
	
	# 横梁
	_add_box(st, Vector3(0, 7.5, 0) * size, Vector3(8, 1, 1) * size)
	
	# 门檐
	_add_pyramid_roof(st, Vector3(0, 8.5, 0) * size, Vector3(9, 0.8, 2) * size, 0.15)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.2)  # 红色山门
	mat.roughness = 0.5
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成炼器房
static func _generate_forge(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 房屋主体
	_add_box(st, Vector3(0, 1.5, 0) * size, Vector3(5, 3, 4) * size)
	
	# 烟囱
	_add_box(st, Vector3(1.5, 4, 0) * size, Vector3(0.8, 2, 0.8) * size)
	
	# 熔炉口 (用深色标记)
	_add_box(st, Vector3(0, 1, 2) * size, Vector3(1.5, 1.5, 0.2) * size)
	
	# 屋顶
	_add_pyramid_roof(st, Vector3(0, 3.5, 0) * size, Vector3(5.5, 1.2, 4.5) * size, 0.25)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.35, 0.35)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成炼丹房
static func _generate_alchemy_room(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 圆形建筑
	_add_cylinder(st, Vector3(0, 1.5, 0) * size, 3.0 * size, 3.0 * size)
	
	# 穹顶
	_add_dome(st, Vector3(0, 3.5, 0) * size, 3.5 * size, 1.5 * size)
	
	# 丹炉 (中央)
	_add_cylinder(st, Vector3(0, 0.6, 0) * size, 0.6 * size, 1.2 * size)
	_add_dome(st, Vector3(0, 1.4, 0) * size, 0.7 * size, 0.4 * size)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.6)  # 青色
	mat.roughness = 0.6
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 生成藏经阁
static func _generate_library(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 多层书塔
	var floors := 3
	for i in range(floors):
		var y := i * 1.8 + 1.0
		var scale := 1.0 - i * 0.1
		_add_box(st, Vector3(0, y, 0) * size, Vector3(4, 1.6, 4) * scale * size)
		# 屋檐
		_add_box(st, Vector3(0, y + 0.9, 0) * size, Vector3(4.5, 0.2, 4.5) * scale * size)
	
	# 顶部
	_add_pyramid_roof(st, Vector3(0, floors * 1.8 + 1.2, 0) * size, Vector3(3, 2, 3) * size, 0.3)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.4, 0.3)  # 书香木色
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# ===== 基础几何工具 =====

static func _add_box(st: SurfaceTool, center: Vector3, extents: Vector3) -> void:
	var h := extents * 0.5
	var verts := PackedVector3Array([
		# 底面
		center + Vector3(-h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z),
		center + Vector3(-h.x, -h.y, h.z),
		# 顶面
		center + Vector3(-h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z),
		center + Vector3(-h.x, h.y, h.z),
	])
	
	# 各面 (简化为独立三角形)
	var indices := [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
	for i in indices:
		st.add_vertex(verts[i])

static func _add_cylinder(st: SurfaceTool, center: Vector3, radius: float, height: float, segments: int = 16) -> void:
	var h := height * 0.5
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		var c1 := cos(a1) * radius
		var s1 := sin(a1) * radius
		var c2 := cos(a2) * radius
		var s2 := sin(a2) * radius
		
		# 侧面
		st.add_vertex(center + Vector3(c1, -h, s1))
		st.add_vertex(center + Vector3(c2, -h, s2))
		st.add_vertex(center + Vector3(c1, h, s1))
		
		st.add_vertex(center + Vector3(c2, -h, s2))
		st.add_vertex(center + Vector3(c2, h, s2))
		st.add_vertex(center + Vector3(c1, h, s1))
		
		# 顶面
		st.add_vertex(center)
		st.add_vertex(center + Vector3(c1, h, s1))
		st.add_vertex(center + Vector3(c2, h, s2))
		
		# 底面
		st.add_vertex(center)
		st.add_vertex(center + Vector3(c2, -h, s2))
		st.add_vertex(center + Vector3(c1, -h, s1))

static func _add_cone(st: SurfaceTool, apex: Vector3, radius: float, height: float, hollow := false, segments: int = 16) -> void:
	var base_y := apex.y - height
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		var c1 := cos(a1) * radius
		var s1 := sin(a1) * radius
		var c2 := cos(a2) * radius
		var s2 := sin(a2) * radius
		
		# 侧面
		st.add_vertex(apex)
		st.add_vertex(Vector3(c1, base_y, s1) + Vector3(apex.x, 0, apex.z))
		st.add_vertex(Vector3(c2, base_y, s2) + Vector3(apex.x, 0, apex.z))
		
		if not hollow:
			# 底面
			st.add_vertex(Vector3(apex.x, base_y, apex.z))
			st.add_vertex(Vector3(c2, base_y, s2) + Vector3(apex.x, 0, apex.z))
			st.add_vertex(Vector3(c1, base_y, s1) + Vector3(apex.x, 0, apex.z))

static func _add_pyramid_roof(st: SurfaceTool, center: Vector3, extents: Vector3, slope: float) -> void:
	var h := extents * 0.5
	var peak := center + Vector3(0, extents.y, 0)
	var overhang := slope * extents.y
	
	# 四面
	var base := [
		center + Vector3(-h.x - overhang, 0, -h.z - overhang),
		center + Vector3(h.x + overhang, 0, -h.z - overhang),
		center + Vector3(h.x + overhang, 0, h.z + overhang),
		center + Vector3(-h.x - overhang, 0, h.z + overhang),
	]
	
	# 四个斜面
	st.add_vertex(peak)
	st.add_vertex(base[0])
	st.add_vertex(base[1])
	
	st.add_vertex(peak)
	st.add_vertex(base[1])
	st.add_vertex(base[2])
	
	st.add_vertex(peak)
	st.add_vertex(base[2])
	st.add_vertex(base[3])
	
	st.add_vertex(peak)
	st.add_vertex(base[3])
	st.add_vertex(base[0])

static func _add_dome(st: SurfaceTool, center: Vector3, radius: float, height: float, segments: int = 12, rings: int = 6) -> void:
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
			var p3 := center + Vector3(cos(a1) * rad2, y2, sin(a1) * rad2)
			var p4 := center + Vector3(cos(a2) * rad2, y2, sin(a2) * rad2)
			
			st.add_vertex(p1)
			st.add_vertex(p2)
			st.add_vertex(p3)
			
			st.add_vertex(p2)
			st.add_vertex(p4)
			st.add_vertex(p3)

static func _add_icosphere(st: SurfaceTool, center: Vector3, radius: float, subdivisions: int = 1) -> void:
	# 简化的二十面体球体
	var phi := (1.0 + sqrt(5.0)) / 2.0
	
	var verts := PackedVector3Array([
		Vector3(-1, phi, 0), Vector3(1, phi, 0),
		Vector3(-1, -phi, 0), Vector3(1, -phi, 0),
		Vector3(0, -1, phi), Vector3(0, 1, phi),
		Vector3(0, -1, -phi), Vector3(0, 1, -phi),
		Vector3(phi, 0, -1), Vector3(phi, 0, 1),
		Vector3(-phi, 0, -1), Vector3(-phi, 0, 1),
	])
	
	# 归一化并缩放
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
