extends CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var healthbar: Control = $healthbar
@onready var shader_mat := animated_sprite.material as ShaderMaterial
@onready var slime_hitbox: CollisionShape2D = $slime_hitbox
@onready var slime_area: Area2D = $slime_area
@onready var hit_noise_basic_1: AudioStreamPlayer2D = $audio/hit_noise_basic_1
@onready var hit_noise_basic_2: AudioStreamPlayer2D = $audio/hit_noise_basic_2
@onready var hit_noise_basic_3: AudioStreamPlayer2D = $audio/hit_noise_basic_3
@onready var hit_noise_charge: AudioStreamPlayer2D = $audio/hit_noise_charge



@export var max_health: int = 15
var current_health: int = max_health
const GROUND_LAYER_BIT = 1 << 3

var direction: int = -1
var SPEED: float = 50.0

var BASE_SPEED = 50
var momentum = 0

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 2000.0  # Higher = faster knockback decay

# New hit cooldown variables
var is_hit: bool = false   # **New:** Flag to track if the character is in cooldown after hit
var hit_cooldown_timer: float = 0.0 # **New:** Timer to track the cooldown duration

enum States { ALIVE, DEAD}
var state: States = States.ALIVE


func _ready():
	timer.timeout.connect(_on_timer_timeout)
	healthbar.set_max_health(max_health)
	slime_area.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta: float) -> void:
	if is_hit:
		hit_cooldown_timer -= delta
		if hit_cooldown_timer <= 0:
			is_hit = false
			SPEED = BASE_SPEED  
			hit_cooldown_timer = 0
			
	# Apply gravity
	velocity.y += get_gravity().y * delta
	
	if(is_on_floor() and current_health > 0):
		animated_sprite.play("idle")

		velocity = Vector2.ZERO
		SPEED = BASE_SPEED

	# Regular movement only if not being knocked back horizontally
	if knockback_velocity.x == 0 and not is_hit and is_on_floor():  # **New:** Check if not in hit cooldown
		velocity.x = direction * SPEED
		knockback_velocity = Vector2.ZERO
	else:
		# If knockback is active, apply it to velocity
		velocity += knockback_velocity

	# Apply knockback
	velocity += knockback_velocity

	## Move and slide handles collision
	move_and_slide()

	# Decay knockback toward zero
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

func _on_timer_timeout():
	direction *= -1
	animated_sprite.flip_h = direction > 0

func take_damage(amount: int, attack_momentum:int, attack_type: String,  hit_effect: Dictionary = {},  attacker_position: Vector2 = Vector2.ZERO):
	is_hit = true   # **New:** Set flag to indicate that the character is hit
	hit_cooldown_timer = hit_effect["enemy_stun"]  # **New:** Start cooldown after hit
	SPEED = 0  # **New:** Stop movement temporarily during damage
	momentum = attack_momentum
	current_health -= amount
	healthbar.set_health(current_health)
	effect_manager.flash(animated_sprite, Color.WHITE, 0.2)
	

	if hit_effect.has("knockback"):
		var knockback: Vector2 = hit_effect["knockback"]
		# Flip knockback direction based on attacker position
		if attacker_position.x < global_position.x:
			knockback.x = abs(knockback.x)
		else:
			knockback.x = -abs(knockback.x)
		knockback_velocity = knockback
		
	GameManager.add_combo_hit(1)
	GameManager.add_momentum(momentum)
	
		

	if hit_effect.has("hit_stop"):
		get_tree().paused = true
		await get_tree().create_timer(hit_effect["hit_stop"]).timeout
		get_tree().paused = false
		
	if attack_type == 'basic_attack_1' or attack_type =='slide':
		hit_noise_basic_1.play()
	elif attack_type == 'basic_attack_2':
		hit_noise_basic_2.play()
	elif attack_type == 'basic_attack_3':
		hit_noise_basic_3.play()
	elif attack_type == 'charge_attack':
		hit_noise_charge.pitch_scale = 1.7
		hit_noise_charge.play()

	if current_health <= 0:
		state = States.DEAD
		velocity = Vector2.ZERO
		
		momentum = 5
		GameManager.add_momentum(momentum)


		knockback_velocity = Vector2.ZERO
		slime_area.collision_mask = 0
		collision_mask = GROUND_LAYER_BIT  # usually 1 << 3
		collision_layer = 0
		animated_sprite.play("death")
		await animated_sprite.animation_finished

		die()

func apply_hit(hit_effect: Dictionary, damage: int, attack_type: String, attack_momentum: int, attacker_position: Vector2 = Vector2.ZERO):
	take_damage(damage, attack_momentum, attack_type, hit_effect,  attacker_position)

func die():
	queue_free()
	

func _on_damage_area_body_entered(body: Node2D) -> void:
	if  body.has_method("take_damage"):
		var knockback_direction = (body.global_position - global_position).normalized()
		body.take_damage(knockback_direction)
