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

func jump(alt: bool = false):
	var anim_name: StringName = "alt_jump" if alt else "jump" 
	var force: int = stats.alt_jump_force if alt else stats.jump_force
	if stats.jumps <= 0:
		return
	physics.body.velocity.y = -force
	stats.jumps -= 1
	animator.play(anim_name)

func enter(_prev_state: StringName, params: Dictionary = {}):
	jump(params.get("alt", false))

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
	if input.check_action("jump"):
		jump(true)
	if physics.body.velocity.y > 5:
		transition_to("fall", {"alt": animator.animated_sprite.animation == "alt_jump"})
	if direction != 0 and wall_detector.touches(Vector2(-direction, 0)):
		transition_to("wall_land")

func physics_update(_delta: float):
	physics.update()
