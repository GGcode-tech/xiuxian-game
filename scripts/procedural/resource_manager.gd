## ResourceManager - 资源管理桩文件
extends Node

# 预加载通用资源（桩）
static func preload_common_assets() -> void:
	print("[ResourceManager] 预加载通用资源 (stub)")

static func create_building(_building_type: int, _size: float = 1.0) -> MeshInstance3D:
	return null

static func create_character(
		_char_type: int,
		_color: Color = Color(0.5, 0.3, 0.2)
	) -> MeshInstance3D:
	return null

static func create_tree(_tree_type: int, _size: float = 1.0) -> MeshInstance3D:
	return null

static func create_rock(_rock_type: int, _size: float = 1.0) -> MeshInstance3D:
	return null

static func create_plant(_plant_type: int, _size: float = 1.0) -> MeshInstance3D:
	return null

static func create_effect(
		_effect_type: int,
		_size: float = 1.0,
		_color_key: String = "qi_blue"
	) -> MeshInstance3D:
	return null
