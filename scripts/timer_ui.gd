extends Control

@onready var timer_label: Label = $timer_label
@onready var game_timer: Timer = $game_timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_timer.start(180)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer_label.set_text(str(game_timer.get_time_left()).pad_decimals(1))
