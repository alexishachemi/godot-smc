extends SMCState

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var animator: AnimatorComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var physics: PhysicsComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var stats: StatsComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var input: InputComponent


func _enter(_previous_state: StringName, _args: Dictionary[StringName, Variant]) -> void:
	stats.reset_stat("jumps")
	animator.play("land")

func _exit(_next_state: StringName, _next_state_args: Dictionary[StringName, Variant]) -> void:
	animator.stop()

func _process(_delta: float) -> void:
	if input.get_vector().x != 0:
		transition_to("run")
	if physics.body.velocity.y > 5:
		transition_to("fall")
	if animator.animated_sprite.animation == "land" \
		and animator.animated_sprite.is_playing():
		return
	transition_to("idle")

func _physics_process(_delta: float) -> void:
	physics.update()
