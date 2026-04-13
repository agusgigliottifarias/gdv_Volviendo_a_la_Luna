extends CharacterBody2D

# --- Configuración de la NAZA ---
@export_group("Motores")
@export var potencia_empuje: float = 600.0 
@export var velocidad_rotacion: float = 4.0

@export_group("Trayectoria")
@export var puntos_prediccion: int = 250
@export var precision_simulacion: float = 0.05
@onready var linea_trayectoria = $Line2D

# --- UI (Telemetría) ---
# Usamos un nombre de variable bien raro para que no choque con nada
@export var mi_etiqueta_de_velocidad: Label 
@onready var fuego = get_node("fuego")


func _physics_process(delta: float) -> void:
	# 1. Movimiento
	var input_giro = Input.get_axis("ui_left", "ui_right")
	rotation += input_giro * velocidad_rotacion * delta

	if Input.is_action_pressed("ui_select"):
		velocity += Vector2.RIGHT.rotated(rotation) * potencia_empuje * delta
		# 2. Encendemos el fuego
		fuego.visible = true 
	else:
		# 3. APAGAMOS el fuego cuando soltás el espacio
		fuego.visible = false
	# 2. Gravedad
	velocity += calcular_gravedad_en_punto(global_position) * delta
	move_and_slide()
	
	# 3. Actualizar Visuales
	actualizar_linea_trayectoria()
	actualizar_velocimetro_naza()

func actualizar_velocimetro_naza() -> void:
	# Verificamos que el cartel esté conectado
	if mi_etiqueta_de_velocidad != null:
		var v_actual = velocity.length()
		var mensaje = "VEL: %d KM/H" % int(v_actual)
		
		# --- EL TRUCO MAESTRO ---
		# Usamos .set() que es una función "bruta" para forzar el valor
		mi_etiqueta_de_velocidad.set("text", mensaje)
		
		# Cambiamos color según velocidad
		if v_actual > 900: mi_etiqueta_de_velocidad.modulate = Color.RED
		elif v_actual > 500: mi_etiqueta_de_velocidad.modulate = Color.ORANGE
		else: mi_etiqueta_de_velocidad.modulate = Color.CYAN

func calcular_gravedad_en_punto(pos: Vector2) -> Vector2:
	var fuerza_total = Vector2.ZERO
	var planetas = get_tree().get_nodes_in_group("planetas")
	for p in planetas:
		if not "fuerza_gravedad" in p: continue
		var dir = p.global_position - pos
		var dist = dir.length()
		if dist < 60: continue
		var intensidad = (p.fuerza_gravedad * 1200) / dist
		fuerza_total += dir.normalized() * intensidad
	return fuerza_total

func actualizar_linea_trayectoria() -> void:
	var puntos = []
	var pos_s = global_position
	var vel_s = velocity
	for i in range(puntos_prediccion):
		var g = calcular_gravedad_en_punto(pos_s)
		vel_s += g * precision_simulacion
		pos_s += vel_s * precision_simulacion
		puntos.append(to_local(pos_s))
	linea_trayectoria.points = puntos
