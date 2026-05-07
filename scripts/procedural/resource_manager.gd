## ResourceManager - 资源管理桩文件
extends Node

# 预加载通用资源（桩）
static func preload_common_assets() -> void:
	print("[ResourceManager] 预加载通用资源 (stub)")

static func create_building(building_type: int, size: float = 1.0) -> MeshInstance3D:
	return null

static func create_character(char_type: int, color: Color = Color(0.5, 0.3, 0.2)) -> MeshInstance3D:
	return null

static func create_tree(tree_type: int, size: float = 1.0) -> MeshInstance3D:
	return null

static func create_rock(rock_type: int, size: float = 1.0) -> MeshInstance3D:
	return null

static func create_plant(plant_type: int, size: float = 1.0) -> MeshInstance3D:
	return null

static func create_effect(effect_type: int, size: float = 1.0, color_key: String = "qi_blue") -> MeshInstance3D:
	return null
