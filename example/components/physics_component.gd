class_name PhysicsComponent
extends SMCComponent

@export var body: CharacterBody2D
@export_group("physics")
@export var gravity_force: float = 100.0
@export var terminal_speed: float = 1000.0
@export var deceleration: int = 1

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent

func get_dependencies() -> Dictionary:
	return {"AnimatorComponent": "animator"}

func apply_gravity(force: Variant = null, max_speed: Variant = null) -> void:
	var _force: float = force if force is float else gravity_force
	var _max_speed: float = max_speed if max_speed is float else terminal_speed
	body.velocity += body.up_direction * -_force
	body.velocity = body.velocity.clampf(-_max_speed, _max_speed)

func update_flip() -> void:
	if body.velocity.x < 0:
		animator.animated_sprite.flip_h = true
	elif body.velocity.x > 0:
		animator.animated_sprite.flip_h = false

func decelerate() -> void:
	if body.velocity.x > -deceleration and body.velocity.x < deceleration:
		body.velocity.x = 0
	else:
		body.velocity.x = move_toward(body.velocity.x, 0, deceleration)

func immobile() -> bool:
	return body.velocity == Vector2.ZERO

func update(gravity: bool = true) -> void:
	if gravity:
		apply_gravity()
	update_flip()
	if body.is_on_floor():
		decelerate()
	body.move_and_slide()
