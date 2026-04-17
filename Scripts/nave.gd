extends CharacterBody2D

# --- Configuración de la NAZA ---
@export_group("Motores")
@export var potencia_empuje: float = 600.0 
@export var velocidad_rotacion: float = 4.0

@export_group("Trayectoria")
@export var puntos_prediccion: int = 250
@export var precision_simulacion: float = 0.05

@export_group("Cámara y Mapa")
@export var zoom_normal: Vector2 = Vector2(1, 1)
@export var zoom_mapa: Vector2 = Vector2(0.15, 0.15) 
@export var zoom_total: Vector2 = Vector2(0.04, 0.04) # Vista completa para testeo
@export var suavizado_zoom: float = 0.1

# --- UI y Nodos ---
@export var mi_etiqueta_de_velocidad: Label 
@onready var linea_trayectoria = $Line2D
@onready var fuego = $fuego
@onready var camara = $Camera2D

func _physics_process(delta: float) -> void:
	# 1. Movimiento y Rotación
	var input_giro = Input.get_axis("ui_left", "ui_right")
	rotation += input_giro * velocidad_rotacion * delta

	if Input.is_action_pressed("ui_select"):
		velocity += Vector2.RIGHT.rotated(rotation) * potencia_empuje * delta
		fuego.visible = true 
	else:
		fuego.visible = false
	
	# 2. Gravedad
	velocity += calcular_gravedad_en_punto(global_position) * delta
	move_and_slide()
	
	# 3. Lógica de Zoom (Testeo y Mapa)
	gestionar_zoom_camara()
	
	# 4. Actualizar Visuales y Telemetría
	actualizar_linea_trayectoria()
	actualizar_velocimetro_naza()

func gestionar_zoom_camara() -> void:
	var objetivo = zoom_normal
	
	# Prioridad de Zoom
	if Input.is_key_pressed(KEY_0):
		objetivo = zoom_total # Vista ultra alejada para testing
	elif Input.is_key_pressed(KEY_M):
		objetivo = zoom_mapa  # Vista táctica
	
	# Interpolación suave
	camara.zoom = camara.zoom.lerp(objetivo, suavizado_zoom)

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

func actualizar_velocimetro_naza() -> void:
	if mi_etiqueta_de_velocidad != null:
		var v_actual = velocity.length()
		var mensaje = "VEL: %d KM/H" % int(v_actual)
		mi_etiqueta_de_velocidad.set("text", mensaje)
		
		if v_actual > 900: mi_etiqueta_de_velocidad.modulate = Color.RED
		elif v_actual > 500: mi_etiqueta_de_velocidad.modulate = Color.ORANGE
		else: mi_etiqueta_de_velocidad.modulate = Color.CYAN

func actualizar_linea_trayectoria() -> void:
	var puntos = []
	var pos_s = global_position
	var vel_s = velocity
	
	for i in range(puntos_prediccion):
		var g = calcular_gravedad_en_punto(pos_s)
		vel_s += g * precision_simulacion
		pos_s += vel_s * precision_simulacion
		puntos.append(to_local(pos_s))
		
	# Debería quedar así (depende de qué haya en esa línea):
# O si es el final de la función:
	linea_trayectoria.points = puntos
