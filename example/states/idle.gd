extends SMCState

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var input: InputComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var stats: StatsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var physics: PhysicsComponent

func _enter(_previous_state: StringName, _args: Dictionary[StringName, Variant]) -> void:
	stats.reset_stat("jumps")
	animator.play("idle")


func _exit(_next_state: StringName, _next_state_args: Dictionary[StringName, Variant]) -> void:
	animator.stop()


func _process(_delta: float) -> void:
	if input.get_vector().x != 0:
		transition_to("run")
	if input.check_action("jump"):
		transition_to("jump")
	if physics.body.velocity.y > 5:
		transition_to("fall")


func _physics_process(_delta: float) -> void:
	physics.update()
