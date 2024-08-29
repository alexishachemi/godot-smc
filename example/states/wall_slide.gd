extends State

var animator: AnimatorComponent
var physics: PhysicsComponent
var stats: StatsComponent
var input: InputComponent
var wall_detector: WallDetectorComponent

var touches_right: bool = false

func get_dependencies() -> Dictionary:
	return {
		"AnimatorComponent": "animator",
		"PhysicsComponent": "physics",
		"StatsComponent": "stats",
		"InputComponent": "input",
		"WallDetectorComponent": "wall_detector"
	}

func enter(_prev_state: StringName, _params: Dictionary = {}):
	touches_right = wall_detector.touches(Vector2.RIGHT)
	animator.animated_sprite.flip_h = touches_right
	animator.play("wall_slide")
	stats.reset_stat("jumps")

func exit():
	animator.stop()

func update(_delta: float):
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

func physics_update(_delta: float):
	physics.apply_gravity(physics.gravity_force / 3, physics.terminal_speed / 4)
	physics.update(false)
