extends Camera3D

@export var spring_arm_pos:Node3D
@export var lerp_pow:float = 5

func _process(delta: float) -> void:
	position = lerp(position, spring_arm_pos.position, lerp_pow * delta)
