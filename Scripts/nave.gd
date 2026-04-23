extends CharacterBody2D

# --- Configuración de la NAZA ---
@export_group("Motores")
@export var potencia_empuje: float = 600.0 
@export var velocidad_rotacion: float = 4.0

@export_group("Trayectoria")
@export var puntos_prediccion: int = 250
@export var precision_simulacion: float = 0.05
@export var intervalo_actualizacion: float = 0.1 

@export_group("Cámara y Mapa")
@export var zoom_normal: Vector2 = Vector2(1, 1)
@export var zoom_mapa: Vector2 = Vector2(0.15, 0.15) 
@export var zoom_total: Vector2 = Vector2(0.02, 0.02)
@export var suavizado_zoom: float = 0.1

@export_group("Combustible")
## Cantidad máxima (ej: 100)
@export var combustible_max: float = 100.0
## Cantidad que resta por cada segundo de aceleración (ej: 0.1)
@export var consumo_por_segundo: float = 0.1

# --- UI y Nodos ---
@export var mi_etiqueta_de_velocidad: Label 
@export var barra_combustible: ProgressBar 
@onready var linea_trayectoria = $Line2D
@onready var fuego = $fuego
@onready var camara = $Camera2D

# --- Variables de Estado Interno ---
var tiempo_desde_ultimo_calculo: float = 0.0
var combustible_actual: float = 100.0

func _ready() -> void:
	combustible_actual = combustible_max
	if barra_combustible:
		barra_combustible.max_value = combustible_max
		barra_combustible.value = combustible_actual

func _physics_process(delta: float) -> void:
	# 1. Movimiento y Rotación
	var input_giro = Input.get_axis("ui_left", "ui_right")
	rotation += input_giro * velocidad_rotacion * delta

	# --- LÓGICA DE COMBUSTIBLE CORREGIDA ---
	var quiere_acelerar = Input.is_action_pressed("ui_select")
	var tiene_combustible = combustible_actual > 0
	var acelerando_ahora = false

	if quiere_acelerar and tiene_combustible:
		# Aplicamos empuje
		velocity += Vector2.RIGHT.rotated(rotation) * potencia_empuje * delta
		
		# RESTA DE COMBUSTIBLE: valor * delta asegura que sea "por segundo"
		combustible_actual -= consumo_por_segundo * delta
		
		fuego.visible = true 
		acelerando_ahora = true
	else:
		fuego.visible = false
	
	# 2. Gravedad y Física
	velocity += calcular_gravedad_en_punto(global_position) * delta
	move_and_slide()
	
	# 3. Zoom, Trayectoria y Telemetría
	gestionar_zoom_camara()
	
	tiempo_desde_ultimo_calculo += delta
	if tiempo_desde_ultimo_calculo >= intervalo_actualizacion or input_giro != 0 or acelerando_ahora:
		actualizar_linea_trayectoria()
		tiempo_desde_ultimo_calculo = 0.0
	
	actualizar_telemetria()

func gestionar_zoom_camara() -> void:
	var objetivo = zoom_normal
	if Input.is_key_pressed(KEY_0):
		objetivo = zoom_total
	elif Input.is_key_pressed(KEY_M):
		objetivo = zoom_mapa
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

func actualizar_telemetria() -> void:
	if mi_etiqueta_de_velocidad:
		mi_etiqueta_de_velocidad.text = "VEL: %d KM/H" % int(velocity.length())
	
	# Actualizamos la barra en cada frame para que se vea fluida
	if barra_combustible:
		barra_combustible.value = combustible_actual

func actualizar_linea_trayectoria() -> void:
	var puntos = []
	var pos_s = global_position
	var vel_s = velocity
	var planetas = get_tree().get_nodes_in_group("planetas")
	
	for i in range(puntos_prediccion):
		var g = calcular_gravedad_en_punto(pos_s)
		vel_s += g * precision_simulacion
		pos_s += vel_s * precision_simulacion
		puntos.append(to_local(pos_s))
		
		var impacto = false
		for p in planetas:
			if pos_s.distance_to(p.global_position) < 65:
				impacto = true
				break
		if impacto: break 
		
	linea_trayectoria.points = puntos
