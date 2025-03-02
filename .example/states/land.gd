extends State

var input: InputComponent
var animator: AnimatorComponent
var stats: StatsComponent
var physics: PhysicsComponent

func get_dependencies() -> Dictionary:
	return {
		"InputComponent": "input",
		"AnimatorComponent": "animator",
		"StatsComponent": "stats",
		"PhysicsComponent": "physics",
	}

func enter(_prev_state: StringName, _params: Dictionary = {}):
	stats.reset_stat("jumps")
	animator.play("land")

func exit():
	animator.stop()

func update(_delta: float):
	if input.get_vector().x != 0:
		transition_to("run")
	if physics.body.velocity.y > 5:
		transition_to("fall")
	if animator.animated_sprite.animation == "land" \
		and animator.animated_sprite.is_playing():
		return
	transition_to("idle")

func physics_update(_delta: float):
	physics.update()
