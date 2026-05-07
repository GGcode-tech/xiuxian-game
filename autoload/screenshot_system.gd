## 截图系统 - 按F12截图，保存到项目目录
extends Node

const SCREENSHOT_DIR = "res://test_screenshots/"
var _screenshot_count: int = 0

func _ready() -> void:
	# 创建截图目录
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)
	print("[ScreenshotSystem] 截图保存目录: ", ProjectSettings.globalize_path(SCREENSHOT_DIR))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F12:
			take_screenshot()

func take_screenshot(custom_name: String = "") -> void:
	# 等一帧确保渲染完成
	await get_tree().process_frame
	await get_tree().process_frame
	
	var image = get_viewport().get_texture().get_image()
	_screenshot_count += 1
	
	var filename: String
	if custom_name != "":
		filename = "%s_%s.png" % [_screenshot_count, custom_name]
	else:
		filename = "%03d_screenshot.png" % _screenshot_count
	
	var path = SCREENSHOT_DIR + filename
	var error = image.save_png(path)
	
	if error == OK:
		var abs_path = ProjectSettings.globalize_path(path)
		print("[Screenshot] 截图已保存: ", abs_path)
	else:
		print("[Screenshot] 截图失败: ", error)

# 自动截图（用于测试流程）
func auto_screenshot(step_name: String) -> void:
	take_screenshot(step_name)
