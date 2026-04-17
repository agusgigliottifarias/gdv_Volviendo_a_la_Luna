extends Node2D

# Velocidad de rotación (podes cambiarla desde el Inspector)
@export var velocidad: float = 1.0

func _process(delta):
	# Esto es lo único que hace falta para que la Luna orbite
	rotation += velocidad * delta
