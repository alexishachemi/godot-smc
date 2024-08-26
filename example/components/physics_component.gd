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

func apply_gravity():
	body.velocity += body.up_direction * -gravity_force
	body.velocity.clampf(-terminal_speed, terminal_speed)

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
