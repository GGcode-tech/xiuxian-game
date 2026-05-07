## 游戏启动器 - 初始化新游戏
class_name GameStarter extends Node

# 信号
signal game_initialized


func start_new_game(family_name: String, founder_name: String) -> void:
	# 创建家族
	var family = FamilyData.new()
	family.id = "player_family"
	family.name = family_name
	family.founded_year = 1
	family.level = 1
	
	# 创建创始人
	var founder = CharacterGenerator.generate_character(
		family.id,
		1,  # 第一代
		[],  # 无父母
		0   # 男性
	)
	founder.name = founder_name
	founder.age = 20
	founder.realm_id = "refining_qi"
	founder.realm_exp = 0
	founder.spirit_root = {"gold": 0.2, "wood": 0.8, "water": 0.3, "fire": 0.1, "earth": 0.2}
	founder.main_technique_id = "azure_essence_art"
	founder.learn_technique("azure_essence_art")
	founder.recalculate_stats()
	
	family.founder_id = founder.id
	family.add_member(founder.id)
	
	# 创建初始配偶
	var spouse = CharacterGenerator.generate_character(
		family.id,
		1,
		[],
		1  # 女性
	)
	spouse.age = 18
	spouse.realm_id = "refining_qi"
	spouse.realm_exp = 0
	spouse.spouse_id = founder.id
	founder.spouse_id = spouse.id
	spouse.learn_technique("ice_soul_art")
	spouse.recalculate_stats()
	
	family.add_member(spouse.id)
	
	# 创建2-3个初始族人
	for i in range(randi_range(2, 3)):
		var member = CharacterGenerator.generate_character(
			family.id,
			1
		)
		member.age = randi_range(15, 40)
		member.realm_id = "mortal"
		member.learn_technique("basic_cultivation")
		member.recalculate_stats()
		family.add_member(member.id)
	
	# 注册到GameManager
	GameManager.add_character(founder)
	GameManager.add_character(spouse)
	GameManager.player_family_id = family.id
	GameManager.add_family(family)
	
	# 注册其他族人
	for member_id in family.members:
		if member_id != founder.id and member_id != spouse.id:
			var member = GameManager.get_character(member_id)
			if member:
				GameManager.add_character(member)
	
	# 初始化地图
	GameManager.map_data = MapData.new()
	GameManager.map_data.initialize()
	
	# 分配初始领地
	var starting_territory = GameManager.map_data.get_territory("territory_2_2")
	if starting_territory:
		starting_territory.owner_id = family.id
		family.territories.append(starting_territory.id)
		family.main_territory_id = starting_territory.id
	
	# 初始化游戏时间
	GameManager.game_time.year = 1
	GameManager.game_time.month = 1
	GameManager.game_time.day = 1
	
	# 初始化资源
	family.resources = {
		"spirit_stone": 1000,
		"spirit_grass": 50,
		"spirit_ore": 0,
		"blood_essence": 0,
		"contribution": 0
	}
	
	game_initialized.emit()
	
	EventManager.add_notification(
		"家族成立",
		"%s 在灵气充沛之地建立了 %s ，开启了修仙之路！" % [founder_name, family_name],
		"success"
	)


func load_game(save_slot: String) -> bool:
	var result = SaveManager.load_game(save_slot)
	return result
