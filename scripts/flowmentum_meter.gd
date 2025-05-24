extends TextureProgressBar

var flowmentum: int = 0
const MAX_FLOWMENTUM: int = 100
const MIN_FLOWMENTUM: int = 0

var in_flowmentum_mode: bool = false

signal flowmentum_changed(new_value: int)
signal flowmentum_mode_started
signal flowmentum_mode_ended

func _set_flowmentum(value: int) -> void:
	flowmentum = clamp(value, MIN_FLOWMENTUM, MAX_FLOWMENTUM)
	emit_signal("flowmentum_changed", flowmentum)
	_check_mode_state()

func add_flowmentum(amount: int) -> void:
	_set_flowmentum(flowmentum + amount)

func lose_flowmentum(amount: int) -> void:
	_set_flowmentum(flowmentum - amount)

func _check_mode_state():
	if flowmentum >= MAX_FLOWMENTUM and not in_flowmentum_mode:
		in_flowmentum_mode = true
		emit_signal("flowmentum_mode_started")
	elif flowmentum < MAX_FLOWMENTUM and in_flowmentum_mode:
		in_flowmentum_mode = false
		emit_signal("flowmentum_mode_ended")
