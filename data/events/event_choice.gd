## 事件选项 - 定义事件的选项和结果
class_name EventChoice extends Resource

@export var text: String = ""
@export_multiline var description: String = ""

# 选择条件
@export var requirements: Dictionary = {}

# 可能的结果
@export var outcomes: Array = []


func get_requirement_string() -> String:
	var parts = []

	for key in requirements:
		match key:
			"min_realm":
				parts.append("需要境界: %s" % requirements[key])
			"min_resources":
				parts.append("需要资源: %s" % str(requirements[key]))
			"has_item":
				parts.append("需要物品: %s" % requirements[key])
			_:
				parts.append("%s: %s" % [key, str(requirements[key])])

	return "\n".join(parts)
