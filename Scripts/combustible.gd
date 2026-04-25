extends Area2D

@export var cantidad_nafta: float = 30.0 # Cuánta nafta te da
var velocidad_rotacion: float = randf_range(0.2, 0.8) # Cada tanque gira distinto

func _ready():
	# Conectamos la señal de que algo entró en nuestro círculo
	body_entered.connect(_on_body_entered)

func _process(delta):
	# El tanque flota a la deriva girando
	rotation += velocidad_rotacion * delta

func _on_body_entered(body):
	# Verificamos si lo que nos chocó es la Nave de la NAZA
	if body.has_method("sumar_nafta"):
		body.sumar_nafta(cantidad_nafta)
		
		# Efecto visual: Podés poner un sonido acá antes de borrarlo
		print("¡Nafta pungueada con éxito! Artemis llora.")
		queue_free() # El tanque desaparece (ya lo vaciaste)
