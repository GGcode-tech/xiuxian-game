## 事件结果 - 定义事件选项的结果
class_name EventOutcome extends Resource

@export_range(0.0, 1.0) var probability: float = 1.0
@export_multiline var text: String = ""

# 效果列表
@export var effects: Array[Dictionary] = []
# 效果格式:
# {"type": "add_exp", "value": 1000}
# {"type": "add_resource", "id": "spirit_stone", "value": 500}
# {"type": "add_item", "id": "spirit_grass", "amount": 3}
# {"type": "learn_technique", "id": "fire_control"}
# {"type": "modify_trait", "id": "lucky"}
# {"type": "damage", "value": 50}
# {"type": "heal", "value": 100}
# {"type": "breakthrough_boost", "value": 0.1}
# {"type": "add_reputation", "value": 10}
# {"type": "trigger_event", "id": "follow_up_event"}


func get_effect_preview() -> String:
	var parts = []
	
	for effect in effects:
		var effect_type = effect.get("type", "")
		var value = effect.get("value", 0)
		var id = effect.get("id", "")
		
		match effect_type:
			"add_exp":
				parts.append("✨ 修炼经验 +%d" % value)
			"add_resource":
				parts.append("💎 %s +%d" % [id, value])
			"add_item":
				parts.append("📦 获得 %s x%d" % [id, effect.get("amount", 1)])
			"learn_technique":
				parts.append("📖 习得功法: %s" % id)
			"modify_trait":
				parts.append("⭐ 获得特质: %s" % id)
			"damage":
				parts.append("💔 受到伤害: %d" % value)
			"heal":
				parts.append("💚 恢复生命: %d" % value)
			"breakthrough_boost":
				parts.append("📈 突破概率 +%.0f%%" % (value * 100))
			"add_reputation":
				parts.append("🏆 声望 +%d" % value)
			_:
				parts.append("❓ %s" % effect_type)
	
	return "\n".join(parts)
