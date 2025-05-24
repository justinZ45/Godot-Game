extends Control
@onready var flowmentum_bar: ProgressBar = $flowmentumBar
@onready var game_manager: Node = %GameManager


func _ready():
	game_manager.score_updated.connect(_on_score_updated)
	flowmentum_bar.value = game_manager.score

func _on_score_updated(new_score: int): 
	print("Score updated in HUD:", new_score)
	flowmentum_bar.value = new_score
