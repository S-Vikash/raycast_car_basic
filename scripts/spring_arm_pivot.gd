extends Node3D

@export var mouse_sensitivity:float = 0.005

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if(event is InputEventMouseMotion ):#and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clampf(rotation.x,-PI/6,PI/6)
		
	if(Input.is_action_just_pressed("Pause")):
		if(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
