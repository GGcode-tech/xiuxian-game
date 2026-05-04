## 门派系统 - 门派选择、门派技能、门派贡献
extends Node

## 门派数据类
class SectData extends RefCounted:
	var id: String
	var name: String
	var novel_source: String
	var sect_type: int
	var description: String
	var bonus_stats: Dictionary
	var skills: Array[String]
	var partners: Array[String]
	var entry_requirements: Dictionary

## 门派贡献数据
class SectContribution extends RefCounted:
	var total_contribution: int = 0
	var weekly_contribution: int = 0
	var sect_rank: int = 1
	var accumulated_points: int = 0

## 门派类型枚举
enum SectType {
	None,
	Sect_YaoYao,
	Sect_HeCun,
	Sect_BaiLiu,
	Sect_CiYan,
	Sect_Qin,
	Sect_Qingxia,
	Sect_TianChuan,
	Sect_XiaoYao,
	Sect_WanJian,
	Sect_WuShuang,
}

## 信号
signal sect_joined(sect_id: String)
signal sect_left(sect_id: String)
signal contribution_changed(new_contribution: int)
signal sect_rank_up(new_rank: int)
signal skill_learned(skill_id: String)

## 门派配置数据
var sects_data: Dictionary = {}
var player_sect_id: String = ""
var player_contribution: SectContribution
var current_sect: SectData

func _init() -> void:
	_init_default_sects()

func _init_default_sects() -> void:
	var default_sects: Array = [
		{
			"id": "sect_yaoyao",
			"name": "掩月宗",
			"novel_source": "凡人修仙传",
			"sect_type": SectType.Sect_YaoYao,
			"description": "掩月宗是越国三大修仙门派之一，以炼丹和符箓闻名",
			"bonus_stats": {"spirit": 15, "max_mp": 20},
			"skills": ["skill_yanyan_blade", "skill_zhaohu"],
			"partners": ["韩立", "南宫婉"],
			"entry_requirements": {"min_realm": "筑基期", "min_age": 50}
		},
		{
			"id": "sect_yuanying",
			"name": "元婴殿",
			"novel_source": "凡人修仙传",
			"sect_type": SectType.Sect_HeCun,
			"description": "元婴殿是乱星海最神秘的势力之一",
			"bonus_stats": {"attack": 20, "max_hp": 50},
			"skills": ["skill_spirit_cultivation"],
			"partners": ["银月"],
			"entry_requirements": {"min_realm": "结丹期"}
		},
		{
			"id": "sect_wanjian",
			"name": "万剑宗",
			"novel_source": "星辰变",
			"sect_type": SectType.Sect_WanJian,
			"description": "以剑道闻名，御剑术独步天下",
			"bonus_stats": {"attack": 25, "speed": 10},
			"skills": ["skill_feijian", "skill_jianxin"],
			"partners": ["秦羽"],
			"entry_requirements": {"min_realm": "金丹期"}
		},
		{
			"id": "sect_qingxia",
			"name": "清虚观",
			"novel_source": "星辰变",
			"sect_type": SectType.Sect_Qingxia,
			"description": "正道领袖，以天机术和阵法著称",
			"bonus_stats": {"defense": 15, "max_mp": 30},
			"skills": ["skill_tianji", "skill_zhenfa"],
			"partners": ["侯费"],
			"entry_requirements": {"min_realm": "金丹期", "virtue": 50}
		},
		{
			"id": "sect_tianchuan",
			"name": "天策府",
			"novel_source": "诛仙",
			"sect_type": SectType.Sect_TianChuan,
			"description": "朝廷修仙势力，军旅风格",
			"bonus_stats": {"defense": 20, "max_hp": 40},
			"skills": ["skill_military_strategy"],
			"partners": ["张小凡"],
			"entry_requirements": {"min_realm": "筑基期"}
		},
		{
			"id": "sect_xiaoyao",
			"name": "逍遥派",
			"novel_source": "诛仙",
			"sect_type": SectType.Sect_XiaoYao,
			"description": "隐世门派，行事洒脱",
			"bonus_stats": {"speed": 20, "luck": 15},
			"skills": ["skill_xiaoyao_arts"],
			"partners": ["碧瑶"],
			"entry_requirements": {"min_realm": "筑基期", "special_trait": "xiaoyao"}
		}
	]
	for sect in default_sects:
		sects_data[sect["id"]] = sect
	player_contribution = SectContribution.new()

## 加载门派数据
func load_sects_from_db() -> void:
	var db = DataManager.get_data("sects")
	if db and db is Dictionary:
		for sect_id in db:
			sects_data[sect_id] = db[sect_id]

func get_sect(sect_id: String) -> SectData:
	if sects_data.has(sect_id):
		return _create_sect_data(sects_data[sect_id])
	return null

func get_all_sects() -> Array:
	var result: Array = []
	for sect_id in sects_data:
		result.append(_create_sect_data(sects_data[sect_id]))
	return result

func get_sects_by_novel(novel_name: String) -> Array:
	var result: Array = []
	for sect in sects_data.values():
		if sect.get("novel_source", "") == novel_name:
			result.append(_create_sect_data(sect))
	return result

func _create_sect_data(data: Dictionary) -> SectData:
	var sect = SectData.new()
	sect.id = data.get("id", "")
	sect.name = data.get("name", "")
	sect.novel_source = data.get("novel_source", "")
	sect.sect_type = data.get("sect_type", SectType.None)
	sect.description = data.get("description", "")
	sect.bonus_stats = data.get("bonus_stats", {})
	sect.skills = data.get("skills", [])
	sect.partners = data.get("partners", [])
	sect.entry_requirements = data.get("entry_requirements", {})
	return sect

## 加入门派
func join_sect(sect_id: String) -> bool:
	if sects_data.has(sect_id):
		player_sect_id = sect_id
		current_sect = get_sect(sect_id)
		player_contribution = SectContribution.new()
		sect_joined.emit(sect_id)
		_save_to_game_db()
		return true
	return false

## 离开门派
func leave_sect() -> void:
	if player_sect_id != "":
		sect_left.emit(player_sect_id)
		player_sect_id = ""
		current_sect = null
		player_contribution = SectContribution.new()
		_save_to_game_db()

## 获取玩家门派属性加成
func get_sect_bonus() -> Dictionary:
	if current_sect:
		return current_sect.bonus_stats.duplicate()
	return {}

## 增加贡献度
func add_contribution(amount: int, reason: String = "") -> void:
	player_contribution.total_contribution += amount
	player_contribution.weekly_contribution += amount
	player_contribution.accumulated_points += amount
	contribution_changed.emit(player_contribution.total_contribution)
	_check_rank_up()
	_save_to_game_db()

## 消耗贡献度
func use_contribution(amount: int) -> bool:
	if player_contribution.accumulated_points >= amount:
		player_contribution.accumulated_points -= amount
		contribution_changed.emit(player_contribution.total_contribution)
		_save_to_game_db()
		return true
	return false

func _check_rank_up() -> void:
	var new_rank = player_contribution.sect_rank
	if player_contribution.total_contribution >= 10000:
		new_rank = 4
	elif player_contribution.total_contribution >= 5000:
		new_rank = 3
	elif player_contribution.total_contribution >= 2000:
		new_rank = 2
	else:
		new_rank = 1
	if new_rank > player_contribution.sect_rank:
		player_contribution.sect_rank = new_rank
		sect_rank_up.emit(new_rank)

## 获取门派技能
func get_sect_skills() -> Array:
	if current_sect:
		return current_sect.skills.duplicate()
	return []

## 学习门派技能
func learn_sect_skill(skill_id: String) -> bool:
	if not current_sect:
		return false
	if skill_id in current_sect.skills:
		skill_learned.emit(skill_id)
		return true
	return false

## 获取招募伙伴列表
func get_available_partners() -> Array:
	if current_sect:
		return current_sect.partners.duplicate()
	return []

## 获取当前门派名称
func get_current_sect_name() -> String:
	if current_sect:
		return current_sect.name
	return "无"

## 获取门派类型名称
func get_sect_type_name(sect_type: SectType) -> String:
	match sect_type:
		SectType.Sect_YaoYao: return "掩月宗"
		SectType.Sect_HeCun: return "黄枫谷"
		SectType.Sect_BaiLiu: return "百机阁"
		SectType.Sect_CiYan: return "慈云寺"
		SectType.Sect_Qin: return "秦王朝"
		SectType.Sect_Qingxia: return "清虚观"
		SectType.Sect_TianChuan: return "天策府"
		SectType.Sect_XiaoYao: return "逍遥派"
		SectType.Sect_WanJian: return "万剑宗"
		SectType.Sect_WuShuang: return "无双城"
		_: return "未知"

## 每周重置
func weekly_reset() -> void:
	player_contribution.weekly_contribution = 0

## 保存数据
func _save_to_game_db() -> void:
	var save_data = {
		"player_sect_id": player_sect_id,
		"total_contribution": player_contribution.total_contribution,
		"weekly_contribution": player_contribution.weekly_contribution,
		"sect_rank": player_contribution.sect_rank,
		"accumulated_points": player_contribution.accumulated_points
	}
	SaveManager.set_data("sect_system", save_data)

## 加载数据
func load_from_save(data: Dictionary) -> void:
	player_sect_id = data.get("player_sect_id", "")
	player_contribution = SectContribution.new()
	player_contribution.total_contribution = data.get("total_contribution", 0)
	player_contribution.weekly_contribution = data.get("weekly_contribution", 0)
	player_contribution.sect_rank = data.get("sect_rank", 1)
	player_contribution.accumulated_points = data.get("accumulated_points", 0)
	if player_sect_id != "":
		current_sect = get_sect(player_sect_id)

## 获取玩家贡献等级名称
func get_contribution_rank_name() -> String:
	match player_contribution.sect_rank:
		1: return "普通弟子"
		2: return "核心弟子"
		3: return "长老"
		4: return "掌门"
		_: return "未知"
