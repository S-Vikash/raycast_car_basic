extends RigidBody3D

@export_group("Suspension")
@export var wheels: Array[RayCast3D]
@export var spring_strength: float = 150
@export var spring_damping: float = 5
@export var rest_dis: float = 0.5
@export var wheel_radius: float = 0.5
@export var wheel_pos_crxn_fac: float = 0.1

@export_group("Acceleration_Braking")
@export var engine_power: float = 10
@export var rev_power: float = 8
@export var rolling_resistance: float = 0.125
@export var throttle_resp:float = 0.6
@export var dir_change_res:float = 0.3

@export_group("Steer")
@export var low_speed_steer_ang: float = 45
@export var high_speed_steer_ang: float = 30
@export var steer_speed: float = 5
@export var max_speed: float = 200  # <-- separate from engine_power
@export var front_grip: float = 0.6
@export var back_grip: float = 0.5

var curr_throttle:float

func _physics_process(delta: float) -> void:
	for wheel in wheels:
		do_single_wheel_suspension(wheel)
		handle_steer(wheel, delta)
		if wheel.is_colliding():  # guard all contact-dependent functions
			handle_throttle(wheel, delta)
			apply_z_force(wheel)
			apply_x_force(wheel)
			
func _get_point_velocity(point: Vector3) -> Vector3:
	return linear_velocity + angular_velocity.cross(point - global_position)
	
func do_single_wheel_suspension(wheel: RayCast3D) -> void:
	if not wheel.is_colliding():
		return
	var contact: Vector3 = wheel.get_collision_point()
	var spring_up_dir: Vector3 = wheel.global_transform.basis.y
	var spring_len: float = wheel.global_position.distance_to(contact) - wheel_radius
	var offset: float = rest_dis - spring_len
	
	wheel.get_node("wheel").position.y = -spring_len + wheel_pos_crxn_fac
	
	var wheel_world_vel: Vector3 = _get_point_velocity(wheel.global_position)
	var vel: float = spring_up_dir.dot(wheel_world_vel)
	var force_mag: float = (offset * spring_strength) - (vel * spring_damping)
	var force_vector: Vector3 = spring_up_dir * force_mag
	
	apply_force(force_vector, wheel.global_position - global_position)
	#DebugDraw3D.draw_arrow(contact, (contact + force_vector), Color.BLUE)
	#DebugDraw3D.draw_line_hit_offset(wheel.global_position, wheel.target_position, spring_len, 10)

func handle_throttle(wheel: RayCast3D, delta:float) -> void:
	if not wheel.is_in_group("rear"):
		return
	var fwd_dir: Vector3 = -global_basis.z
	
	var throttle: float = Input.get_action_strength("accelerate")
	var brake: float = Input.get_action_strength("brake")
	
	var target_throttle:float = throttle - brake
	var same_dir:bool = sign(target_throttle) == sign(curr_throttle) or throttle == 0
	var lerp_speed:float = throttle_resp if same_dir else dir_change_res
	
	curr_throttle = move_toward(curr_throttle, target_throttle, lerp_speed * delta)
	var power:float = engine_power if curr_throttle>=0 else rev_power
	
	var force:Vector3 = curr_throttle * fwd_dir * power
	
	var contact: Vector3 = wheel.get_collision_point()
	
	if(linear_velocity.length() < max_speed):
		apply_force(force , contact - global_position)
		
func handle_steer(wheel: RayCast3D, _delta: float) -> void:
	if wheel.is_in_group("rear"):
		return
	var fwd: Vector3 = -wheel.global_basis.z
	var steer_input: float = Input.get_axis("steer_right", "steer_left")
	var forward_speed: float = linear_velocity.dot(fwd)
	# Use max_speed instead of engine_power for normalization
	
	var speed_factor: float = clamp(abs(forward_speed) / max_speed, 0.0, 1.0)
	var max_steer: float = lerp(
		deg_to_rad(low_speed_steer_ang),
		deg_to_rad(high_speed_steer_ang),
		speed_factor)			#Did not use delta bcz not changes over time

	wheel.rotation.y = lerp_angle(
		wheel.rotation.y,
		steer_input * max_steer,
		steer_speed * _delta)			#Used delta because rot.y changes over time


func apply_z_force(wheel: RayCast3D) -> void:
	var dir: Vector3 = wheel.global_basis.z
	var contact: Vector3 = wheel.get_collision_point()
	var tire_world_vel: Vector3 = _get_point_velocity(wheel.global_position)
	var z_force: float = dir.dot(tire_world_vel) * mass * rolling_resistance
	
	apply_force(-dir * z_force, contact - global_position)			#-dir * z_force → -( +Z ) * ( negative ) → positive Z direction...
	
func apply_x_force(wheel: RayCast3D) -> void:
	var contact: Vector3 = wheel.get_collision_point()
	var dir: Vector3 = wheel.global_basis.x
	var tire_world_vel: Vector3 = _get_point_velocity(wheel.global_position)
	var lateral_speed: float = dir.dot(tire_world_vel)
	
	var grip: float = back_grip if wheel.is_in_group("rear") else front_grip
	# Physically correct: impulse = mass * velocity_change
	var x_force: float = -lateral_speed * grip * mass
	
	apply_force(dir * x_force, contact - global_position)
