## 数据管理器 - 管理所有配置数据
extends Node

var realms: Dictionary = {}
var techniques: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}
var events: Dictionary = {}
var alchemy_recipes: Dictionary = {}

var game_constants: Dictionary = {}
## 便捷别名，供其他脚本通过 DataManager.constants.xxx 访问
var constants: Dictionary = {}

## game_database.json 查询（委托给DataManagerDB）
var _db: RefCounted = preload("data_manager_db.gd").new()


func _ready() -> void:
	print("[DataManager] 初始化开始")
	_load_all_data()
	print("[DataManager] 初始化完成，共加载: %d 境界, %d 功法, %d 技能, %d 物品, %d 事件" % [
		realms.size(), techniques.size(), skills.size(), items.size(), events.size()])


func _load_all_data() -> void:
	_load_realms()
	_load_techniques()
	_load_skills()
	_load_items()
	_load_events()
	_load_alchemy_recipes()
	_load_constants()


func _load_realms() -> void:
	realms.clear()
	_add_realm({
		"id": "mortal", "name": "凡人", "order": 0, "tier": 0,
		"description": "尚未踏入修仙之路", "color": "#9CA3AF",
		"required_exp": 0, "max_hp_bonus": 0, "attack_bonus": 0,
		"max_mp_bonus": 0, "defense_bonus": 0, "spirit_bonus": 0,
		"speed_bonus": 0, "lifespan_bonus": 0,
		"required_resources": {}, "base_breakthrough_rate": 0.5,
		"failure_penalty": {"exp_loss_rate": 0.0, "injury_chance": 0.0, "death_chance": 0.0}
	})
	_add_realm({
		"id": "realm_lianqi", "name": "炼气", "order": 1, "tier": 1,
		"description": "踏入修仙的第一步", "color": "#8B5CF6",
		"required_exp": 0, "max_hp_bonus": 0, "attack_bonus": 0,
		"max_mp_bonus": 0, "defense_bonus": 0, "spirit_bonus": 0,
		"speed_bonus": 0, "lifespan_bonus": 0,
		"required_resources": {}, "base_breakthrough_rate": 0.4,
		"failure_penalty": {"exp_loss_rate": 0.2, "injury_chance": 0.1, "death_chance": 0.0}
	})
	_add_realm({
		"id": "realm_zhuoji", "name": "筑基", "order": 2, "tier": 2,
		"description": "丹田化液，根基初成", "color": "#3B82F6",
		"required_exp": 1000, "max_hp_bonus": 50, "attack_bonus": 10,
		"max_mp_bonus": 20, "defense_bonus": 5, "spirit_bonus": 5,
		"speed_bonus": 5, "lifespan_bonus": 50,
		"required_resources": {"spirit_stone": 500}, "base_breakthrough_rate": 0.3,
		"failure_penalty": {"exp_loss_rate": 0.3, "injury_chance": 0.2, "death_chance": 0.0}
	})
	_add_realm({
		"id": "realm_jiandan", "name": "结丹", "order": 3, "tier": 3,
		"description": "金丹凝聚，真气凝实", "color": "#10B981",
		"required_exp": 5000, "max_hp_bonus": 150, "attack_bonus": 30,
		"max_mp_bonus": 60, "defense_bonus": 15, "spirit_bonus": 15,
		"speed_bonus": 10, "lifespan_bonus": 100,
		"required_resources": {"spirit_stone": 2000}, "base_breakthrough_rate": 0.2,
		"failure_penalty": {"exp_loss_rate": 0.3, "injury_chance": 0.3, "death_chance": 0.05}
	})
	_add_realm({
		"id": "realm_yuanying", "name": "元婴", "order": 4, "tier": 4,
		"description": "元婴出窍，神通初现", "color": "#F59E0B",
		"required_exp": 20000, "max_hp_bonus": 400, "attack_bonus": 80,
		"max_mp_bonus": 150, "defense_bonus": 40, "spirit_bonus": 40,
		"speed_bonus": 25, "lifespan_bonus": 200,
		"required_resources": {"spirit_stone": 10000}, "base_breakthrough_rate": 0.15,
		"failure_penalty": {"exp_loss_rate": 0.4, "injury_chance": 0.4, "death_chance": 0.1}
	})
	_add_realm({
		"id": "realm_huashen", "name": "化神", "order": 5, "tier": 5,
		"description": "化神成功，神识大增", "color": "#EF4444",
		"required_exp": 80000, "max_hp_bonus": 1000, "attack_bonus": 200,
		"max_mp_bonus": 300, "defense_bonus": 100, "spirit_bonus": 100,
		"speed_bonus": 50, "lifespan_bonus": 500,
		"required_resources": {"spirit_stone": 50000}, "base_breakthrough_rate": 0.1,
		"failure_penalty": {"exp_loss_rate": 0.5, "injury_chance": 0.5, "death_chance": 0.2}
	})
	_add_realm({
		"id": "realm_linxu", "name": "炼虚", "order": 6, "tier": 6,
		"description": "炼虚合道，半步大乘", "color": "#EC4899",
		"required_exp": 300000, "max_hp_bonus": 2500, "attack_bonus": 500,
		"max_mp_bonus": 800, "defense_bonus": 250, "spirit_bonus": 250,
		"speed_bonus": 100, "lifespan_bonus": 1000,
		"required_resources": {"spirit_stone": 200000}, "base_breakthrough_rate": 0.08,
		"failure_penalty": {"exp_loss_rate": 0.5, "injury_chance": 0.6, "death_chance": 0.3}
	})
	_add_realm({
		"id": "realm_heti", "name": "合体", "order": 7, "tier": 7,
		"description": "天人合一，道法自然", "color": "#8B5CF6",
		"required_exp": 1000000, "max_hp_bonus": 6000, "attack_bonus": 1200,
		"max_mp_bonus": 2000, "defense_bonus": 600, "spirit_bonus": 600,
		"speed_bonus": 200, "lifespan_bonus": 2000,
		"required_resources": {"spirit_stone": 1000000}, "base_breakthrough_rate": 0.06,
		"failure_penalty": {"exp_loss_rate": 0.6, "injury_chance": 0.7, "death_chance": 0.4}
	})
	_add_realm({
		"id": "realm_dacheng", "name": "大乘", "order": 8, "tier": 8,
		"description": "大乘圆满，飞升在即", "color": "#F97316",
		"required_exp": 5000000, "max_hp_bonus": 15000, "attack_bonus": 3000,
		"max_mp_bonus": 5000, "defense_bonus": 1500, "spirit_bonus": 1500,
		"speed_bonus": 500, "lifespan_bonus": 5000,
		"required_resources": {"spirit_stone": 5000000}, "base_breakthrough_rate": 0.04,
		"failure_penalty": {"exp_loss_rate": 0.7, "injury_chance": 0.8, "death_chance": 0.5}
	})
	_add_realm({
		"id": "realm_dujie", "name": "渡劫", "order": 9, "tier": 9,
		"description": "渡劫成仙，雷劫加身", "color": "#DC2626",
		"required_exp": 20000000, "max_hp_bonus": 40000, "attack_bonus": 8000,
		"max_mp_bonus": 15000, "defense_bonus": 4000, "spirit_bonus": 4000,
		"speed_bonus": 1000, "lifespan_bonus": 10000,
		"required_resources": {"spirit_stone": 20000000}, "base_breakthrough_rate": 0.03,
		"failure_penalty": {"exp_loss_rate": 0.8, "injury_chance": 0.9, "death_chance": 0.7}
	})
	_add_realm({
		"id": "realm_feisheng", "name": "飞升", "order": 10, "tier": 10,
		"description": "白日飞升，位列仙班", "color": "#FFD700",
		"required_exp": 100000000, "max_hp_bonus": 100000, "attack_bonus": 20000,
		"max_mp_bonus": 50000, "defense_bonus": 20000, "spirit_bonus": 20000,
		"speed_bonus": 5000, "lifespan_bonus": 99999,
		"required_resources": {}, "base_breakthrough_rate": 0.0,
		"failure_penalty": {}
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


func _load_skills() -> void:
	skills.clear()
	_add_skill({
		"id": "skill_jianqi", "name": "剑气斩",
		"mp_cost": 10, "cooldown": 2,
		"target_type": "single_enemy",
		"damage_multiplier": 1.5,
		"heal_amount": 0,
		"effects": []
	})
	_add_skill({
		"id": "skill_yuyin_dodge", "name": "御风闪避",
		"mp_cost": 5, "cooldown": 3,
		"target_type": "self",
		"damage_multiplier": 0,
		"heal_amount": 0,
		"effects": [{
			"id": "dodge_buff", "name": "闪避提升",
			"type": "buff", "duration": 3,
			"effects": {"dodge": 0.2}
		}]
	})
	_add_skill({
		"id": "skill_huizhiling", "name": "回春术",
		"mp_cost": 15, "cooldown": 4,
		"target_type": "single_ally",
		"damage_multiplier": 0,
		"heal_amount": 50,
		"effects": []
	})
	_add_skill({
		"id": "skill_tianjian", "name": "天剑降世",
		"mp_cost": 25, "cooldown": 5,
		"target_type": "all_enemy",
		"damage_multiplier": 2.0,
		"heal_amount": 0,
		"effects": [{
			"id": "armor_break", "name": "破甲",
			"type": "debuff", "duration": 2,
			"effects": {"defense_multiplier": 0.8}
		}]
	})
	_add_skill({
		"id": "skill_bushu_shield", "name": "不死护盾",
		"mp_cost": 20, "cooldown": 6,
		"target_type": "self",
		"damage_multiplier": 0,
		"heal_amount": 0,
		"effects": [{
			"id": "shield", "name": "护盾",
			"type": "buff", "duration": 3,
			"effects": {"damage_reduction": 0.5}
		}]
	})
	_add_skill({
		"id": "skill_benlei", "name": "奔雷击",
		"mp_cost": 18, "cooldown": 3,
		"target_type": "single_enemy",
		"damage_multiplier": 2.5,
		"heal_amount": 0,
		"effects": [{"id": "stun", "name": "眩晕", "type": "control", "duration": 1, "effects": {}}]
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
	_add_item({
		"id": "item_feijian", "name": "飞剑",
		"type": "equipment", "rarity": "rare", "stack_size": 1,
		"value": 3000, "effect": {"attack": 25, "speed": 10}, "description": "御剑飞行，锋利无匹"
	})
	_add_item({
		"id": "item_beast_core", "name": "妖兽内丹",
		"type": "material", "rarity": "uncommon", "stack_size": 99,
		"value": 100, "description": "妖兽精华凝结的内丹"
	})
	_add_item({
		"id": "item_huoshi", "name": "火石",
		"type": "material", "rarity": "common", "stack_size": 99,
		"value": 10, "description": "炼丹辅材"
	})
	_add_item({
		"id": "item_huoyandan", "name": "火焰丹",
		"type": "pill", "rarity": "uncommon", "stack_size": 10,
		"value": 200, "effect": {"attack": 5}, "description": "服用后短暂提升攻击力"
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
						{"type": "learn_technique", "id": "technique_bushu"},
					{"type": "add_item", "id": "item_jiuxuan"}
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
	# ==================== 月度事件 (8个) ====================
	_add_event({
			"id": "monthly_fullmoon", "name": "月圆之夜",
			"event_type": "monthly", "probability": 0.3,
			"trigger_condition": {"min_month": 1},
			"description": "月华如水，灵气充沛，天地间的灵力在月光下涌动。",
			"choices": [
				{
					"text": "趁月修炼",
					"outcomes": [
						{"probability": 0.7, "text": "月华入体，修炼效果极佳！", "effects": [
							{"type": "add_exp_mult", "value": 0.5}
						]},
						{"probability": 0.3, "text": "月光刺眼，修炼受到干扰。", "effects": []}
					]
				},
				{
					"text": "静观其变",
					"outcomes": [
						{"probability": 1.0, "text": "你静静观赏月色，心绪平和。", "effects": []}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_exam", "name": "门派考核",
			"event_type": "monthly", "probability": 0.4,
			"trigger_condition": {"min_month": 3},
			"description": "门派一年一度的考核即将到来，弟子们各显神通。",
			"choices": [
				{
					"text": "全力参与",
					"outcomes": [
						{"probability": 0.5, "text": "表现出色，门派贡献度大增！", "effects": [
							{"type": "add_resource", "id": "prestige", "value": 50},
							{"type": "add_exp", "value": 200}
						]},
						{"probability": 0.5, "text": "表现平平，没有特别收获。", "effects": []}
					]
				},
				{
					"text": "故意藏拙",
					"outcomes": [
						{"probability": 1.0, "text": "低调行事，不引人注目。", "effects": []}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_herb", "name": "灵药成熟",
			"event_type": "monthly", "probability": 0.25,
			"trigger_condition": {"min_month": 1},
			"description": "后山药田中一株灵药散发出浓郁的药香，似乎已完全成熟。",
			"choices": [
				{
					"text": "采摘灵药",
					"outcomes": [
						{"probability": 0.6, "text": "灵药品质上乘，可炼制高级丹药！", "effects": [
							{"type": "add_item", "id": "item_jiuxuan"}
						]},
						{"probability": 0.4, "text": "灵药尚欠火候，只得到普通药材。", "effects": [
							{"type": "add_resource", "id": "herb", "value": 30}
						]}
					]
				},
				{
					"text": "留给弟子们",
					"outcomes": [
						{"probability": 1.0, "text": "弟子们感激不尽，门派凝聚力提升。", "effects": [
							{"type": "add_resource", "id": "prestige", "value": 20}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_caravan", "name": "商队来访",
			"event_type": "monthly", "probability": 0.35,
			"trigger_condition": {"min_month": 1},
			"description": "一支远道而来的商队途经此地，带来了各地的稀有物品。",
			"choices": [
				{
					"text": "购买材料",
					"outcomes": [
						{"probability": 0.8, "text": "以合理价格购得稀有材料！", "effects": [
							{"type": "add_resource", "id": "spirit_stone", "value": -100},
							{"type": "add_item", "id": "item_feijian"}
						]},
						{"probability": 0.2, "text": "商队漫天要价，没有成交。", "effects": []}
					]
				},
				{
					"text": "置之不理",
					"outcomes": [
						{"probability": 1.0, "text": "商队匆匆离去，没有停留。", "effects": []}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_beast", "name": "妖兽出没",
			"event_type": "monthly", "probability": 0.3,
			"trigger_condition": {"min_month": 2},
			"description": "附近山林中传来妖兽的嚎叫，似乎有一头强大的妖兽出没。",
			"choices": [
				{
					"text": "迎战妖兽",
					"requirements": {"min_realm": 2},
					"outcomes": [
						{"probability": 0.6, "text": "成功斩杀妖兽，获得珍贵内丹！", "effects": [
							{"type": "add_item", "id": "item_beast_core"},
							{"type": "add_exp", "value": 300}
						]},
						{"probability": 0.4, "text": "妖兽凶猛，你受了不轻的伤。", "effects": [
							{"type": "damage", "value": 50}
						]}
					]
				},
				{
					"text": "躲避妖兽",
					"outcomes": [
						{"probability": 1.0, "text": "你小心避开，没有惊动妖兽。", "effects": []}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_visit", "name": "同道拜访",
			"event_type": "monthly", "probability": 0.35,
			"trigger_condition": {"min_month": 1},
			"description": "一位久未谋面的道友前来拜访，带来了远方的消息。",
			"choices": [
				{
					"text": "热情款待",
					"outcomes": [
						{"probability": 1.0, "text": "与道友畅谈甚欢，关系更加亲密。", "effects": [
							{"type": "add_relationship", "id": "daoist_friend", "value": 10}
						]}
					]
				},
				{
					"text": "婉拒见面",
					"outcomes": [
						{"probability": 1.0, "text": "道友失望离去，关系略显冷淡。", "effects": [
							{"type": "add_relationship", "id": "daoist_friend", "value": -5}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_omen", "name": "天象异变",
			"event_type": "monthly", "probability": 0.15,
			"trigger_condition": {"min_month": 6},
			"description": "天空中出现奇异天象，星辰闪烁不定，似乎预示着什么。",
			"choices": [
				{
					"text": "参悟天机",
					"outcomes": [
						{"probability": 0.4, "text": "感悟天地大道，修为大进！", "effects": [
							{"type": "add_exp", "value": 800}
						]},
						{"probability": 0.6, "text": "天机难测，未能参透。", "effects": []}
					]
				},
				{
					"text": "祈福消灾",
					"outcomes": [
						{"probability": 1.0, "text": "你焚香祈福，心中安定。", "effects": [
							{"type": "heal", "value": 30}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "monthly_harvest", "name": "资源丰收",
			"event_type": "monthly", "probability": 0.3,
			"trigger_condition": {"min_month": 8},
			"description": "今年风调雨顺，灵田丰收，各种资源产量大增。",
			"choices": [
				{
					"text": "全力收割",
					"outcomes": [
						{"probability": 1.0, "text": "收获满满！家族资源大幅提升。", "effects": [
							{"type": "add_resource", "id": "spirit_stone", "value": 200},
							{"type": "add_resource", "id": "herb", "value": 50}
						]}
					]
				},
				{
					"text": "部分保留",
					"outcomes": [
						{"probability": 1.0, "text": "保留部分资源以备不时之需。", "effects": [
							{"type": "add_resource", "id": "spirit_stone", "value": 100}
						]}
					]
				}
			]
	})
	# ==================== 年度事件 (6个) ====================
	_add_event({
			"id": "yearly_assembly", "name": "宗门大会",
			"event_type": "yearly", "probability": 0.25,
			"trigger_condition": {"min_year": 1},
			"description": "各宗门齐聚一堂，共商修仙界大事，声望与资源的较量。",
			"choices": [
				{
					"text": "积极参与",
					"outcomes": [
						{"probability": 0.5, "text": "宗门大放异彩，声望与资源双丰收！", "effects": [
							{"type": "add_resource", "id": "prestige", "value": 100},
							{"type": "add_resource", "id": "spirit_stone", "value": 500}
						]},
						{"probability": 0.5, "text": "宗门表现平平，没有特别收获。", "effects": [
							{"type": "add_resource", "id": "prestige", "value": 20}
						]}
					]
				},
				{
					"text": "低调参与",
					"outcomes": [
						{"probability": 1.0, "text": "低调行事，获得基本尊重。", "effects": [
							{"type": "add_resource", "id": "prestige", "value": 30}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "yearly_calamity", "name": "天地大劫",
			"event_type": "yearly", "probability": 0.15,
			"trigger_condition": {"min_year": 5},
			"description": "天地间灵气紊乱，一道道天雷劈下，高阶修士首当其冲。",
			"choices": [
				{
					"text": "正面抵抗",
					"requirements": {"min_realm": 4},
					"outcomes": [
						{"probability": 0.4, "text": "你成功抵御天劫，修为更进一步！", "effects": [
							{"type": "add_exp", "value": 2000},
							{"type": "breakthrough_boost", "value": 0.2}
						]},
						{"probability": 0.6, "text": "天劫威力巨大，你身受重伤。", "effects": [
							{"type": "damage", "value": 200}
						]}
					]
				},
				{
					"text": "闭关躲劫",
					"outcomes": [
						{"probability": 0.7, "text": "你躲在阵法中安然度过。", "effects": [
							{"type": "add_exp", "value": 500}
						]},
						{"probability": 0.3, "text": "阵法被天劫击破，你受到波及。", "effects": [
							{"type": "damage", "value": 80}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "yearly_ascend", "name": "飞升契机",
			"event_type": "yearly", "probability": 0.1,
			"trigger_condition": {"min_year": 10},
			"description": "天地感应，一股神秘力量降临，金丹以上修士或有飞升契机。",
			"choices": [
				{
					"text": "尝试突破",
					"requirements": {"min_realm": 3},
					"outcomes": [
						{"probability": 0.3, "text": "天地共鸣，你感悟到飞升的真谛！", "effects": [
							{"type": "breakthrough_boost", "value": 0.5},
							{"type": "add_exp", "value": 5000}
						]},
						{"probability": 0.7, "text": "时机未到，未能突破瓶颈。", "effects": [
							{"type": "add_exp", "value": 1000}
						]}
					]
				},
				{
					"text": "静待机缘",
					"outcomes": [
						{"probability": 1.0, "text": "你默默等待，内心更加坚定。", "effects": [
							{"type": "add_exp", "value": 300}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "yearly_century", "name": "百年庆典",
			"event_type": "yearly", "probability": 0.2,
			"trigger_condition": {"min_year": 1},
			"description": "修仙界迎来百年庆典，各地张灯结彩，修士们欢聚一堂。",
			"choices": [
				{
					"text": "参与庆典",
					"outcomes": [
						{"probability": 1.0, "text": "庆典上获赠灵丹，全属性小幅提升！", "effects": [
							{"type": "add_exp", "value": 1500},
							{"type": "heal", "value": 100}
						]}
					]
				},
				{
					"text": "闭关修炼",
					"outcomes": [
						{"probability": 1.0, "text": "别人欢庆时你潜心修炼，修为稳步提升。", "effects": [
							{"type": "add_exp", "value": 2000}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "yearly_tide", "name": "妖潮来袭",
			"event_type": "yearly", "probability": 0.2,
			"trigger_condition": {"min_year": 3},
			"description": "大批妖兽从深山涌出，形成妖潮向人族领地袭来！",
			"choices": [
				{
					"text": "率众御敌",
					"requirements": {"min_realm": 2},
					"outcomes": [
						{"probability": 0.5, "text": "成功击退妖潮，缴获大量妖兽内丹！", "effects": [
							{"type": "add_item", "id": "item_beast_core"},
							{"type": "add_item", "id": "item_beast_core"},
							{"type": "add_resource", "id": "prestige", "value": 80}
						]},
						{"probability": 0.5, "text": "妖潮凶猛，防线被突破，损失惨重。", "effects": [
							{"type": "damage", "value": 150},
							{"type": "add_resource", "id": "spirit_stone", "value": -200}
						]}
					]
				},
				{
					"text": "固守不出",
					"outcomes": [
						{"probability": 0.6, "text": "阵法坚固，妖潮无功而返。", "effects": [
							{"type": "add_exp", "value": 500}
						]},
						{"probability": 0.4, "text": "妖兽破阵而入，你勉强抵挡。", "effects": [
							{"type": "damage", "value": 60}
						]}
					]
				}
			]
	})
	_add_event({
			"id": "yearly_taizu", "name": "道祖讲道",
			"event_type": "yearly", "probability": 0.15,
			"trigger_condition": {"min_year": 5},
			"description": "传说中的道祖现身讲道，天地间灵气涌动，万物聆听。",
			"choices": [
				{
					"text": "虔诚聆听",
					"outcomes": [
						{"probability": 0.6, "text": "道祖之道博大精深，你获益匪浅！", "effects": [
							{"type": "add_exp", "value": 3000},
							{"type": "breakthrough_boost", "value": 0.3}
						]},
						{"probability": 0.4, "text": "道境太高，你只能领悟皮毛。", "effects": [
							{"type": "add_exp", "value": 1000}
						]}
					]
				},
				{
					"text": "默默感悟",
					"outcomes": [
						{"probability": 1.0, "text": "你静心感悟，收获不少。", "effects": [
							{"type": "add_exp", "value": 1500}
						]}
					]
				}
			]
	})


func _load_alchemy_recipes() -> void:
	alchemy_recipes.clear()
	_add_alchemy_recipe({
		"id": "recipe_huoyandan", "name": "火焰丹",
		"ingredients": {"item_huoshi": 3, "item_lingshi": 100},
		"result": "item_huoyandan",
		"result_count": 1,
		"success_rate": 0.8,
		"required_level": 5,
		"description": "以火石炼制，服用后短暂提升攻击力"
	})
	_add_alchemy_recipe({
		"id": "recipe_huoyan丹", "name": "养气丹",
		"ingredients": {"item_lingshi": 50},
		"result": "item_jiuxuan",
		"result_count": 1,
		"success_rate": 0.6,
		"required_level": 3,
		"description": "灵石炼化的基础丹药"
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
		# 修炼相关
		"base_cultivation_exp": 10,
		"min_breakthrough_rate": 0.01,
		"max_breakthrough_rate": 0.95,
		"max_inventory_slots": 50,
		# 战斗相关
		"base_crit_rate": 0.05,
		"base_crit_damage": 1.5,
		"dodge_base": 0.05,
		# 寿命相关
		"base_lifespan": 80,
		"lifespan_per_realm": 50,
	}
	# 设置别名，供 DataManager.constants.xxx 访问
	constants = game_constants


# ==================== 添加数据 ====================

func _add_realm(data: Dictionary) -> void:
	realms[data.get("id", "")] = data


func _add_technique(data: Dictionary) -> void:
	techniques[data.get("id", "")] = data


func _add_skill(data: Dictionary) -> void:
	skills[data.get("id", "")] = data


func _add_item(data: Dictionary) -> void:
	items[data.get("id", "")] = data


func _add_event(data: Dictionary) -> void:
	events[data.get("id", "")] = data


func _add_alchemy_recipe(data: Dictionary) -> void:
	alchemy_recipes[data.get("id", "")] = data


# ==================== 数据获取 ====================

func get_realm(id: String) -> Dictionary:
	return realms.get(id, {})


func get_technique(id: String) -> Dictionary:
	return techniques.get(id, {})


func get_skill(id: String) -> Dictionary:
	return skills.get(id, {})


func get_item(id: String) -> Dictionary:
	return items.get(id, {})


func get_event(id: String) -> Dictionary:
	return events.get(id, {})


func get_alchemy_recipe(id: String) -> Dictionary:
	return alchemy_recipes.get(id, {})


## 获取下一个境界 - 按 order 顺序查找
func get_next_realm(current_realm_id: String) -> Dictionary:
	var current = realms.get(current_realm_id, {})
	if current.is_empty():
		return {}
	var current_order = current.get("order", -1)
	var best_realm: Dictionary = {}
	var best_order: int = 999999
	for realm_id in realms:
		var realm = realms[realm_id]
		var r_order = realm.get("order", 0)
		if r_order > current_order and r_order < best_order:
			best_order = r_order
			best_realm = realm
	return best_realm


func get_all_realms() -> Array:
	return realms.values()


func get_all_techniques() -> Array:
	return techniques.values()


func get_all_skills() -> Array:
	return skills.values()


func get_all_items() -> Array:
	return items.values()


func get_all_events() -> Array:
	return events.values()


func _get_all_alchemy_recipes() -> Array:
	return alchemy_recipes.values()


func get_techniques_by_tier(tier: int) -> Array:
	var result: Array = []
	for tech in techniques.values():
		if tech.get("tier", 0) == tier:
			result.append(tech)
	return result


func get_skills_by_target_type(target_type: String) -> Array:
	var result: Array = []
	for sk in skills.values():
		if sk.get("target_type", "") == target_type:
			result.append(sk)
	return result


func _get_constant(key: String):
	return game_constants.get(key, null)




func get_data(key: String):
	return _db.get_data(key)


func get_sects() -> Dictionary:
	return _db.get_sects()


func get_dungeons() -> Dictionary:
	return _db.get_dungeons()


func get_daily_activities() -> Dictionary:
	return _db.get_daily_activities()


func get_spirit_beasts() -> Dictionary:
	return _db.get_spirit_beasts()


func get_equipment_sets() -> Dictionary:
	return _db.get_equipment_sets()
