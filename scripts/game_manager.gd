extends Node

var combo_count: int = 0
var score: int = 0

signal score_updated(new_score: int)
signal combo_count_updated()


# In GameManager.gd
func add_score(amount: int):
	score += amount
	emit_signal("score_updated", score)


func add_combo_hit():
	print("combo updated: ", combo_count)
	combo_count += 1
	emit_signal("combo_count_updated")
