extends CanvasLayer

@onready var flowmentum_bar = $FlowmentumBar

func _ready():
	var fm = get_node("/flowmentum_meter")
	fm.connect("flowmentum_changed", Callable(self, "_on_flowmentum_changed"))
	fm.connect("flowmentum_mode_started", Callable(self, "_on_flowmentum_mode_started"))
	fm.connect("flowmentum_mode_ended", Callable(self, "_on_flowmentum_mode_ended"))

func _on_flowmentum_changed(value: int) -> void:
	flowmentum_bar.value = value

func _on_flowmentum_mode_started():
	flowmentum_bar.modulate = Color.ORANGE_RED  # Flash or glow effect here

func _on_flowmentum_mode_ended():
	flowmentum_bar.modulate = Color.WHITE
