class_name PhysicsComponent
extends Component

@export var body: CharacterBody2D
@export_group("physics")
@export var gravity_force: float = 100.0
@export var terminal_speed: float = 1000.0
@export var deceleration: int = 1

var animator: AnimatorComponent

func get_dependencies() -> Dictionary:
	return {"AnimatorComponent": "animator"}

func apply_gravity(force = null, max_speed = null):
	var _force = force if force is float else gravity_force
	var _max_speed = max_speed if max_speed is float else terminal_speed
	body.velocity += body.up_direction * -_force
	body.velocity = body.velocity.clampf(-_max_speed, _max_speed)

func update_flip():
	if body.velocity.x < 0:
		animator.animated_sprite.flip_h = true
	elif body.velocity.x > 0:
		animator.animated_sprite.flip_h = false

func decelerate():
	if body.velocity.x > -deceleration and body.velocity.x < deceleration:
		body.velocity.x = 0
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, deceleration)

func immobile() -> bool:
	return body.velocity == Vector2.ZERO

func update(gravity: bool = true):
	if gravity:
		apply_gravity()
	update_flip()
	if body.is_on_floor():
		decelerate()
	body.move_and_slide()
