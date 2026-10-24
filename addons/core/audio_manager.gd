extends Node
## Global audio manager.
##
## Autoloaded as "AudioManager" by the FP Framework plugin. Centralises:
##   - music playback with crossfade on the "Music" bus,
##   - pooled one-shot 2D SFX on the "Effects" bus (UI clicks, etc.),
##   - fire-and-forget positional 3D SFX on the "Effects" bus.
##
## Bus volumes are still controlled by GameSettings; this manager only decides
## *how* sounds play, not how loud the buses are.

const MUSIC_BUS := "Music"
const SFX_BUS := "Effects"
const SFX_POOL_SIZE := 12
const MUSIC_CROSSFADE := 1.0

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

func _ready() -> void:
	# SFX/music should keep playing (or be controllable) while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_active_music = _music_a

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_sfx_pool.append(p)

func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = MUSIC_BUS
	add_child(p)
	return p

## Crossfade to a new music track. Pass null/stop_music() to fade out.
func play_music(stream: AudioStream, crossfade: float = MUSIC_CROSSFADE) -> void:
	if stream == null:
		stop_music(crossfade)
		return

	var from := _active_music
	var to := _music_b if _active_music == _music_a else _music_a

	to.stream = stream
	to.volume_db = -80.0
	to.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(to, "volume_db", 0.0, crossfade)
	if from.playing:
		tween.tween_property(from, "volume_db", -80.0, crossfade)
		tween.chain().tween_callback(from.stop)

	_active_music = to

## Fade out and stop the currently playing music.
func stop_music(fade: float = MUSIC_CROSSFADE) -> void:
	if not _active_music.playing:
		return
	var m := _active_music
	var tween := create_tween()
	tween.tween_property(m, "volume_db", -80.0, fade)
	tween.tween_callback(m.stop)

## Play a non-positional one-shot sound (UI clicks, notifications).
func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := _next_sfx_player()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()

## Play a positional one-shot sound at a world location. The temporary player is
## parented to the active scene so it uses the current 3D world, then frees itself.
func play_sfx_3d(stream: AudioStream, position: Vector3, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.bus = SFX_BUS
	p.stream = stream
	p.pitch_scale = pitch
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child(p)
	if p is Node3D:
		p.global_position = position
	p.play()
	p.finished.connect(p.queue_free)

func _next_sfx_player() -> AudioStreamPlayer:
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	return p
