## 修仙小说设定数据库加载器
## 自动生成 - 包含12部经典修仙小说设定数据
extends Node

enum NovelSource {
	FANREN,   ## 凡人修仙传
	XINGCHEN, ## 星辰变
	ZHUXIAN,  ## 诛仙
	SHENGXU,  ## 圣墟
	PIAOMI,   ## 飘邈之旅
	WANMEI,   ## 完美世界
	DOULUO,   ## 斗罗大陆
	ZTIAN,    ## 遮天
	XIANNI,   ## 仙逆
	XUEZHONG, ## 雪中悍刀行
	DOUPO,    ## 斗破苍穹
	JIANLAI,  ## 剑来
}

const NOVEL_NAMES = {
	NovelSource.FANREN: "凡人修仙传",
	NovelSource.XINGCHEN: "星辰变",
	NovelSource.ZHUXIAN: "诛仙",
	NovelSource.SHENGXU: "圣墟",
	NovelSource.PIAOMI: "飘邈之旅",
	NovelSource.WANMEI: "完美世界",
	NovelSource.DOULUO: "斗罗大陆",
	NovelSource.ZTIAN: "遮天",
	NovelSource.XIANNI: "仙逆",
	NovelSource.XUEZHONG: "雪中悍刀行",
	NovelSource.DOUPO: "斗破苍穹",
	NovelSource.JIANLAI: "剑来",
}

var _database: Dictionary = {}

func _ready() -> void:
	_load_database()

func _load_database() -> void:
	var file = FileAccess.open("res://data/game_database.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var json_obj = JSON.new()
		if json_obj.parse(json_text) == OK:
			_database = json_obj.data
			print("[NovelDatabase] 加载成功，小说数: ", _database.get("novels_count", 0))

## 获取指定小说的境界体系
func get_realms(novel: NovelSource) -> Array:
	var name = NOVEL_NAMES.get(novel, "")
	return _database.get("realms", {}).get(name, [])

## 获取指定小说的功法技能
func get_techniques(novel: NovelSource) -> Array:
	var name = NOVEL_NAMES.get(novel, "")
	return _database.get("techniques", {}).get(name, [])

## 获取指定小说的物品丹药
func get_items(novel: NovelSource) -> Array:
	var name = NOVEL_NAMES.get(novel, "")
	return _database.get("items", {}).get(name, [])

## 获取指定小说的势力宗门
func get_sects(novel: NovelSource) -> Array:
	var name = NOVEL_NAMES.get(novel, "")
	return _database.get("sects", {}).get(name, [])

## 获取指定小说的人物
func get_characters(novel: NovelSource) -> Array:
	var name = NOVEL_NAMES.get(novel, "")
	return _database.get("characters", {}).get(name, [])

## 获取所有小说的境界体系
func get_all_realms() -> Dictionary:
	return _database.get("realms", {})

## 获取所有小说的功法技能
func get_all_techniques() -> Dictionary:
	return _database.get("techniques", {})

## 获取所有小说的物品丹药
func get_all_items() -> Dictionary:
	return _database.get("items", {})

## 获取所有小说的势力宗门
func get_all_sects() -> Dictionary:
	return _database.get("sects", {})

## 获取所有小说的人物
func get_all_characters() -> Dictionary:
	return _database.get("characters", {})

## 搜索所有小说中的境界(名称匹配)
func search_realm(name: String) -> Array:
	var results = []
	for novel_name in _database.get("realms", {}):
		for realm in _database["realms"][novel_name]:
			if typeof(realm) == TYPE_DICTIONARY and realm.get("name", "").find(name) >= 0:
				results.append({"novel": novel_name, "realm": realm})
	return results

## 搜索所有小说中的功法(名称匹配)
func search_technique(name: String) -> Array:
	var results = []
	for novel_name in _database.get("techniques", {}):
		for tech in _database["techniques"][novel_name]:
			if typeof(tech) == TYPE_DICTIONARY and tech.get("name", "").find(name) >= 0:
				results.append({"novel": novel_name, "technique": tech})
	return results

## 获取修仙体系概览(用于游戏选择界面)
func get_cultivation_systems_overview() -> Array:
	var overview = []
	for novel_key in NOVEL_NAMES:
		var novel_name = NOVEL_NAMES[novel_key]
		var realms = _database.get("realms", {}).get(novel_name, [])
		overview.append({
			"novel": novel_name,
			"realm_count": realms.size(),
			"technique_count": _database.get("techniques", {}).get(novel_name, []).size(),
			"item_count": _database.get("items", {}).get(novel_name, []).size(),
			"sect_count": _database.get("sects", {}).get(novel_name, []).size(),
			"character_count": _database.get("characters", {}).get(novel_name, []).size(),
		})
	return overview
