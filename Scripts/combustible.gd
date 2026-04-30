extends Area2D

@export var cantidad_nafta: float = 30.0 
var velocidad_rotacion: float = randf_range(0.2, 0.8) 

func _ready():
	
	body_entered.connect(_on_body_entered)

func _process(delta):
	
	rotation += velocidad_rotacion * delta

func _on_body_entered(body):
	
	if body.has_method("sumar_nafta"):
		body.sumar_nafta(cantidad_nafta)
		
		
		print("¡Nafta pungueada con éxito! Artemis llora.")
		queue_free() # El tanque desaparece (ya lo vaciaste)
