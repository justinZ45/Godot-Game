extends Control

@onready var flowmentum_bar: ProgressBar = $flowmentumBar

func _ready():
	GameManager.score_updated.connect(_on_score_updated)
	flowmentum_bar.value = GameManager.score

func _on_score_updated(new_score: int): 
	print("Score updated in HUD:", new_score)
	flowmentum_bar.value = new_score
