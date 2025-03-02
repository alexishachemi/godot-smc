extends State

var animator: AnimatorComponent
var physics: PhysicsComponent
var stats: StatsComponent
var input: InputComponent

func get_dependencies() -> Dictionary:
	return {
		"AnimatorComponent": "animator",
		"PhysicsComponent": "physics",
		"StatsComponent": "stats",
		"InputComponent": "input",
	}

func enter(_prev_state: StringName, _params: Dictionary = {}):
	pass

func exit():
	animator.stop()

func update(_delta: float):
	var direction: float = input.get_vector().x
	if direction < 0:
		direction = floor(direction)
	else:
		direction = ceil(direction)
	physics.body.velocity.x += stats.acceleration * direction
	physics.body.velocity.x = clamp(physics.body.velocity.x,
		-stats.max_speed, stats.max_speed)
	if abs(physics.body.velocity.x) > stats.acceleration * 5 \
		and animator.animated_sprite.animation != "run":
			animator.play("run")
	if physics.immobile():
		transition_to("idle")
	if input.check_action("jump"):
		transition_to("jump")
	if physics.body.velocity.y > 5:
		transition_to("fall")

func physics_update(_delta: float):
	physics.update()
