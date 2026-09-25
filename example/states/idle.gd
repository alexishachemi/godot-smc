extends SMCState

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var input: InputComponent

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var animator: AnimatorComponent

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var stats: StatsComponent

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var physics: PhysicsComponent

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
