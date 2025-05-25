extends Control

@onready var momentum_bar: ProgressBar = $momentumBar

func _ready():
	GameManager.momentum_updated.connect(_on_momentum_updated)
	momentum_bar.value = GameManager.momentum 

func _on_momentum_updated(new_momentum: int): 
	momentum_bar.value = new_momentum
	if momentum_bar.value < 0:
		momentum_bar.value = 0
	if momentum_bar.value > 50:
		momentum_bar.value = 50
