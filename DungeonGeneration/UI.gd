extends CanvasLayer
class_name UI

@onready var spawn_label = $Control/MarginContainer/VBoxContainer/HBoxContainer/Spawn
@onready var objetivo_label = $Control/MarginContainer/VBoxContainer/HBoxContainer/Objetivo
@onready var coordenada_a = $Control/MarginContainer/VBoxContainer/HBoxContainer/Actual

var spawn = "Spawn = "
var objetivo = "Objetivo = "
var actual = "Coordenada Actual = "


var datosSpawn : String
var datosObjetivo : String
var datosActual : String
var puntoA : String
var puntoB : String
var coor	: String


func _ready():
	update_spawn_label()
	
func update_spawn_label():
	ponerDatos()
	spawn_label.text = datosSpawn
	objetivo_label.text = datosObjetivo
	coordenada_a.text = datosActual
	
func set_Text(punto_A, punto_B, coordenada):
	puntoA =  punto_A
	puntoB = punto_B
	coor = coordenada
	
func ponerDatos():
	datosSpawn = (spawn + puntoA + "         ")
	datosObjetivo = (objetivo + puntoB + "           													")
	datosActual = (actual + coor)
	
