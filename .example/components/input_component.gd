class_name InputComponent
extends Component

func get_vector() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func check_action(action_name: StringName) -> bool:
	return Input.is_action_just_pressed(action_name)
