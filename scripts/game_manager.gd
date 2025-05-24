extends Node

var score: int = 0
signal score_updated(new_score: int)
# In GameManager.gd
func add_score(amount: int):
	score += amount
	print("Score now:", score)
	emit_signal("score_updated", score)
