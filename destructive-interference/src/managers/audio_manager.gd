extends Node2D



var JSON_SONGS: Dictionary[String, AudioStream] = {
	"res://levels/tutorial/tutorial.json": preload("res://levels/tutorial/tutorial! (120).mp3"),
	"res://levels/level2/level2.json": preload("res://levels/level2/demo a 4.mp3"),
	"res://levels/challenge1/challenge1.json": preload("res://levels/challenge1/challenge1.mp3"),
}


var SFX_MENU_SCROLL = preload("res://assets/sfx/menu/menu scroll.mp3")
var SFX_MENU_BACK = preload("res://assets/sfx/menu/btton back.mp3")
var SFX_MENU_SELECT = preload("res://assets/sfx/menu/btton foward.mp3")


var SFX_GOAL: Dictionary[String, AudioStream] = {
	"saw": preload("res://assets/sfx/level/goal/saw.mp3"),
	"sine": preload("res://assets/sfx/level/goal/sine.mp3"),
	"square": preload("res://assets/sfx/level/goal/square.mp3"),
	"triangle": preload("res://assets/sfx/level/goal/triangle.mp3"),
}

var SFX_LEVEL_END_DEFEAT = preload("res://assets/sfx/level/end/defeat.mp3")
var SFX_LEVEL_END_VICTORY = preload("res://assets/sfx/level/end/victory.mp3")

var SFX_MOVE_LEFT = preload("res://assets/sfx/level/player_move/left.mp3")
var SFX_MOVE_RIGHT = preload("res://assets/sfx/level/player_move/right.mp3")
var SFX_MOVE_JUMP = preload("res://assets/sfx/level/player_move/sfx jump.wav")


var SFX_BEAT_HITS_PLAYER: Array[AudioStream] = [
	preload("res://assets/sfx/level/beat/ouch/miss 1.mp3"),
	preload("res://assets/sfx/level/beat/ouch/miss 2.mp3"),
]


var master_volume_linear = 1.0


var active_player: AudioStreamPlayer


## Player used for menu song
@onready var menu_song_player := $MenuPlayer as AudioStreamPlayer

## Player used for level songs
@onready var level_song_player := $SongPlayer as AudioStreamPlayer

## Timer for crossfade
@onready var fade_timer := $FadeTimer as Timer



## connect transition state signal for pause effect
func _ready() -> void:
	GameManager.transitioned_game_state.connect(_on_game_state_transition)
	LevelManager.warmup_finished.connect(_on_warmup_end)


## men u
func switch_to_menu_song():
	if menu_song_player != active_player:
		fade_between_tracks(menu_song_player, menu_song_player.stream, level_song_player)


func fade_menu_song_out():
	fade_out(menu_song_player)


## switch to level son g
func switch_to_level_song(json_path: String):
	if !JSON_SONGS.has(json_path):
		return

	fade_between_tracks(level_song_player, JSON_SONGS[json_path], menu_song_player)


## fade between tracks
func fade_between_tracks(in_track: AudioStreamPlayer, in_stream: AudioStream, out_track: AudioStreamPlayer):
	if out_track != in_track:
		fade_out(out_track)

	fade_in(in_track, in_stream)


## fade in a track with a stream
func fade_in(player: AudioStreamPlayer, stream: AudioStream = null):
	if !stream:
		stream = player.stream

	player.stream = stream
	player.play()
	player.volume_linear = 0 if player != level_song_player else 1

	active_player = player

	var tween := get_tree().create_tween()
	tween.tween_property(player, "volume_linear", 1 * master_volume_linear, .1)


## fade a track out
func fade_out(player: AudioStreamPlayer):
	if !is_instance_valid(player):
		return

	var tween := get_tree().create_tween()
	tween.tween_property(player, "volume_linear", 0, .1)
	tween.tween_callback(player.stop)


func _on_game_state_transition(from: GameManager.GAME_STATE, to: GameManager.GAME_STATE):
	AudioServer.set_bus_effect_enabled(0, 0, [GameManager.GAME_STATE.PAUSED, GameManager.GAME_STATE.GAME_OVER].has(to))

	if from == GameManager.GAME_STATE.PAUSED && to == GameManager.GAME_STATE.IN_GAME:
		level_song_player.stream_paused = false
		fade_out(menu_song_player)
		active_player = level_song_player
	elif from == GameManager.GAME_STATE.IN_GAME && to == GameManager.GAME_STATE.PAUSED:
		level_song_player.stream_paused = true
		fade_in(menu_song_player)


func _on_warmup_end():
	if active_player != level_song_player:
		switch_to_level_song(LevelManager.current_level_json_file)


func _on_song_player_finished() -> void:
	#_loop_player(level_song_player)
	pass


func _on_menu_player_finished() -> void:
	#_loop_player(menu_song_player)
	pass


func loop_level_song():
	_loop_player(level_song_player)


func _loop_player(in_player: AudioStreamPlayer):
	if in_player != active_player:
		return

	in_player.stop()
	in_player.play()


## one shot helper function used to play SFX
func sfx_one_shot(
		in_stream: AudioStream,
		volume_mod := 1.0, pitch_mod := 1.0,
		## let the caller pass in a custom parent. otherwise nest in scene root
		parent: Node=null,
		## provide a func(AudioStreamPlayer) -> void to modify any properties you want
		sfx_player_customizer: Callable=func(_sfx_player) -> void: return,
):
	var sfx_player := AudioStreamPlayer.new()
	if parent == null:
		parent = get_tree().root
	parent.add_child(sfx_player)
	sfx_player.stream = in_stream
	sfx_player.bus = "SFX"
	sfx_player.volume_linear = 1 * master_volume_linear * volume_mod
	sfx_player.pitch_scale = pitch_mod
	sfx_player_customizer.call(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)
