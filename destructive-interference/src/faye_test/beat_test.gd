class_name BeatTest
extends Sprite2D


var instrument_name: String
var lifespan: float


func _ready() -> void:
	$InstrumentName.text = instrument_name
	$Lifespan.wait_time = lifespan
	$Lifespan.start()


func load_data(note: Note):
	instrument_name = note.instrument.instrument_name
	lifespan = LevelManager.view_range


func _process(delta: float) -> void:
	var vspeed = 1080 / LevelManager.view_range
	position += Vector2(0, vspeed) * delta


func _on_lifespan_timeout() -> void:
	print(LevelManager.current_time)
	queue_free()
