extends RefCounted

const PATH: String = "user://noxsum_settings.cfg"

static func read_value(key: String, fallback: Variant) -> Variant:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	return config.get_value("presentation", key, fallback)

static func write_value(key: String, value: Variant) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(PATH)
	config.set_value("presentation", key, value)
	config.save(PATH)

static func sound_enabled() -> bool:
	return bool(read_value("sound", false))

static func bgm_volume() -> float:
	return clampf(float(read_value("bgm_volume", 100.0)), 0.0, 100.0)

static func se_volume() -> float:
	return clampf(float(read_value("se_volume", 100.0)), 0.0, 100.0)

static func volume_offset_db(percent: float) -> float:
	return -80.0 if percent <= 0.0 else linear_to_db(percent / 100.0)

static func apply_audio() -> void:
	var enabled: bool = sound_enabled()
	AudioServer.set_bus_mute(0, not enabled)
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var playlist: Node = tree.root.get_node_or_null("BgmPlaylist")
	if playlist != null and playlist.has_method("set_enabled"):
		playlist.call("set_volume", bgm_volume())
		playlist.call("set_enabled", enabled)

static func reduced_motion() -> bool:
	return bool(read_value("reduced_motion", false))
