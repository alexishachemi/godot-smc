extends SMCState

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var physics: PhysicsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var stats: StatsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var input: InputComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var wall_detector: WallDetectorComponent


func _enter(previous_state: StringName, args: Dictionary = {}) -> void:
	if previous_state != "jump" and stats.jumps > 0:
		stats.jumps -= 1
	if args.get("alt", false):
		animator.play("alt_fall")
	else:
		animator.play("fall")


func _exit(_next_state: StringName, _next_state_args: Dictionary[StringName, Variant]) -> void:
	animator.stop()


func _process(_delta: float) -> void:
	var direction: float = input.get_vector().x
	if direction < 0:
		direction = floor(direction)
	else:
		direction = ceil(direction)
	physics.body.velocity.x += stats.air_acceleration * direction
	physics.body.velocity.x = clamp(physics.body.velocity.x,
		-stats.air_max_speed, stats.air_max_speed)
	if input.check_action("jump") and stats.jumps > 0:
		transition_to("jump", {"alt": true})
	if physics.body.is_on_floor():
		transition_to("land")
	if direction != 0 and wall_detector.touches(Vector2(-direction, 0)):
		transition_to("wall_slide")


func _physics_process(_delta: float) -> void:
	physics.update()
