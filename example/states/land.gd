extends SMCState

@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var input: InputComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var animator: AnimatorComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var stats: StatsComponent
@export_custom(PROPERTY_HINT_COMPONENT, "", 0) var physics: PhysicsComponent


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
