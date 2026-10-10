extends Area3D
## Botón 3D para menús (Godot 4.x). Estructura esperada en el editor:
##
##   Area3D            <- este script
##   ├ CollisionShape3D
##   └ Visual (Node3D) <- aquí cuelgan el MeshInstance3D y el Label3D; es lo que se anima
##
## Se anima "Visual" y no el Area3D para que la colisión no se mueva (así el
## hover no parpadea al elevarse el botón).

signal pressed(action: String)

## "goto:NombreZona" mueve la cámara a esa zona. Cualquier otro texto ("play", "quit"...)
## se envía tal cual al controlador del menú.
@export var action := ""
@export var hover_lift := 0.3
@export var hover_scale := 1.07

@onready var _visual: Node3D = $Visual

var _tween: Tween
var _hovering := false
var _armed := false  # se pulsó sobre este botón y todavía no se ha soltado


func _ready() -> void:
	add_to_group("menu_buttons")
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)


func _on_mouse_entered() -> void:
	_set_hover(true)


func _on_mouse_exited() -> void:
	_armed = false
	_set_hover(false)


func _on_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_armed = true
		_set_hover(true)  # en móvil no existe "pasar por encima": se eleva al tocar
	elif _armed:
		_armed = false
		if mb.device == InputEvent.DEVICE_ID_EMULATION:
			_hovering = false  # evento táctil: al levantar el dedo ya no hay hover
		_press_animation()
		pressed.emit(action)


# ------------------------------------------------------------------ animaciones

## Hover: el botón se adelanta y crece un poco.
func _set_hover(value: bool) -> void:
	_hovering = value
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_visual, "position:z", hover_lift if value else 0.0, 0.15)
	_tween.tween_property(_visual, "scale", Vector3.ONE * (hover_scale if value else 1.0), 0.15)


## Pulsación: se hunde un instante y rebota hasta su estado de reposo/hover.
func _press_animation() -> void:
	var lift := hover_lift if _hovering else 0.0
	var scl := hover_scale if _hovering else 1.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_visual, "scale", Vector3(0.92, 0.92, 1.0), 0.07)
	_tween.tween_property(_visual, "scale", Vector3.ONE * scl, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(_visual, "position:z", lift, 0.2)
