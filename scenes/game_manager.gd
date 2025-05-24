extends Node

var score: int = 0
signal score_updated(new_score: int)

func add_score(amount: int):
	score += amount
	print(score)
	emit_signal("score_updated", score)
