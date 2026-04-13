extends StaticBody2D

# Esta variable aparecerá en el Inspector a la derecha.
# Podés ponerle 50 a un planeta chico y 500 a uno gigante.
@export var fuerza_gravedad: float = 100.0

func _ready():
	rotation_speed = randf_range(0.1, 0.5)

# Si querés que el planeta rote (decorativo)
var rotation_speed = 0.2
func _process(delta):
	$Sprite2D.rotation += rotation_speed * delta
