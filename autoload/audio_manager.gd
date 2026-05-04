## 音频管理器 - 管理背景音乐和音效
## 支持音量控制、渐入渐出、音效池
extends Node

# ==================== 配置 ====================
var master_volume: float = 1.0
var bgm_volume: float = 0.8
var sfx_volume: float = 1.0

# ==================== 音频节点 ====================
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 16

# ==================== 当前状态 ====================
var current_bgm: String = ""
var is_bgm_playing: bool = false


func _ready() -> void:
	_create_audio_players()
	_load_settings()
	print("[AudioManager] 初始化完成")


func initialize() -> void:
	# _ready()已经完成了初始化，这里仅作兼容接口
	pass


func _create_audio_players() -> void:
	# 创建BGM播放器
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	
	# 创建SFX播放器池
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		sfx_players.append(player)
		add_child(player)


# ==================== BGM管理 ====================

func play_bgm(bgm_id: String, fade_duration: float = 1.0) -> void:
	if current_bgm == bgm_id and is_bgm_playing:
		return
	
	var bgm_path = "res://audio/bgm/%s.ogg" % bgm_id
	
	if not ResourceLoader.exists(bgm_path):
		push_warning("[AudioManager] BGM不存在: " + bgm_id)
		return
	
	var stream = load(bgm_path)
	
	# 渐出当前BGM
	if bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
		await tween.finished
		bgm_player.stop()
	
	# 播放新BGM
	bgm_player.stream = stream
	bgm_player.volume_db = -40.0
	bgm_player.play()
	
	# 渐入
	var tween_in = create_tween()
	tween_in.tween_property(bgm_player, "volume_db", linear_to_db(bgm_volume), fade_duration)
	
	current_bgm = bgm_id
	is_bgm_playing = true


func stop_bgm(fade_duration: float = 1.0) -> void:
	if not bgm_player.playing:
		return
	
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -40.0, fade_duration)
	await tween.finished
	
	bgm_player.stop()
	current_bgm = ""
	is_bgm_playing = false


func pause_bgm() -> void:
	bgm_player.stream_paused = true


func resume_bgm() -> void:
	bgm_player.stream_paused = false


# ==================== SFX管理 ====================

func play_sfx(sfx_id: String, volume_scale: float = 1.0) -> void:
	var sfx_path = "res://audio/sfx/%s.wav" % sfx_id
	
	if not ResourceLoader.exists(sfx_path):
		# 尝试ogg格式
		sfx_path = "res://audio/sfx/%s.ogg" % sfx_id
		if not ResourceLoader.exists(sfx_path):
			push_warning("[AudioManager] SFX不存在: " + sfx_id)
			return
	
	var stream = load(sfx_path)
	var player = _get_available_sfx_player()
	
	if player:
		player.stream = stream
		player.volume_db = linear_to_db(sfx_volume * volume_scale)
		player.play()


func _get_available_sfx_player() -> AudioStreamPlayer:
	# 优先找空闲的播放器
	for player in sfx_players:
		if not player.playing:
			return player
	
	# 全部占用时，使用第一个（覆盖最旧的）
	return sfx_players[0]


# ==================== 音量控制 ====================

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	_save_settings()


func set_bgm_volume(volume: float) -> void:
	bgm_volume = clamp(volume, 0.0, 1.0)
	if bgm_player.playing:
		bgm_player.volume_db = linear_to_db(bgm_volume)
	_save_settings()


func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_save_settings()


func linear_to_db(volume: float) -> float:
	if volume <= 0.0:
		return -80.0
	return log(volume) * 8.685889638065037  # 20 * log10(volume)


# ==================== 设置持久化 ====================

func _save_settings() -> void:
	var settings = {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume
	}
	
	var file = FileAccess.open("user://audio_settings.cfg", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings))
		file.close()


func _load_settings() -> void:
	var file = FileAccess.open("user://audio_settings.cfg", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var settings = json.data
			master_volume = settings.get("master_volume", 1.0)
			bgm_volume = settings.get("bgm_volume", 0.8)
			sfx_volume = settings.get("sfx_volume", 1.0)
		file.close()
	
	# 应用音量设置
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
