extends Control

var combo_active = false
@onready var combo_timer: Timer = $combo_timer
@onready var combo_label: Label = $combo_label
@onready var momentum_bar: ProgressBar = $"../MomentumUI/momentumBar"
@onready var timer_bar: ProgressBar = $timer_bar


func _ready():
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	timer_bar.visible = false
	combo_label.visible = false
	GameManager.combo_count_updated.connect(add_combo)
	
func _process(delta):
	timer_bar.value = combo_timer.time_left


func add_combo(new_combo_count: int):
	if GameManager.combo_count <= 0:
		GameManager.combo_count = 0
		combo_active = false
		combo_label.visible = false
		timer_bar.visible = false
		combo_timer.stop()

		
	elif not combo_active:
		GameManager.combo_count = 1
		combo_active = true
		combo_label.visible = true
		timer_bar.visible = true
		combo_label.text = "COMBO  X%d" % GameManager.combo_count
		combo_timer.start(2.5)  # 2 seconds window


		
	else:
		combo_label.text = "COMBO  X%d" % GameManager.combo_count

		# Restart the combo timer
		combo_timer.start(2.0)  # 2 seconds window
	
	
func _on_combo_timer_timeout():
	if combo_active:
		# Add to momentum meter
		var momentum_gain = GameManager.combo_count * 3  # scale this value
		GameManager.add_momentum(momentum_gain)

		# Reset combo
		GameManager.combo_count = 0
		combo_active = false
		timer_bar.visible = false
		combo_label.visible = false
