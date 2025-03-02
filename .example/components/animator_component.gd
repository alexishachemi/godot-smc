class_name AnimatorComponent
extends Component

@export var animated_sprite: AnimatedSprite2D
@export var animation_player: AnimationPlayer

func play(anim_name: StringName):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		animated_sprite.play(anim_name)

func stop(keep_state: bool = false):
	if animation_player:
		animation_player.stop(keep_state)
	animated_sprite.stop()
