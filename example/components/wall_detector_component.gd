class_name WallDetectorComponent
extends SMCComponent

@export var detectors: Array[WallDetector]

var detection_map: Dictionary

func touches(dir: Variant = null) -> bool:
	for d in detectors:
		if d.direction == dir:
			return d.enabled
		elif dir == null and d.enabled:
			return true
	return false
