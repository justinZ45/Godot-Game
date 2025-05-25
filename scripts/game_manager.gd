extends Node

var combo_count: int = 0
var momentum: int = 0

signal momentum_updated(new_momentum: int)
signal combo_count_updated(new_combo_count: int)


# In GameManager.gd
func add_momentum(amount: int):
	momentum += amount
	if momentum < 0:
		momentum = 0
	if momentum > 50:
		momentum = 50
	
	emit_signal("momentum_updated", momentum)


func add_combo_hit(amount: int):
	print("combo updated: ", combo_count)
	combo_count += amount
	emit_signal("combo_count_updated", amount)
