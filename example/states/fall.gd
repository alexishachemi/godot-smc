extends State

var animator: AnimatorComponent
var physics: PhysicsComponent
var stats: StatsComponent
var input: InputComponent
var wall_detector: WallDetectorComponent

func get_dependencies() -> Dictionary:
	return {
		"AnimatorComponent": "animator",
		"PhysicsComponent": "physics",
		"StatsComponent": "stats",
		"InputComponent": "input",
		"WallDetectorComponent": "wall_detector"
	}

func enter(_prev_state: StringName, params: Dictionary = {}):
	if params.get("alt", false):
		animator.play("alt_fall")
	else:
		animator.play("fall")

func exit():
	animator.stop()

func update(_delta: float):
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

func physics_update(_delta: float):
	physics.update()
