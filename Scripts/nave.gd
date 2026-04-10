extends RigidBody2D

# --- VARIABLES (Asegurate que aparezcan en el Inspector) ---
@export var velocidad_rotacion: float = 5.0
@export var velocidad_maxima: float = 5500.0
@export var aceleracion: float = 600.0
@export var friccion: float = 100.0

func _ready():
	# IMPORTANTE: Dejamos la gravedad en 1 para que el Area2D afecte a la nave
	# Pero en el proyecto (Project Settings) la gravedad global debería ser 0
	# o simplemente no afectará si no hay otras áreas.
	gravity_scale = 1.0
	# Bloqueamos la rotación física para que no gire como loca al chocar
	lock_rotation = true 

func _physics_process(delta: float):
	var direccion_rotacion = 0
	var direccion_aceleracion = Vector2.ZERO
	
	# 1. INPUTS (Fijate que los nombres coincidan con tu Mapa de Entrada)
	if Input.is_action_pressed("ui_left"):
		direccion_rotacion = -1
	if Input.is_action_pressed("ui_right"):
		direccion_rotacion = 1
		
	# Cambié "espacio" por "ui_select" que es el default de Godot para Espacio
	if Input.is_action_pressed("ui_select") or Input.is_action_pressed("ui_up"):
		# Usamos -transform.y porque en Godot "arriba" es el eje Y negativo
		direccion_aceleracion = -transform.y
	
	# 2. ROTACIÓN MANUAL
	rotation += direccion_rotacion * velocidad_rotacion * delta
	
	# 3. MOVIMIENTO (Operamos directamente sobre la propiedad de RigidBody2D)
	if direccion_aceleracion != Vector2.ZERO:
		linear_velocity += direccion_aceleracion * aceleracion * delta
	
	# 4. LÍMITE DE VELOCIDAD
	if linear_velocity.length() > velocidad_maxima:
		linear_velocity = linear_velocity.normalized() * velocidad_maxima
	
	# 5. FRICCIÓN (Solo si no estamos acelerando)
	if direccion_aceleracion == Vector2.ZERO and linear_velocity.length() > 5:
		var vector_friccion = linear_velocity.normalized() * friccion * delta
		linear_velocity -= vector_friccion
	elif direccion_aceleracion == Vector2.ZERO and linear_velocity.length() <= 5:
		linear_velocity = Vector2.ZERO
