extends Area2D
@onready var hit_effect_anim: AnimatedSprite2D = $hit_effect_anim


var player_ref: Node = null  # Set from the player

func _ready():
	hit_effect_anim.play("none")
	body_entered.connect(_on_body_entered)
	player_ref = get_parent().get_parent()
	
	
func _on_body_entered(body):
	if player_ref == null:
		return

	var current_attack = player_ref.get_current_attack_config()
	if current_attack == null:
		return

	if body.has_method("apply_hit") and body.state != body.States.DEAD and player_ref.state in[ player_ref.States.ATTACKING, player_ref.States.SLIDING]:
		var hit_effect = current_attack.get("hit_effect", {})
		var attack_score = current_attack.get("attack_score", 1)
		var attack_type = current_attack.get("animation")
		var damage = current_attack.get ("damage", {})
		damage = current_attack.get("damage", 1)
		body.apply_hit(hit_effect, damage, attack_type, attack_score, global_position)
		hit_effect_anim.play("hit")
		


func _on_hit_effect_anim_animation_finished() -> void:
	hit_effect_anim.play("none")
# Replace with function body.
