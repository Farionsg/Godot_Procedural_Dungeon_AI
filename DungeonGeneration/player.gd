@tool
extends CharacterBody3D

var speed = 2
var accel = 10
var target : Vector3

@onready var nav: NavigationAgent3D = $NavigationAgent3D

func _physics_process(delta):
	mover_player(delta, target)

func mover_player(delta, target):
	var direction = Vector3()
	nav.target_position = target
	
	direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	
	velocity = velocity.lerp(direction * speed, accel * delta)
	move_and_slide()
	rotation.y = lerp(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10)

func set_Target(targetP):
	target = targetP

