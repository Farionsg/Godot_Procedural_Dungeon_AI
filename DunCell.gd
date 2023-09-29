@tool
extends Node3D
@export var speed : int = 50
func remove_wall_up():
	$WallUP.free()
func remove_wall_down():
	$WallDown.free()
func remove_wall_left():
	$WalllLeft.free()
func remove_wall_right():
	$WallRight.free()
func remove_door_up():
	$DoorUp.free()
func remove_door_down():
	$DoorDown.free()
func remove_door_left():
	$DoorLeft.free()
func remove_door_right():
	$DoorRight.free()
func disable_floor_slow():
	$TileRaised.free()
func disable_floor():
	$TileFlat.free()
