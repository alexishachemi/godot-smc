class_name WallDetector
extends Node2D

@export_enum("UP", "DOWN", "LEFT", "RIGHT") var direction_str: String
@export var area: Area2D

var enabled: bool = false
var direction: Vector2

func _ready():
	area.body_entered.connect(func (_a): enabled = true)
	area.body_exited.connect(func (_a): enabled = false)
	direction = str_to_direction(direction_str)

static func str_to_direction(s: String) -> Vector2:
	match s.to_upper():
		"UP":
			return Vector2.UP
		"DOWN":
			return Vector2.DOWN
		"LEFT":
			return Vector2.LEFT
		"RIGHT":
			return Vector2.RIGHT
	return Vector2.ZERO
