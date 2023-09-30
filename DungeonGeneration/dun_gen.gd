@tool
extends Node3D

@onready var grid_map : GridMap = $GridMap
@onready var player : CharacterBody3D = $Player

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	$Player.position = Vector3i(0,0,0)
	$Target.position = Vector3i(0,0,0)
	$Player.rotation = Vector3i(0,0,0)
	if Engine.is_editor_hint():
		generate()
		playerAI()


@export_range(0,1) var survival_chance : float = 0.25

@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()


@export var punto_A : Vector3
@export var punto_B : Vector3
@export var room_type : bool = 0
@export var room_number : int = 20
@export var room_margin : int = 2
@export var room_recursion : int = 15
@export var min_room_size : int = 7
@export var max_room_size : int = 14
@export_multiline var custom_seed : String = "" : set = set_seed
var inicio_juego : bool = false
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())

var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []

func _init():
	inicio_juego = false

func _process(delta):
	if !inicio_juego:
		$Player.position = Vector3i(0,0,0)
		$Target.position = Vector3i(0,0,0)
		$Player.rotation = Vector3i(0,0,0)
		generate()
		playerAI()
		inicio_juego = true
		if Input.is_action_just_pressed("Pause"):
			get_tree().paused = true
			print("Juego pausado")

	
func visualize_border():
	grid_map.clear()
	for i in range(-1, border_size + 1): #Crea el borde del cuarto
		grid_map.set_cell_item(Vector3i(i,0,-1),3)
		grid_map.set_cell_item(Vector3i(i,0,border_size),3)
		grid_map.set_cell_item(Vector3i(border_size,0,i),3)
		grid_map.set_cell_item(Vector3i(-1,0,i),3)
	
func generate():
	room_tiles.clear()
	room_positions.clear()
	
	if custom_seed : set_seed(custom_seed)
	visualize_border()
	for i in room_number:
		make_room(room_recursion)
	
	
	punto_A = room_positions[0]
	punto_B = room_positions[room_positions.size() - 1]
	
	
	
	print("Las coordenadas del spawn son : ", punto_A)
	print("Las coordenadas del objetivo son : ", punto_B)
	
	var rpv2 : PackedVector2Array = []
	var del_graph : AStar2D = AStar2D.new()
	var mst_graph : AStar2D = AStar2D.new()
	
	for p in room_positions:
		rpv2.append(Vector2(p.x,p.z))
		del_graph.add_point(del_graph.get_available_point_id(), Vector2(p.x,p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(), Vector2(p.x,p.z))
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2))
	
	for i in delaunay.size()/3:
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1,p2)
		del_graph.connect_points(p2,p3)
		del_graph.connect_points(p1,p3)
	
	var visited_point : PackedInt32Array = []
	visited_point.append(randi() % room_positions.size())
	while visited_point.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_point:
			for c in del_graph.get_point_connections(vp):
				if !visited_point.has(c):
					var con : PackedInt32Array = [vp,c]
					possible_connections.append(con)
					
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) < rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
			
		visited_point.append(connection[1])
		mst_graph.connect_points(connection[0], connection[1])
		del_graph.disconnect_points(connection[0], connection[1])
			
	var hallway_graph : AStar2D = mst_graph
	
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c > p:
				var kill : float = randf()
				if survival_chance > kill :
					hallway_graph.connect_points(p,c)
					
	create_hallways(hallway_graph)
	$NavigationRegion3D.get_node("DunMesh").create_dungeon()
	$NavigationRegion3D.bake_navigation_mesh()

func create_hallways(hallway_graph : AStar2D):
	var hallways : Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c > p:
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				for t in room_from:
					if t.distance_squared_to(room_positions[c]) < tile_from.distance_squared_to(room_positions[c]):
						tile_from = t
				for t in room_to:
					if t.distance_squared_to(room_positions[p]) < tile_to.distance_squared_to(room_positions[p]):
						tile_to = t
				var hallway : PackedVector3Array = [tile_from, tile_to]
				hallways.append(hallway)
				grid_map.set_cell_item(tile_from,2)
				grid_map.set_cell_item(tile_to,2)
	
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x, t.z))
		
	for h in hallways:
		var pos_from : Vector2i = Vector2i(h[0].x, h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x, h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from, pos_to)
		
		for t in hall:
			var pos : Vector3i = Vector3i(t.x, 0, t.y)
			if grid_map.get_cell_item(pos) < 0:
				grid_map.set_cell_item(pos, 1)
	
	
func make_room(rec: int):
	if !rec>0:
		return
	
	var width : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	
	var start_pos : Vector3i
	start_pos.x = randi() % (border_size - width + 1)
	start_pos.z = randi() % (border_size - height + 1)
	

	

	
	for r in range(-room_margin, height + room_margin):
		for c in range(-room_margin, width + room_margin):
			var pos : Vector3i = start_pos + Vector3i(c, 0, r)
			if grid_map.get_cell_item(pos) == 0:
				make_room(rec-1)
				return
	
	var room : PackedVector3Array = []
	for r in height:
		for c in width:
			var pos : Vector3i = start_pos + Vector3i(c, 0, r)
			grid_map.set_cell_item(pos, 0)
			room.append(pos)
	room_tiles.append(room)
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)

func playerAI():
	var velocity = Vector3.FORWARD
	$Player.translate(Vector3i(punto_A.x, 3, punto_A.z) * 2)
	$Target.translate(Vector3i(punto_B.x, 5, punto_B.z) * 2)
	
	$Player.set_Target($Target.global_position)
	$Player.rotation.y = lerp($Player.rotation.y, atan2(-velocity.x, -velocity.z),10)

