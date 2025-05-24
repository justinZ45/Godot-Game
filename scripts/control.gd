extends Control

var combo_active = false
@onready var combo_timer: Timer = $combo_timer
@onready var combo_label: Label = $combo_label
@onready var flowmentum_bar: ProgressBar = $"../ScoreUI/flowmentumBar"


func _ready():
	combo_timer.timeout.connect(_on_combo_timer_timeout)
	combo_label.visible = false
	GameManager.combo_count_updated.connect(add_combo)


func add_combo():
	print("combo added")
	if not combo_active:
		GameManager.combo_count = 1
		combo_active = true
		combo_label.visible = true
		
	combo_label.text = "Combo: %d" % GameManager.combo_count

	# Restart the combo timer
	combo_timer.start(4.0)  # 2 seconds window
	
	
func _on_combo_timer_timeout():
	if combo_active:
		# Add to momentum meter
		var momentum_gain = GameManager.combo_count * 3  # scale this value
		GameManager.add_score(momentum_gain)

		# Reset combo
		GameManager.combo_count = 0
		combo_active = false
		combo_label.visible = false
