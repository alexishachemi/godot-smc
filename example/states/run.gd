extends SMCState

@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var animator: AnimatorComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var physics: PhysicsComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var stats: StatsComponent
@export_custom(SMCComponent.PROPERTY_HINT_COMPONENT, "", SMCComponent.PROPERTY_USAGE_COMPONENT)
var input: InputComponent


func _exit(_next_state: StringName, _next_state_args: Dictionary[StringName, Variant]) -> void:
	animator.stop()


func _process(_delta: float) -> void:
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

func _physics_process(_delta: float) -> void:
	physics.update()
