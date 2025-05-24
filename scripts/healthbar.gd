extends Control


@onready var bar: ProgressBar = $ProgressBar

@export var max_value: int = 100

var current_value: int = max_value

func set_health(value: int):
	current_value = clamp(value, 0, max_value)
	bar.value = current_value

func set_max_health(value: int):
	max_value = value
	bar.max_value = value
	set_health(value)
