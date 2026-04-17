extends StaticBody2D

# --- Configuración de la NAZA ---
@export_group("Física de Gravedad")
## La fuerza que usará la nave para su cálculo y la trayectoria.
## Tip: Tierra ~ 980, Luna ~ 300.
@export var fuerza_gravedad: float = 100.0:
	set(valor):
		fuerza_gravedad = valor
		_actualizar_fisica()

## Prioridad del área: 0 para Tierra, 1 o más para la Luna.
## Esto permite que la gravedad de la Luna "pise" a la de la Tierra.
@export var prioridad: int = 0:
	set(valor):
		prioridad = valor
		_actualizar_fisica()

@export_group("Visuales")
## Si querés que el planeta rote sobre su eje (decorativo).
@export var rotar_planeta: bool = true
var rotation_speed: float = 0.2

# --- Referencias ---
@onready var area_gravedad: Area2D = $Area2D

func _ready() -> void:
	# Seteamos una rotación aleatoria para que no todos los planetas giren igual
	rotation_speed = randf_range(0.1, 0.5)
	
	# Sincronizamos los valores al arrancar
	_actualizar_fisica()

func _process(delta: float) -> void:
	# Rotación decorativa del sprite
	if rotar_planeta and has_node("Sprite2D"):
		$Sprite2D.rotation += rotation_speed * delta

## Función interna para que el Area2D siempre tenga los mismos datos que el script
func _actualizar_fisica() -> void:
	# Usamos is_node_ready() para evitar errores si el setter se dispara antes que el _ready
	if is_node_ready() and area_gravedad:
		area_gravedad.gravity = fuerza_gravedad
		area_gravedad.priority = prioridad
		
		# Configuraciones fijas necesarias para que funcione como planeta:
		area_gravedad.gravity_point = true
		area_gravedad.gravity_space_override = Area2D.SPACE_OVERRIDE_REPLACE
		# (0,0) significa que la gravedad tira hacia el centro del nodo
		area_gravedad.gravity_direction = Vector2.ZERO
