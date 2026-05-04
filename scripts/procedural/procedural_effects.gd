## 程序化特效生成器 - 仙侠风格特效
## 生成灵气、剑气、丹火等特效网格

class_name ProceduralEffects
extends Node

# 特效类型
enum EffectType {
	QI_ORB,        # 灵气球
	GLIDING_SWORD, # 飞剑
	ALCHEMY_FLAME, # 丹火
	MEDITATION_AURA, # 打坐光环
	BREAKTHROUGH,  # 突破特效
	TALISMAN,      # 符箓
	DAN,           # 金丹
	YUANYING,      # 元婴
	SPIRIT_BEAST,  # 灵兽
	PORTAL,        # 传送门
}

# 调色板
const COLORS := {
	"qi_blue": Color(0.3, 0.7, 1.0),
	"qi_green": Color(0.4, 1.0, 0.5),
	"qi_gold": Color(1.0, 0.85, 0.3),
	"qi_purple": Color(0.7, 0.3, 1.0),
	"fire_red": Color(1.0, 0.4, 0.1),
	"fire_blue": Color(0.3, 0.5, 1.0),
	"fire_green": Color(0.3, 1.0, 0.5),
	"sword_silver": Color(0.9, 0.95, 1.0),
	"breakthrough_white": Color(1.0, 1.0, 1.0),
}

# 生成特效
static func generate(effect_type: EffectType, size: float = 1.0, color_key: String = "qi_blue") -> MeshInstance3D:
	match effect_type:
		EffectType.QI_ORB:
			return _generate_qi_orb(size, color_key)
		EffectType.GLIDING_SWORD:
			return _generate_gliding_sword(size)
		EffectType.ALCHEMY_FLAME:
			return _generate_alchemy_flame(size, color_key)
		EffectType.MEDITATION_AURA:
			return _generate_meditation_aura(size, color_key)
		EffectType.BREAKTHROUGH:
			return _generate_breakthrough(size)
		EffectType.TALISMAN:
			return _generate_talisman(size)
		EffectType.DAN:
			return _generate_dan(size, color_key)
		EffectType.YUANYING:
			return _generate_yuanying(size)
		EffectType.SPIRIT_BEAST:
			return _generate_spirit_beast(size)
		EffectType.PORTAL:
			return _generate_portal(size)
		_:
			return _generate_qi_orb(size, color_key)

# 灵气球
static func _generate_qi_orb(size: float, color_key: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 外层光球
	_add_icosphere(st, Vector3.ZERO, size, 1)
	
	# 内层核心
	_add_icosphere(st, Vector3.ZERO, size * 0.4, 1)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var color := COLORS.get(color_key, COLORS.qi_blue)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 1.5
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.6
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 飞剑
static func _generate_gliding_sword(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 剑身 (流线型)
	_add_sword_blade(st, Vector3(0, 0, 0) * size, size)
	
	# 剑柄
	_add_box(st, Vector3(0, -size * 0.3, 0), Vector3(0.05, 0.15, 0.04) * size)
	
	# 护手
	_add_box(st, Vector3(0, -size * 0.2, 0), Vector3(0.15, 0.03, 0.05) * size)
	
	# 剑气光环
	_add_ring(st, Vector3(0, size * 0.5, 0), size * 0.3, size * 0.05, 8)
	_add_ring(st, Vector3(0, size * 0.3, 0), size * 0.25, size * 0.03, 8)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.95, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.9, 1.0)
	mat.emission_energy = 0.8
	mat.roughness = 0.2
	mat.metallic = 0.9
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 丹火
static func _generate_alchemy_flame(size: float, color_key: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 三层火焰
	for layer in range(3):
		var scale := 1.0 - layer * 0.25
		var offset := Vector3(randf_range(-0.05, 0.05), layer * 0.1, randf_range(-0.05, 0.05)) * size
		_add_flame(st, offset, size * scale, 5 - layer)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var color := COLORS.get(color_key, COLORS.fire_red)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 2.0
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 打坐光环
static func _generate_meditation_aura(size: float, color_key: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 多层光环
	for i in range(3):
		var r := size * (0.8 + i * 0.3)
		var y := size * (0.1 + i * 0.2)
		_add_ring(st, Vector3(0, y, 0), r, size * 0.05, 16)
	
	# 升腾的灵气柱
	_add_cylinder(st, Vector3(0, size * 1.5, 0), size * 0.3, size * 2.0, 8)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var color := COLORS.get(color_key, COLORS.qi_blue)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 1.0
	mat.roughness = 0.1
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 突破特效
static func _generate_breakthrough(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 中央光柱
	_add_cylinder(st, Vector3(0, size, 0), size * 0.4, size * 4.0, 8)
	
	# 散射光芒
	for i in range(8):
		var angle := TAU * i / 8
		var base := Vector3(cos(angle) * size * 0.3, 0, sin(angle) * size * 0.3)
		_add_light_ray(st, base, size * 2.0, angle)
	
	# 顶部光环
	_add_ring(st, Vector3(0, size * 2.5, 0), size * 1.2, size * 0.1, 16)
	_add_ring(st, Vector3(0, size * 2.8, 0), size * 0.8, size * 0.08, 12)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.8)
	mat.emission_energy = 2.5
	mat.roughness = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.8
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 符箓
static func _generate_talisman(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 符纸
	_add_box(st, Vector3(0, 0, 0), Vector3(0.4, 0.6, 0.01) * size)
	
	# 符文符头
	_add_box(st, Vector3(0, 0.25, 0.005) * size, Vector3(0.15, 0.1, 0.005) * size)
	
	# 竖笔
	_add_box(st, Vector3(0, 0.05, 0.005) * size, Vector3(0.02, 0.35, 0.005) * size)
	
	# 左右点
	_add_box(st, Vector3(-0.1, 0.1, 0.005) * size, Vector3(0.05, 0.05, 0.005) * size)
	_add_box(st, Vector3(0.1, 0.1, 0.005) * size, Vector3(0.05, 0.05, 0.005) * size)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.7)  # 黄纸
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 金丹
static func _generate_dan(size: float, color_key: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 圆形丹体
	_add_icosphere(st, Vector3.ZERO, size, 2)
	
	# 纹路
	for i in range(4):
		var angle := TAU * i / 4
		_add_ring(st, Vector3(0, 0, 0), size * 0.8, size * 0.02, 8)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var color := COLORS.get(color_key, COLORS.qi_gold)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.8
	mat.emission_energy = 1.5
	mat.roughness = 0.3
	mat.metallic = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.9
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 元婴
static func _generate_yuanying(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 小人形
	# 头
	_add_icosphere(st, Vector3(0, size * 0.5, 0), size * 0.2, 1)
	# 身体
	_add_box(st, Vector3(0, size * 0.2, 0), Vector3(0.2, 0.35, 0.15) * size)
	# 手臂
	_add_box(st, Vector3(-size * 0.18, size * 0.25, 0), Vector3(0.1, 0.25, 0.1) * size)
	_add_box(st, Vector3(size * 0.18, size * 0.25, 0), Vector3(0.1, 0.25, 0.1) * size)
	# 腿
	_add_box(st, Vector3(-size * 0.08, -size * 0.1, 0), Vector3(0.08, 0.25, 0.1) * size)
	_add_box(st, Vector3(size * 0.08, -size * 0.1, 0), Vector3(0.08, 0.25, 0.1) * size)
	
	# 光环
	_add_ring(st, Vector3(0, -size * 0.1, 0), size * 0.6, size * 0.05, 12)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var color := Color(0.6, 0.8, 1.0)  # 半透明蓝色
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.7
	mat.emission_energy = 1.2
	mat.roughness = 0.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.7
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 灵兽
static func _generate_spirit_beast(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 龙形简化
	# 头
	_add_icosphere(st, Vector3(0, size * 0.6, size * 0.3), size * 0.2, 1)
	# 身体
	_add_cylinder(st, Vector3(0, size * 0.4, 0), size * 0.15, size * 0.8, 6)
	# 翅膀
	_add_wing(st, Vector3(-size * 0.3, size * 0.5, 0), size * 0.4, -PI/4)
	_add_wing(st, Vector3(size * 0.3, size * 0.5, 0), size * 0.4, PI/4)
	# 尾巴
	_add_cylinder(st, Vector3(0, size * 0.2, -size * 0.5), size * 0.08, size * 0.4, 4)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.8)
	mat.emission_energy = 1.0
	mat.roughness = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.8
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# 传送门
static func _generate_portal(size: float) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 门框 (环形)
	_add_torus(st, Vector3(0, size, 0), size * 0.8, size * 0.1, 12)
	
	# 门内漩涡
	_add_disc(st, Vector3(0, size, 0), size * 0.7, 16)
	
	# 装饰柱
	_add_box(st, Vector3(-size * 0.9, size * 0.5, 0), Vector3(0.2, size, 0.2) * size)
	_add_box(st, Vector3(size * 0.9, size * 0.5, 0), Vector3(0.2, size, 0.2) * size)
	
	st.generate_normals()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.3, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.2, 0.8)
	mat.emission_energy = 1.5
	mat.roughness = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.75
	mesh.surface_set_material(0, mat)
	
	instance.mesh = mesh
	return instance

# ===== 几何工具 =====

static func _add_box(st: SurfaceTool, center: Vector3, extents: Vector3) -> void:
	var h := extents * 0.5
	var verts := PackedVector3Array([
		center + Vector3(-h.x, -h.y, -h.z), center + Vector3(h.x, -h.y, -h.z),
		center + Vector3(h.x, -h.y, h.z), center + Vector3(-h.x, -h.y, h.z),
		center + Vector3(-h.x, h.y, -h.z), center + Vector3(h.x, h.y, -h.z),
		center + Vector3(h.x, h.y, h.z), center + Vector3(-h.x, h.y, h.z),
	])
	var indices := [0,1,2, 0,2,3, 4,6,5, 4,7,6, 0,4,5, 0,5,1, 1,5,6, 1,6,2, 2,6,7, 2,7,3, 3,7,4, 3,4,0]
	for i in indices:
		st.add_vertex(verts[i])

static func _add_cylinder(st: SurfaceTool, center: Vector3, radius: float, height: float, segments: int = 8) -> void:
	var h := height * 0.5
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		st.add_vertex(center + Vector3(cos(a1) * radius, -h, sin(a1) * radius))
		st.add_vertex(center + Vector3(cos(a2) * radius, -h, sin(a2) * radius))
		st.add_vertex(center + Vector3(cos(a1) * radius, h, sin(a1) * radius))
		st.add_vertex(center + Vector3(cos(a2) * radius, -h, sin(a2) * radius))
		st.add_vertex(center + Vector3(cos(a2) * radius, h, sin(a2) * radius))
		st.add_vertex(center + Vector3(cos(a1) * radius, h, sin(a1) * radius))

static func _add_icosphere(st: SurfaceTool, center: Vector3, radius: float, subdivisions: int = 1) -> void:
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

static func _add_ring(st: SurfaceTool, center: Vector3, radius: float, thickness: float, segments: int = 12) -> void:
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		# 内圈
		var r_in := radius - thickness * 0.5
		var r_out := radius + thickness * 0.5
		st.add_vertex(center + Vector3(cos(a1) * r_in, 0, sin(a1) * r_in))
		st.add_vertex(center + Vector3(cos(a2) * r_out, 0, sin(a2) * r_out))
		st.add_vertex(center + Vector3(cos(a1) * r_out, 0, sin(a1) * r_out))
		st.add_vertex(center + Vector3(cos(a1) * r_in, 0, sin(a1) * r_in))
		st.add_vertex(center + Vector3(cos(a2) * r_in, 0, sin(a2) * r_in))
		st.add_vertex(center + Vector3(cos(a2) * r_out, 0, sin(a2) * r_out))

static func _add_disc(st: SurfaceTool, center: Vector3, radius: float, segments: int = 12) -> void:
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		st.add_vertex(center)
		st.add_vertex(center + Vector3(cos(a1) * radius, 0, sin(a1) * radius))
		st.add_vertex(center + Vector3(cos(a2) * radius, 0, sin(a2) * radius))

static func _add_flame(st: SurfaceTool, base: Vector3, height: float, points: int = 5) -> void:
	# 火焰形状
	var tip := base + Vector3(0, height, 0)
	var w := height * 0.3
	for i in range(points):
		var a := TAU * i / points + PI / 2
		var mid_r := height * 0.5
		var mid := base + Vector3(cos(a) * mid_r * 0.3, mid_r, sin(a) * mid_r * 0.3)
		st.add_vertex(base + Vector3(cos(a) * w, 0, sin(a) * w))
		st.add_vertex(tip + Vector3(randf_range(-0.02, 0.02), 0, randf_range(-0.02, 0.02)))
		st.add_vertex(mid)

static func _add_sword_blade(st: SurfaceTool, base: Vector3, size: float) -> void:
	# 剑身
	_add_box(st, base + Vector3(0, size * 0.4, 0), Vector3(0.06, size * 0.8, 0.02) * size)
	# 剑尖
	var tip := base + Vector3(0, size * 0.9, 0)
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(-0.03 * size, size * 0.7, 0))
	st.add_vertex(base + Vector3(0.03 * size, size * 0.7, 0))

static func _add_light_ray(st: SurfaceTool, base: Vector3, length: float, angle: float) -> void:
	var tip := base + Vector3(cos(angle) * length, length * 1.5, sin(angle) * length)
	st.add_vertex(base)
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(cos(angle + 0.1) * length * 0.8, length * 1.2, sin(angle + 0.1) * length * 0.8))

static func _add_torus(st: SurfaceTool, center: Vector3, major_radius: float, minor_radius: float, segments: int = 12) -> void:
	for i in range(segments):
		var a1 := TAU * i / segments
		var a2 := TAU * (i + 1) / segments
		for j in range(6):
			var b1 := TAU * j / 6
			var b2 := TAU * (j + 1) / 6
			var r1 := major_radius + cos(b1) * minor_radius
			var r2 := major_radius + cos(b2) * minor_radius
			var y1 := sin(b1) * minor_radius
			var y2 := sin(b2) * minor_radius
			var p1 := center + Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			var p2 := center + Vector3(cos(a2) * r1, y1, sin(a2) * r1)
			var p3 := center + Vector3(cos(a1) * r2, y2, sin(a1) * r2)
			var p4 := center + Vector3(cos(a2) * r2, y2, sin(a2) * r2)
			st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)
			st.add_vertex(p2); st.add_vertex(p4); st.add_vertex(p3)

static func _add_wing(st: SurfaceTool, base: Vector3, size: float, angle: float) -> void:
	var tip := base + Vector3(cos(angle) * size, size * 0.3, sin(angle) * size * 0.5)
	st.add_vertex(base)
	st.add_vertex(tip)
	st.add_vertex(base + Vector3(cos(angle) * size * 0.6, 0, sin(angle) * size * 0.3))
