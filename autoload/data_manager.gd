## 数据管理器 - 管理所有配置数据
extends Node

var realms: Dictionary = {}
var techniques: Dictionary = {}
var items: Dictionary = {}
var events: Dictionary = {}
var game_constants: Dictionary = {}


func _ready() -> void:
	print("[DataManager] 初始化开始")
	load_all_data()
	print("[DataManager] 初始化完成，共加载: %d 境界, %d 功法, %d 物品, %d 事件" % [
		realms.size(), techniques.size(), items.size(), events.size()])


func load_all_data() -> void:
	_load_realms()
	_load_techniques()
	_load_items()
	_load_events()
	_load_constants()


func _load_realms() -> void:
	realms.clear()
	_add_realm({
		"id": "realm_lianqi", "name": "炼气", "order": 1, "tier": 1,
		"description": "踏入修仙的第一步", "color": "#8B5CF6",
		"required_exp": 0, "max_hp_bonus": 0, "attack_bonus": 0
	})
	_add_realm({
		"id": "realm_zhuoji", "name": "筑基", "order": 2, "tier": 2,
		"description": "丹田化液，根基初成", "color": "#3B82F6",
		"required_exp": 1000, "max_hp_bonus": 50, "attack_bonus": 10
	})
	_add_realm({
		"id": "realm_jiandan", "name": "结丹", "order": 3, "tier": 3,
		"description": "金丹凝聚，真气凝实", "color": "#10B981",
		"required_exp": 5000, "max_hp_bonus": 150, "attack_bonus": 30
	})
	_add_realm({
		"id": "realm_yuanying", "name": "元婴", "order": 4, "tier": 4,
		"description": "元婴出窍，神通初现", "color": "#F59E0B",
		"required_exp": 20000, "max_hp_bonus": 400, "attack_bonus": 80
	})
	_add_realm({
		"id": "realm_huashen", "name": "化神", "order": 5, "tier": 5,
		"description": "化神成功，神识大增", "color": "#EF4444",
		"required_exp": 80000, "max_hp_bonus": 1000, "attack_bonus": 200
	})
	_add_realm({
		"id": "realm_linxu", "name": "炼虚", "order": 6, "tier": 6,
		"description": "炼虚合道，半步大乘", "color": "#EC4899",
		"required_exp": 300000, "max_hp_bonus": 2500, "attack_bonus": 500
	})
	_add_realm({
		"id": "realm_heti", "name": "合体", "order": 7, "tier": 7,
		"description": "天人合一，道法自然", "color": "#8B5CF6",
		"required_exp": 1000000, "max_hp_bonus": 6000, "attack_bonus": 1200
	})
	_add_realm({
		"id": "realm_dacheng", "name": "大乘", "order": 8, "tier": 8,
		"description": "大乘圆满，飞升在即", "color": "#F97316",
		"required_exp": 5000000, "max_hp_bonus": 15000, "attack_bonus": 3000
	})
	_add_realm({
		"id": "realm_dujie", "name": "渡劫", "order": 9, "tier": 9,
		"description": "渡劫成仙，雷劫加身", "color": "#DC2626",
		"required_exp": 20000000, "max_hp_bonus": 40000, "attack_bonus": 8000
	})
	_add_realm({
		"id": "realm_feisheng", "name": "飞升", "order": 10, "tier": 10,
		"description": "白日飞升，位列仙班", "color": "#FFD700",
		"required_exp": 100000000, "max_hp_bonus": 100000, "attack_bonus": 20000
	})


func _load_techniques() -> void:
	techniques.clear()
	_add_technique({
		"id": "technique_jianxin", "name": "剑心决",
		"type": "cultivation", "tier": 1, "level": 1, "exp_required": 0,
		"effect": {"attack": 5}, "description": "凝聚剑心，剑意初成"
	})
	_add_technique({
		"id": "technique_tianjiang", "name": "天剑术",
		"type": "attack", "tier": 2, "level": 1, "exp_required": 1000,
		"effect": {"attack": 15}, "description": "天剑降世，斩尽一切"
	})
	_add_technique({
		"id": "technique_yuyin", "name": "御风术",
		"type": "movement", "tier": 1, "level": 1, "exp_required": 0,
		"effect": {"speed": 10}, "description": "御风而行，来去如风"
	})
	_add_technique({
		"id": "technique_bushu", "name": "不死身",
		"type": "defense", "tier": 3, "level": 1, "exp_required": 5000,
		"effect": {"max_hp": 50, "defense": 10}, "description": "肉身不朽，滴血重生"
	})
	_add_technique({
		"id": "technique_huanjie", "name": "换劫术",
		"type": "special", "tier": 4, "level": 1, "exp_required": 20000,
		"effect": {"attack": 30, "speed": 20}, "description": "以身化劫，劫火焚天"
	})
	_add_technique({
		"id": "technique_feijian", "name": "飞剑术",
		"type": "attack", "tier": 2, "level": 1, "exp_required": 1500,
		"effect": {"attack": 12}, "description": "御剑飞行，剑去如虹"
	})
	_add_technique({
		"id": "technique_xuanwu", "name": "玄武护体",
		"type": "defense", "tier": 2, "level": 1, "exp_required": 2000,
		"effect": {"defense": 15, "max_hp": 30}, "description": "玄武真力，防御无双"
	})
	_add_technique({
		"id": "technique_benlei", "name": "奔雷诀",
		"type": "attack", "tier": 3, "level": 1, "exp_required": 8000,
		"effect": {"attack": 25, "speed": 15}, "description": "雷声滚滚，势不可挡"
	})


func _load_items() -> void:
	items.clear()
	_add_item({
		"id": "item_lingshi", "name": "灵石",
		"type": "currency", "rarity": "common", "stack_size": 9999,
		"value": 1, "description": "修仙界通用货币"
	})
	_add_item({
		"id": "item_zhuyun", "name": "驻颜丹",
		"type": "pill", "rarity": "rare", "stack_size": 10,
		"value": 500, "effect": {"trait": "youthful"}, "description": "永驻容颜，青春不老"
	})
	_add_item({
		"id": "item_jiuxuan", "name": "九玄丹",
		"type": "pill", "rarity": "epic", "stack_size": 5,
		"value": 5000, "effect": {"exp": 10000}, "description": "服用后可大幅提升修为"
	})
	_add_item({
		"id": "item_xuanwu", "name": "玄武甲",
		"type": "equipment", "rarity": "rare", "stack_size": 1,
		"value": 2000, "effect": {"defense": 30}, "description": "玄武神甲，防御惊人"
	})
	_add_item({
		"id": "item_jinshi", "name": "金丝甲",
		"type": "equipment", "rarity": "uncommon", "stack_size": 1,
		"value": 300, "effect": {"defense": 10}, "description": "金丝编织，轻便防护"
	})


func _load_events() -> void:
	events.clear()
	_add_event({
		"id": "event_breakthrough", "name": "顿悟突破",
		"event_type": "character", "trigger_chance": 0.05,
		"triggers": {"min_realm": "realm_lianqi", "min_age": 50},
		"choices": [
			{
				"text": "闭关突破",
				"requirements": {},
				"outcomes": [
					{"text": "你感到灵力涌动，境界松动了！", "probability": 0.6, "effects": [
						{"type": "add_exp", "value": 500}
					]},
					{"text": "突破失败，受到反噬。", "probability": 0.4, "effects": [
						{"type": "damage", "value": 20}
					]}
				]
			}
		]
	})
	_add_event({
		"id": "event_zhanyi", "name": "仙魔大战",
		"event_type": "world", "trigger_chance": 0.02,
		"triggers": {"min_year": 100},
		"choices": [
			{
				"text": "加入正派联军",
				"requirements": {},
				"outcomes": [
					{"text": "大战结束，你立下赫赫战功。", "probability": 0.7, "effects": [
						{"type": "add_exp", "value": 2000}, {"type": "add_resource", "id": "prestige", "value": 100}
					]},
					{"text": "你不幸陨落在战场上。", "probability": 0.3, "effects": [
						{"type": "damage", "value": 200}
					]}
				]
			},
			{
				"text": "闭关躲避",
				"requirements": {},
				"outcomes": [
					{"text": "你闭关修炼，躲过了战乱。", "probability": 1.0, "effects": [
						{"type": "add_exp", "value": 300}
					]}
				]
			}
		]
	})
	_add_event({
		"id": "event_cave", "name": "秘境探索",
		"event_type": "character", "trigger_chance": 0.03,
		"triggers": {"min_realm": "realm_zhuoji"},
		"choices": [
			{
				"text": "探索秘境",
				"requirements": {},
				"outcomes": [
					{"text": "你发现了一处前辈洞府！", "probability": 0.3, "effects": [
						{"type": "learn_technique", "id": "technique_bushu"}, {"type": "add_item", "id": "item_jiuxuan"}
					]},
					{"text": "你找到了不少灵石。", "probability": 0.5, "effects": [
						{"type": "add_resource", "id": "spirit_stone", "value": 500}
					]},
					{"text": "你遭遇了禁制反噬。", "probability": 0.2, "effects": [
						{"type": "damage", "value": 50}
					]}
				]
			}
		]
	})


func _load_constants() -> void:
	game_constants = {
		"START_YEAR": 1,
		"START_MONTH": 1,
		"START_DAY": 1,
		"TICK_INTERVAL": 1.0,
		"BASE_EXP_RATE": 1.0,
		"BASE_HARVEST_RATE": 10,
		"MAX_FAMILY_SIZE": 20,
		"MAX_CULTIVATION_SPEED": 5.0,
		"BREAKTHROUGH_BASE_CHANCE": 0.1,
	}


func _add_realm(data: Dictionary) -> void:
	realms[data.get("id", "")] = data


func _add_technique(data: Dictionary) -> void:
	techniques[data.get("id", "")] = data


func _add_item(data: Dictionary) -> void:
	items[data.get("id", "")] = data


func _add_event(data: Dictionary) -> void:
	events[data.get("id", "")] = data


func get_realm(id: String) -> Dictionary:
	return realms.get(id, {})


func get_technique(id: String) -> Dictionary:
	return techniques.get(id, {})


func get_item(id: String) -> Dictionary:
	return items.get(id, {})


func get_event(id: String) -> Dictionary:
	return events.get(id, {})


func get_all_realms() -> Array:
	return realms.values()


func get_all_techniques() -> Array:
	return techniques.values()


func get_all_items() -> Array:
	return items.values()


func get_all_events() -> Array:
	return events.values()


func get_techniques_by_tier(tier: int) -> Array:
	var result: Array = []
	for tech in techniques.values():
		if tech.get("tier", 0) == tier:
			result.append(tech)
	return result


func get_constant(key: String):
	return game_constants.get(key, null)


# ==================== 新增数据获取方法 ====================

func get_data(key: String):
	# 从game_database.json读取额外数据
	var db = _load_game_database()
	return db.get(key, {})


func _load_game_database() -> Dictionary:
	# 懒加载game_database.json
	var db_path = "res://data/game_database.json"
	if not FileAccess.file_exists(db_path):
		return {}
	
	var file = FileAccess.open(db_path, FileAccess.READ)
	if not file:
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(content) != OK:
		return {}
	
	return json.data if json.data is Dictionary else {}


func get_sects() -> Dictionary:
	var db = _load_game_database()
	return db.get("sects", {})


func get_dungeons() -> Dictionary:
	var db = _load_game_database()
	return db.get("dungeons", {})


func get_daily_activities() -> Dictionary:
	var db = _load_game_database()
	return db.get("daily_activities", {})


func get_spirit_beasts() -> Dictionary:
	var db = _load_game_database()
	return db.get("spirit_beasts", {})


func get_equipment_sets() -> Dictionary:
	var db = _load_game_database()
	return db.get("equipment_sets", {})
