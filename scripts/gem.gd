extends Area2D

func _on_body_entered(body: Node2D) -> void:
	GameManager.add_momentum(200)
	queue_free()
