extends Node3D
## Controlador del menú 3D (Godot 4.x). Estructura esperada:
##
##   Menu (Node3D)                <- este script
##   ├ Camera3D                   -> asígnala en "camera"
##   └ Zones (Node3D)             -> asígnalo en "zones"
##      ├ Main (Node3D)
##      │  ├ CamPoint (Marker3D)  <- desde aquí mira la cámara a esta zona
##      │  └ botones (instancias de button_3d.gd)
##      └ Options (Node3D)
##         ├ CamPoint (Marker3D)
##         └ botones...
##
## Un botón con action = "goto:Options" mueve la cámara al CamPoint de la zona "Options".

signal action_pressed(action: String)

@export var camera: Camera3D
@export var zones: Node3D
@export var start_zone := "Main"
@export var travel_time := 1.1

var _current := ""
var _moving := false
var _base_fov := 60.0


func _ready() -> void:
	# Los botones se registran solos en el grupo "menu_buttons"
	for button in get_tree().get_nodes_in_group("menu_buttons"):
		button.pressed.connect(_on_button_pressed)

	_base_fov = camera.fov
	_current = start_zone
	camera.global_transform = _cam_point(start_zone).global_transform


func _cam_point(zone_name: String) -> Marker3D:
	return zones.get_node(zone_name + "/CamPoint")


func go_to(zone_name: String) -> void:
	if _moving or zone_name == _current or not zones.has_node(zone_name):
		return
	_moving = true
	var start := camera.global_transform
	var target := _cam_point(zone_name).global_transform
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_travel.bind(start, target), 0.0, 1.0, travel_time)
	tw.finished.connect(_on_travel_finished.bind(zone_name))


func _travel(w: float, start: Transform3D, target: Transform3D) -> void:
	camera.global_transform = start.interpolate_with(target, w)
	camera.fov = _base_fov + sin(w * PI) * 10.0  # efecto "swoosh" a mitad de viaje


func _on_travel_finished(zone_name: String) -> void:
	_current = zone_name
	_moving = false


func _on_button_pressed(action: String) -> void:
	if _moving:
		return
	if action.begins_with("goto:"):
		go_to(action.substr(5))
		return

	action_pressed.emit(action)
	match action:
		"play":
			print("Jugar -> get_tree().change_scene_to_file(\"res://tu_escena.tscn\")")
		"quit":
			get_tree().quit()
		_:
			print("Acción: ", action)
