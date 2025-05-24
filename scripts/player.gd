extends CharacterBody2D

# Basic movement variables
const BASESPEED = 150.0
var SPEED = 170
const  DASHSPEED = 110.0
const CROUCH_SPEED = 50.0
const JUMP_VELOCITY = -320.0
const WALL_SLIDING_SPEED = 10.0
const ENEMY_LAYER_BIT = 1 << 1  # Layer 2
const GROUND_LAYER_BIT = 1 << 3  # Layer 4
var direction: int = 0
var original_collision_mask: int = 0
var is_invulnerable: bool = false




@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var basic_sword_hitbox: Area2D = $attack_hitboxes/basic_sword_hitbox
@onready var collision_shape: CollisionShape2D = $player_hitbox
@onready var head_check: RayCast2D = $raycasts/head_check
@onready var grabhandraycast: RayCast2D = $raycasts/grabhandraycast
@onready var grabcheckraycast: RayCast2D = $raycasts/grabcheckraycast
@onready var wallslideraycast: RayCast2D = $raycasts/wallslideraycast


@onready var dash_timer: Timer = $timers/dash_timer
@onready var roll_reset: Timer = $timers/roll_reset
@onready var combo_reset_timer: Timer = $timers/comboResetTimer
@onready var charge_flash_timer: Timer = $timers/charge_flash_timer


enum States { IDLE, RUNNING, JUMPING, MIDAIR, FALLING, ATTACKING, 
CROUCHED, SLIDING, GRABBING,
 AIR_DASHING, ROLLING, WALL_SLIDE, CHARGED }

var state: States = States.IDLE

# Attack variables
var current_attack_name: String = ""
var current_hitbox_node: Node = null
var current_attack_config = {}
var attack_type :=""
var combo_reset_time_basic := 1.0
var combo_reset_time_aerial := 2.0
var original_damage = {}
var attack_button_held := false
var attack_hold_time := 0.0
const CHARGE_ATTACK_THRESHOLD := 1.0
var is_charge_attack_ready := false




# slide variables
var slide_velocity := 250.0
var slide_duration := 0.5
var slide_timer := 0.0
var slide_direction := 0
var can_slide := true

# crouch variables
var is_crouching := false
var original_shape: Shape2D
var crouch_shape: Shape2D

# dash variables
var can_dash = true
var dash_duration:= 0.5
var roll_duration:= 0.5
var roll_reset_duration = 1.5
var max_dash_in_air = 1
var dashes_in_air = 0
var dash_gravity_reduction = -100
var can_roll = true
var dash_direction := 1

# Wall Slide and Wall Jump variables
var on_wall: bool = false  # Whether the player is touching a wall
var falling: bool = false  # Whether the player is falling
var pushing_against_wall: bool = false  # Whether the player is pushing against the wall
var original_wallslide_dir := ""
var cur_wallslide_dir := ""
var original_offset: Vector2
var num_wall_jumps := 0




# Attack configuration dictionary
var attack_configs = {
	"slide_attack": {
		"animation": "slide",
		"hitbox_on": 0,
		"hitbox_off": 3,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"attack_score": 1,
		"damage": 2,
		"hit_effect": {
			"knockback": Vector2(-60, -70),
			"hit_stop": 0.07,
			"enemy_stun":  1.0
		}
	},
	"basic_attack_1": {
		"animation": "basic_attack_1",
		"hitbox_on": 3,
		"hitbox_off": 5,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"next": "basic_attack_2",
		"move_speed": 20,
		"attack_score": 2,  
		"damage": 2,
		"hit_effect": {
			"knockback": Vector2(5, 0),
			"hit_stop": 0.07,
			"enemy_stun":  1.0
		}
	},
	"basic_attack_2": {
		"animation": "basic_attack_2",
		"hitbox_on": 1,
		"hitbox_off": 3,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"next": "basic_attack_3",
		"move_speed": 20,  
		"attack_score": 2,
		"damage": 3,
		"hit_effect": {
			"knockback": Vector2(5, 0),
			"hit_stop": 0.07,
			"enemy_stun": 1.0
		}
	},
	"basic_attack_3": {
		"animation": "basic_attack_3",
		"hitbox_on": 2,
		"hitbox_off": 4,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"move_speed": 40,  
		"attack_score": 3,
		"damage": 5,
		"hit_effect": {
			"knockback": Vector2(60, -50),
			"hit_stop": 0.25,
			"enemy_stun":  1.0
		}
	},
	"basic_aerial_1": {
		"animation": "basic_attack_1",
		"hitbox_on": 1,
		"hitbox_off": 3,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"next": "basic_aerial_2",
		"move_speed": 20,  
		"attack_score": 2,
		"damage": 2,
		"hit_effect": {
			"knockback": Vector2(8, -115),
			"hit_stop": 0.07,
			"enemy_stun":  1.0
		}
	},
	"basic_aerial_2": {
		"animation": "basic_attack_2",
		"hitbox_on": 0,
		"hitbox_off": 3,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"next": "basic_aerial_3",
		"move_speed": 20, 
		"attack_score": 2, 
		"damage": 3,
		"hit_effect": {
			"knockback": Vector2(5, -100),
			"hit_stop": 0.07,
			"enemy_stun":  1.0
		}
	},
	"basic_aerial_3": {
		"animation": "basic_attack_3",
		"hitbox_on": 0,
		"hitbox_off": 5,
		"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
		"move_speed": 20,  
		"attack_score": 3,
		"damage":5,
		"hit_effect": {
			"knockback": Vector2(60, -50),
			"hit_stop": 0.25,
			"enemy_stun":  1.0
		}
	},
	"charge_attack": {
	"animation": "charge_attack",
	"hitbox_on": 2,
	"hitbox_off": 5,
	"hitbox_node": "attack_hitboxes/basic_sword_hitbox",
	"attack_score": 5,
	"damage": 7,
	"move_speed": 20,
	"hit_effect": {
		"knockback": Vector2(150, -20),
		"hit_stop": 0.5,
		"enemy_stun": 1.5
	}
}
}

func _ready() -> void:
	original_collision_mask = collision_mask
	original_shape = collision_shape.shape.duplicate()
	original_offset = animated_sprite.offset
	crouch_shape = original_shape.duplicate()
	crouch_shape.set("extents", original_shape.extents * Vector2(1, 0.5))
	for key in attack_configs.keys():
		original_damage[key] = attack_configs[key]["damage"]

func _physics_process(delta: float) -> void:
	_check_ledge_grab()
	
	if grabcheckraycast.target_position.x < 0:
		cur_wallslide_dir = 'left' 
	else:
		cur_wallslide_dir = 'right'

	if not is_on_floor() and (grabcheckraycast.is_colliding() && grabhandraycast.is_colliding() && wallslideraycast.is_colliding())  and velocity.y > 0 :
	# Player is touching a wall and falling
		
		if num_wall_jumps < 1:
			if grabcheckraycast.target_position.x < 0:
				original_wallslide_dir = 'left' 
			else:
				original_wallslide_dir = 'right'
			
			state = States.WALL_SLIDE  # Set to sliding state if you want
			can_dash = true
			
		elif original_wallslide_dir != cur_wallslide_dir:
			if grabcheckraycast.target_position.x < 0:
				original_wallslide_dir = 'left' 
			else:
				original_wallslide_dir = 'right' # Stop horizontal movement while sliding
			state = States.WALL_SLIDE  # Set to sliding state if you want
			can_dash = true

		else:
			print("Can't wall slide on same wall twice!")

		
	if attack_button_held:
		attack_hold_time += delta
		
		if attack_hold_time >= CHARGE_ATTACK_THRESHOLD and not is_charge_attack_ready:
			is_charge_attack_ready = true
			print("charged")
			# Change color to white (bright flash effect)
			
			# Start a timer to reset the flash effect after a brief moment
			state = States.CHARGED
			SPEED = 30  # Set to the slow speed when charging
			animated_sprite.play("charged")
			animated_sprite.modulate = Color(2, 2, 2)
			charge_flash_timer.start(.1)  # Flash lasts for 0.1 seconds

	# Handle charge state reset when jumping or sliding
	if state == States.JUMPING or state == States.SLIDING or state == States.FALLING or state == States.AIR_DASHING or state == States.CROUCHED :
		if is_charge_attack_ready:
			attack_button_held = false
			is_charge_attack_ready = false
			SPEED = BASESPEED  # Reset speed to normal when jumping/sliding
				

	# Ledge grab or other logic will continue as usual without interference
	if state == States.WALL_SLIDE:
		velocity.x=0
		velocity.y = min(velocity.y + WALL_SLIDING_SPEED * delta, WALL_SLIDING_SPEED)
		
		if(cur_wallslide_dir == 'left' and Input.is_action_just_pressed('move_right')):
			state = States.FALLING
			velocity += get_gravity() * delta
		
		if(cur_wallslide_dir == 'right' and Input.is_action_just_pressed('move_left')):
			state = States.FALLING
			velocity += get_gravity() * delta


		if Input.is_action_just_pressed("jump"):
			state = States.JUMPING
			velocity.y = JUMP_VELOCITY
			num_wall_jumps +=1
			
		if(cur_wallslide_dir == 'left'):
			animated_sprite.flip_h = false
		else:
			animated_sprite.flip_h = true
			
		if(grabcheckraycast.is_colliding() && grabhandraycast.is_colliding() && !wallslideraycast.is_colliding()):
			state = States.FALLING

		animated_sprite.play("wall_slide")  # Play the wall slide animation


		
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		

	if Input.is_action_just_pressed("jump") and ( is_on_floor() || state==States.GRABBING) and state != States.SLIDING and state != States.CHARGED:
		num_wall_jumps = 0

		if(dashes_in_air != 0):
			dashes_in_air = 0
			can_dash =true
			state = States.IDLE
		if state == States.GRABBING:
			animated_sprite.play("ledge_pull_up")

		if(!is_obstructed_above()):
			state = States.IDLE
			velocity.y = JUMP_VELOCITY
	
	if state == States.GRABBING:
		return
		
	direction = Input.get_axis("move_left", "move_right")
		
	var attack_move_speed = 40

	if state != States.ATTACKING:
		if direction != 0 and not (state in [States.ROLLING, States.SLIDING, States.AIR_DASHING, States.WALL_SLIDE]):
			
			animated_sprite.flip_h = direction < 0
			if animated_sprite.flip_h:
				basic_sword_hitbox.scale.x = -abs(basic_sword_hitbox.scale.x)
				grabcheckraycast.target_position.x = -abs(grabcheckraycast.target_position.x)
				grabhandraycast.target_position.x = -abs(grabhandraycast.target_position.x)
				wallslideraycast.target_position.x = -abs(wallslideraycast.target_position.x)


			else:
				basic_sword_hitbox.scale.x = abs(basic_sword_hitbox.scale.x)
				grabcheckraycast.target_position.x = abs(grabcheckraycast.target_position.x)
				grabhandraycast.target_position.x = abs(grabhandraycast.target_position.x)
				wallslideraycast.target_position.x = abs(wallslideraycast.target_position.x)



		if state == States.SLIDING:
			velocity.x = slide_direction * slide_velocity
			slide_timer -= delta
			if slide_timer <= 0:
				end_slide()
			move_and_slide()
			return
			
		if state == States.ROLLING || state == States.AIR_DASHING:
			velocity.x = dash_direction * SPEED
			move_and_slide()
			return
		

		var crouch_pressed = Input.is_action_pressed("crouch")
		if crouch_pressed and is_on_floor() and direction == 0 and state != States.CROUCHED and state != States.CHARGED:
			start_crouch()
		elif not crouch_pressed and state == States.CROUCHED and not is_obstructed_above():
			end_crouch()

		if state == States.CROUCHED:
			if direction != 0:
				velocity.x = direction * CROUCH_SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				animated_sprite.play("crouch")
		else:
			if direction != 0:
				velocity.x = direction * SPEED
				if is_on_floor():
					if state != States.ROLLING and state != States.CHARGED:
						state = States.RUNNING
						adjust_sprite_offset()
						animated_sprite.play("run")
					
					if Input.is_action_just_pressed("Dash") and can_roll and state != States.CHARGED:
						if direction != 0:
							dash_direction = direction
						else:
							dash_direction = -1 if animated_sprite.flip_h else 1
						can_roll = false
						state = States.ROLLING
						collision_shape.shape = crouch_shape
						position.y += original_shape.extents.y * 0.5
						SPEED = BASESPEED + DASHSPEED
						adjust_sprite_offset()
						animated_sprite.play("dash")
						collision_mask &= ~ENEMY_LAYER_BIT
						is_invulnerable = true
						dash_timer.start(roll_duration)
						roll_reset.start(roll_reset_duration)

			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if is_on_floor() and state != States.CROUCHED and state!= States.CHARGED:
					state = States.IDLE
					adjust_sprite_offset()
					animated_sprite.play("idle")

		if can_slide and Input.is_action_just_pressed("crouch") and direction != 0 and is_on_floor() and state != States.CHARGED:
			start_slide(direction)
			#start_attack(attack_configs["slide_attack"])

			move_and_slide()
			return

		if not is_on_floor():
			if Input.is_action_just_pressed("Dash") and can_dash:
				if direction != 0:
					dash_direction = direction
				else:
					dash_direction = -1 if animated_sprite.flip_h else 1
				can_dash = false
				state = States.AIR_DASHING
				dashes_in_air += 1
				velocity.y = dash_gravity_reduction
				SPEED = BASESPEED + DASHSPEED
				collision_mask &= ~ENEMY_LAYER_BIT
				is_invulnerable = true
				animated_sprite.play("dash")
				dash_timer.start(dash_duration)

			# Prevent overriding dash animation while it's active
			if state != States.AIR_DASHING and state != States.WALL_SLIDE and state != States.CHARGED:
				if velocity.y > 50:
					state = States.FALLING
					animated_sprite.play("fall")			
				else:
					collision_shape.shape = original_shape
					state = States.JUMPING
					animated_sprite.play("jump")
		
		
		
	
	if state != States.ATTACKING  and Input.is_action_just_pressed("aerial") and !is_obstructed_above() and state != States.CHARGED:
		attack_button_held = false
		is_charge_attack_ready = false

		if(attack_type != "aerial"):
			attack_type = "aerial"
		if	is_on_floor():
			current_attack_name = "aerial_attack_1"
		else:
			velocity.y = JUMP_VELOCITY + 180
		attack_move_speed = current_attack_config.get("move_speed", 40)
		if direction != 0:
			velocity.x = direction * attack_move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		if current_attack_name == "":
			current_attack_name = "basic_aerial_1"
		else:
			var current_config = attack_configs.get(current_attack_name, null)
			if current_config and current_config.has("next"):
				current_attack_name = current_config["next"]
			else:
				current_attack_name = "basic_aerial_1"

		if current_attack_name in attack_configs:
			print(current_attack_name)

			start_attack(attack_configs[current_attack_name])
			
	if Input.is_action_just_pressed("basic_attack") and is_on_floor() and state not in [States.ATTACKING, States.SLIDING, States.ROLLING]:
		attack_button_held = true
		attack_hold_time = 0.0
		is_charge_attack_ready = false

	# Release logic — decides between normal combo and charge attack
	if Input.is_action_just_released("basic_attack") and attack_button_held:
		attack_button_held = false

		if is_charge_attack_ready:
			# Launch spin attack
			is_charge_attack_ready = false
			state = States.ATTACKING
			current_attack_name = "charge_attack"
			attack_move_speed = current_attack_config.get("move_speed", 40)
			if direction != 0:
				velocity.x = direction * attack_move_speed
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
			attack_type = "charge"
			charge_flash_timer.stop()
			animated_sprite.modulate = Color(1, 1, 1)  # reset color
			start_attack(attack_configs["charge_attack"])
			SPEED = BASESPEED

		else:
			# Do basic combo attack if not already attacking
			if state not in [States.ATTACKING, States.SLIDING, States.ROLLING]:
				if attack_type != "basic":
					current_attack_name = ""
					attack_type = "basic"

					attack_move_speed = current_attack_config.get("move_speed", 40)
				if direction != 0:
					velocity.x = direction * attack_move_speed
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)

				if current_attack_name == "":
					current_attack_name = "basic_attack_1"
				else:
					var current_config = attack_configs.get(current_attack_name, null)
					if current_config and current_config.has("next"):
						current_attack_name = current_config["next"]
					else:
						current_attack_name = "basic_attack_1"

				if current_attack_name in attack_configs:
					start_attack(attack_configs[current_attack_name])
					combo_reset_timer.start(combo_reset_time_basic)
	


	move_and_slide()

func _process(delta: float) -> void:
	if state == States.ATTACKING or state == States.SLIDING and current_hitbox_node:
		var anim = animated_sprite.animation
		var frame = animated_sprite.frame
		if anim == current_attack_config["animation"]:
			if frame == current_attack_config["hitbox_on"]:
				current_hitbox_node.monitoring = true
			elif frame == current_attack_config["hitbox_off"]:
				current_hitbox_node.monitoring = false


		
func start_attack(config: Dictionary):
	if attack_type != "slide":
		state = States.ATTACKING
	current_attack_config = config
	animated_sprite.play(config["animation"])
	if config.has("hitbox_node"):
		current_hitbox_node = get_node(config["hitbox_node"])
	else:
		current_hitbox_node = null

func finish_attack():
	if current_hitbox_node:
		current_hitbox_node.monitoring = false
	current_hitbox_node = null
	if current_attack_name == "basic_aerial_1" :
		if is_on_floor():
			velocity.y = JUMP_VELOCITY - 100  # boost for uppercut
	state = States.IDLE

func _on_animated_sprite_2d_animation_finished() -> void:
	if state == States.ATTACKING and animated_sprite.animation == current_attack_config.get("animation", ""):
		finish_attack()

func get_current_attack_config() -> Dictionary:
	return current_attack_config

func start_slide(dir: int):
	state = States.SLIDING
	slide_timer = slide_duration
	slide_direction = dir
	can_slide = false
	collision_shape.shape = crouch_shape
	position.y += original_shape.extents.y * 0.5
	adjust_sprite_offset()
	animated_sprite.play("slide")

	# Start the slide attack here
	attack_type = "slide"
	current_attack_name = "slide_attack"
	start_attack(attack_configs["slide_attack"])

func end_slide():
	if current_hitbox_node:
		current_hitbox_node.monitoring = false
	current_hitbox_node = null
	if not is_obstructed_above():
		state = States.IDLE
		collision_shape.shape = original_shape
		can_slide = true
	else:
		start_crouch()

func start_crouch():
	state = States.CROUCHED
	can_slide = true

	collision_shape.shape = crouch_shape
	position.y += original_shape.extents.y * 0.5
	adjust_sprite_offset()
	animated_sprite.play("crouch")

func end_crouch():
	if is_obstructed_above():
		print("obstructed")
		return # Don't stand up into a ceiling
	state = States.IDLE
	collision_shape.shape = original_shape
	position.y -= original_shape.extents.y * 0.5
	adjust_sprite_offset()
	animated_sprite.play("idle")

func is_obstructed_above() -> bool:
	return head_check.is_colliding()



func _on_combo_reset_timer_timeout() -> void:
	current_attack_name = ""
	print("combo timeout")
	

	
func _check_ledge_grab():
	var checkHand = not grabhandraycast.is_colliding()
	var checkGrabHeight = grabcheckraycast.is_colliding()
	
	var canGrab = state == States.FALLING && checkHand && checkGrabHeight && state!=States.GRABBING && is_on_wall_only()
	
	if canGrab:
		state = States.GRABBING
		animated_sprite.play("ledge_grab")
	
	return canGrab
		


func adjust_sprite_offset():
	match state:
		States.ROLLING:
			animated_sprite.offset = Vector2(0, 3)
		States.CROUCHED:
			animated_sprite.offset = Vector2(0, -8)
		States.SLIDING:
			animated_sprite.offset = Vector2(0, -7)
		States.RUNNING:
			animated_sprite.offset = original_offset 
		States.IDLE:
			animated_sprite.offset = original_offset # Adjust for rolling animation
		# Add other cases for other animations
		
		
func _on_dash_timer_timeout() -> void:
	SPEED = BASESPEED
	collision_mask = original_collision_mask
	is_invulnerable = false

	if state==States.AIR_DASHING:
		velocity.y = abs(dash_gravity_reduction)
	if not is_obstructed_above():
		state = States.IDLE
		collision_shape.shape = original_shape
		can_slide = true
	else:
		
		start_crouch()

	
	if dashes_in_air >= max_dash_in_air:
		can_dash = false
	else:
		can_dash = true
		
		
		print("Max dashes reached!")
	

func _on_roll_reset_timeout() -> void:
	can_roll = true
	

func _on_flowmentum_mode_started():
	SPEED *= 1.5
	for attack in attack_configs.values():
		attack["damage"] *= 1.5
	$MomentumEffectParticles.emitting = true

func _on_flowmentum_mode_ended():
	SPEED = 150
	for key in attack_configs.keys():
		if original_damage.has(key):  # Ensure the key exists in original_damage
			attack_configs[key]["damage"] = original_damage[key]
	$MomentumEffectParticles.emitting = false
	


func _on_charge_flash_timer_timeout() -> void:
	if animated_sprite.modulate == Color(1, 1, 1):
		animated_sprite.modulate = Color(2, 2, 2)
	else:
		animated_sprite.modulate = Color(1, 1, 1)
