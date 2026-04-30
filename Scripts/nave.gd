extends CharacterBody2D

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
@export var combustible_max: float = 100.0
@export var consumo_por_segundo: float = 10.0 

@export_group("Diálogos y Radio")
@export var recurso_dialogo: DialogueResource 
@export var titulo_intro: String = "start"
@export var titulo_radio: String = "radio_start"

@export var mi_etiqueta_de_velocidad: Label 
@export var barra_combustible: ProgressBar 

@onready var linea_trayectoria = $Line2D
@onready var fuego = $fuego
@onready var camara = $Camera2D
@onready var punto_escape = get_node_or_null("PuntoEscape") # Seguro contra crasheos
@onready var reproductor = $ReproductorMusica 

# --- NODOS DEL MAPA ---
@onready var gps_linea = $Line2D_GPS
@onready var label_mapa = $CanvasLayer/LabelMapa

var tiempo_desde_ultimo_calculo: float = 0.0
var combustible_actual: float = 100.0
var lista_canciones : Array = []
var indice_actual : int = 0
var es_primera_vez_radio: bool = true

# --- VARIABLES DE ESTADO DE VISTA ---
var modo_mapa: bool = false # Controla si el mapa táctico está abierto (Tecla M)
var modo_zoom_total: bool = false # Controla si el súper zoom está abierto (Tecla 0)

func _ready() -> void:
	combustible_actual = combustible_max
	if barra_combustible:
		barra_combustible.max_value = combustible_max
		barra_combustible.value = combustible_actual
	
	# Ocultamos el mapa y vaciamos el GPS al arrancar
	if label_mapa: label_mapa.visible = false
	if gps_linea: gps_linea.clear_points()
	
	cargar_canciones_de_carpeta()

	if recurso_dialogo:
		await get_tree().create_timer(1.0).timeout
		DialogueManager.show_example_dialogue_balloon(recurso_dialogo, titulo_intro)

func _physics_process(delta: float) -> void:
	# --- 1. ROTACIÓN Y MOVIMIENTO ---
	var input_giro = Input.get_axis("ui_left", "ui_right")
	rotation += input_giro * velocidad_rotacion * delta

	var quiere_acelerar = Input.is_action_pressed("ui_select") # Barra espaciadora
	var tiene_combustible = combustible_actual > 0
	var acelerando_ahora = false

	if quiere_acelerar and tiene_combustible:
		velocity += Vector2.LEFT.rotated(rotation) * potencia_empuje * delta
		combustible_actual -= consumo_por_segundo * delta
		fuego.visible = true 
		acelerando_ahora = true
	else:
		fuego.visible = false
	
	velocity += calcular_gravedad_en_punto(global_position) * delta
	move_and_slide()
	
	# --- 2. CÁMARA Y UI ---
	gestionar_zoom_camara()
	actualizar_telemetria()
	
	# --- 3. TRAYECTORIA DE GRAVEDAD ---
	tiempo_desde_ultimo_calculo += delta
	if tiempo_desde_ultimo_calculo >= intervalo_actualizacion or input_giro != 0 or acelerando_ahora:
		actualizar_linea_trayectoria()
		tiempo_desde_ultimo_calculo = 0.0

	# --- 4. LÓGICA DEL GPS A LA LUNA (FIXED) ---
	if modo_mapa:
		actualizar_gps_lunar()
	else:
		# Si el mapa no está abierto, borramos el GPS para que no quede flotando
		if gps_linea: gps_linea.clear_points()

func _input(event: InputEvent) -> void:
	# --- ACTIVAR/DESACTIVAR MAPA (Tecla M) ---
	if event.is_action_pressed("tecla_m") or (event is InputEventKey and event.pressed and event.keycode == KEY_M):
		if not event.is_echo(): # Evita repeticiones al mantener pulsado
			modo_mapa = !modo_mapa
			if modo_mapa: 
				modo_zoom_total = false # Si abro el mapa, apago el super zoom
			if label_mapa: label_mapa.visible = modo_mapa
			if not modo_mapa and gps_linea:
				gps_linea.clear_points()

	# --- SUPER ZOOM UNIVERSAL (Tecla 0) ---
	if event is InputEventKey and event.pressed and event.keycode == KEY_0:
		if not event.is_echo():
			modo_zoom_total = !modo_zoom_total
			if modo_zoom_total:
				modo_mapa = false # Si meto super zoom, apago el mapa
				if label_mapa: label_mapa.visible = false
				if gps_linea: gps_linea.clear_points()

	# --- MÚSICA Y RADIO ---
	if event.is_action_pressed("tecla_p"):
		gestionar_musica_p()
	
	if event.is_action_pressed("tecla_o") or event.is_action_pressed("tecla_i"):
		if not es_primera_vez_radio: 
			reproducir_aleatorio()

func actualizar_gps_lunar():
	# Buscamos la luna por su nombre exacto en el árbol
	var luna = get_tree().current_scene.find_child("Luna", true, false)
	
	if luna and gps_linea:
		# FIX: Solo agregamos los puntos la primera vez, después los actualizamos.
		# Esto evita el parpadeo de la línea.
		if gps_linea.get_point_count() < 2:
			gps_linea.clear_points()
			gps_linea.add_point(Vector2.ZERO) # Posición 0: La nave
			gps_linea.add_point(to_local(luna.global_position)) # Posición 1: La Luna
		else:
			# Si ya existen los dos puntos, solo actualizamos hacia dónde apunta la punta
			gps_linea.set_point_position(1, to_local(luna.global_position))

func gestionar_zoom_camara() -> void:
	var objetivo = zoom_normal
	
	# --- PRIORIDAD DE ZOOM ---
	if modo_zoom_total:
		# Zoom súper lejano (0.02)
		objetivo = zoom_total 
	elif modo_mapa:
		# Zoom intermedio táctico (0.15)
		objetivo = zoom_mapa
	else: 
		# Zoom dinámico por velocidad cuando volás normal
		var factor_velocidad = velocity.length() / 5000.0 
		var zoom_segun_velocidad = Vector2(1.0, 1.0) / (1.0 + factor_velocidad)
		objetivo = zoom_segun_velocidad.clamp(Vector2(0.2, 0.2), Vector2(1.2, 1.2))
		
	camara.zoom = camara.zoom.lerp(objetivo, suavizado_zoom)

# --- MÚSICA, GRAVEDAD Y TRAYECTORIA SIGUEN INTACTAS ---

func gestionar_musica_p():
	if reproductor.playing:
		reproductor.stop()
		print("Radio apagada.")
	else:
		if es_primera_vez_radio:
			var ruta_intro = "res://Music/intro_naza.mp3" 
			if FileAccess.file_exists(ruta_intro):
				reproductor.stream = load(ruta_intro)
				reproductor.play()
				print("Reproduciendo intro específica.")
			else:
				print("No encontré la intro, cargando aleatoria.")
				reproducir_aleatorio()
			
			if recurso_dialogo:
				DialogueManager.show_example_dialogue_balloon(recurso_dialogo, titulo_radio)
			
			es_primera_vez_radio = false
		else:
			if reproductor.stream == null:
				reproducir_aleatorio()
			else:
				reproductor.play()

func cargar_canciones_de_carpeta():
	lista_canciones.clear()
	var dir = DirAccess.open("res://Music/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".mp3") or file_name.ends_with(".ogg")):
				lista_canciones.append("res://Music/" + file_name)
			file_name = dir.get_next()
		print("NAZA Radio: Se cargaron ", lista_canciones.size(), " temas.")
	else:
		print("ERROR: No se encontró la carpeta res://Music/ (fijate las mayúsculas)")

func reproducir_cancion(indice):
	if lista_canciones.size() > 0:
		indice_actual = indice
		reproductor.stream = load(lista_canciones[indice])
		reproductor.play()
		print("Tocando: ", lista_canciones[indice])

func reproducir_aleatorio():
	if lista_canciones.size() > 0:
		var nuevo_indice = randi() % lista_canciones.size()
		reproducir_cancion(nuevo_indice)

func calcular_gravedad_en_punto(pos: Vector2) -> Vector2:
	var fuerza_total = Vector2.ZERO
	for p in get_tree().get_nodes_in_group("planetas"):
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
	if barra_combustible:
		barra_combustible.value = combustible_actual

func actualizar_linea_trayectoria() -> void:
	var puntos = []
	var pos_s = global_position
	var vel_s = velocity
	var offset_visual = punto_escape.position if punto_escape else Vector2.ZERO
	for i in range(puntos_prediccion):
		var g = calcular_gravedad_en_punto(pos_s)
		vel_s += g * precision_simulacion
		pos_s += vel_s * precision_simulacion
		puntos.append(to_local(pos_s) + offset_visual)
		var impacto = false
		for p in get_tree().get_nodes_in_group("planetas"):
			if pos_s.distance_to(p.global_position) < 65:
				impacto = true; break
		if impacto: break 
	linea_trayectoria.points = puntos
