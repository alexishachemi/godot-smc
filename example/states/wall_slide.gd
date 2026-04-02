extends SMCState

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var physics: PhysicsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var stats: StatsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var input: InputComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var wall_detector: WallDetectorComponent

var touches_right: bool = false

func _enter(_previous_state: StringName, _args: Dictionary[StringName, Variant]) -> void:
	touches_right = wall_detector.touches(Vector2.RIGHT)
	animator.animated_sprite.flip_h = touches_right
	animator.play("wall_slide")
	stats.reset_stat("jumps")


func _exit(_next_state: StringName, _next_state_args: Dictionary[StringName, Variant]) -> void:
	animator.stop()


func _process(_delta: float) -> void:
	var direction: int = 1 if touches_right else -1
	var input_direction: int = ceil(input.get_vector().x)

	if physics.body.is_on_floor():
		animator.animated_sprite.flip_h = not touches_right
		transition_to("land")
	elif input.check_action("jump"):
		animator.animated_sprite.flip_h = not touches_right
		physics.body.velocity.x = stats.wall_jump_H_force * direction
		transition_to("jump")
	elif input_direction != 0 and input_direction == direction:
		animator.animated_sprite.flip_h = not touches_right
		physics.body.velocity.x = stats.wall_jump_H_force * direction
		transition_to("fall")
	elif not wall_detector.touches():
		transition_to("fall")


func _physics_process(_delta: float) -> void:
	physics.apply_gravity(physics.gravity_force / 3, physics.terminal_speed / 4)
	physics.update(false)
