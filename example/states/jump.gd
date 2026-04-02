extends SMCState

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var physics: PhysicsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var stats: StatsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var input: InputComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var wall_detector: WallDetectorComponent


func jump(alt: bool = false) -> void:
	var anim_name: StringName = "alt_jump" if alt else "jump" 
	var force: int = stats.alt_jump_force if alt else stats.jump_force
	if stats.jumps <= 0:
		return
	physics.body.velocity.y = -force
	stats.jumps -= 1
	animator.play(anim_name)

func _enter(_previous_state: StringName, args: Dictionary[StringName, Variant]) -> void:
	jump(args.get("alt", false))

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
	if input.check_action("jump"):
		jump(true)
	if physics.body.velocity.y > 5:
		transition_to("fall", {"alt": animator.animated_sprite.animation == "alt_jump"})
	if direction != 0 and wall_detector.touches(Vector2(-direction, 0)):
		transition_to("wall_land")

func _physics_process(_delta: float) -> void:
	physics.update()
