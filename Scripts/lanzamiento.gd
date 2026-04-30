extends Node2D


@onready var ala_izq = $Obelisco2/Izquierda
@onready var ala_der = $Obelisco2/Derecha
@onready var nave_nodo = $Nave # Usamos el nodo que ahora es Node2D
@onready var fuego = $Nave/Fuego
@onready var audio = $AudioStreamPlayer

@export var recurso_dialogo: DialogueResource

var puede_lanzar: bool = false
var lanzando: bool = false

func _ready() -> void:
	# 1. Estado inicial
	if fuego: 
		fuego.visible = false
	
	# BLOQUEO DE SEGURIDAD:
	# Desactivamos el script interno de la nave para que no interfiera con el despegue
	nave_nodo.set_physics_process(false) 
	nave_nodo.set_process(false)

	if recurso_dialogo:
		await get_tree().create_timer(1.0).timeout
		# Lanzamos el diálogo inicial
		DialogueManager.show_example_dialogue_balloon(recurso_dialogo, "intro_obelisco")
		
		# Esperamos a que termine el diálogo para habilitar el espacio
		await DialogueManager.dialogue_ended
		puede_lanzar = true
		print("NAZA: Diálogo terminado. Esperando ESPACIO.")

func _input(event: InputEvent) -> void:
	if puede_lanzar and not lanzando:
		if event.is_action_pressed("ui_accept"): # Barra espaciadora
			iniciar_secuencia_naza()

func iniciar_secuencia_naza():
	lanzando = true
	puede_lanzar = false
	
	print("NAZA: ¡Iniciando motores!")
	
	# 2. IGNICIÓN: El fuego y el audio arrancan al tocar Espacio
	if fuego: 
		fuego.visible = true
	audio.play()
	
	# 3. ANIMACIÓN DEL OBELISCO (Alas se abren mientras hay espera)
	var tween_alas = create_tween().set_parallel(true)
	tween_alas.tween_property(ala_izq, "position:x", ala_izq.position.x - 200, 5.0)
	tween_alas.tween_property(ala_izq, "rotation_degrees", -45, 5.0)
	tween_alas.tween_property(ala_der, "position:x", ala_der.position.x + 200, 5.0)
	tween_alas.tween_property(ala_der, "rotation_degrees", 45, 5.0)
	
	# 4. ASCENSO DE LA NAVE (Con espera de 11 segundos)
	var tween_nave = create_tween()
	
	# --- ESPERA DE 11 SEGUNDOS ANTES DE MOVERSE ---
	tween_nave.tween_interval(9.0) # Espera exacta antes de subir
	# ----------------------------------------------
	
	# Usamos global_position para el ascenso imparable
	var destino_y = nave_nodo.global_position.y - 6000
	tween_nave.tween_property(nave_nodo, "global_position:y", destino_y, 12.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	print("NAZA: Despegue iniciado. La nave subirá en 9 segundos.")

	# 5. DIÁLOGO DE LA ATMÓSFERA (Durante la subida)
	# Esperamos a que empiece el movimiento para el relato
	await get_tree().create_timer(12.0).timeout 
	if recurso_dialogo:
		tween_nave.tween_interval(9.0)
		DialogueManager.show_example_dialogue_balloon(recurso_dialogo, "atmosfera")
		await DialogueManager.dialogue_ended
	
	# 6. ESPERA DEL AUDIO (Asegura que el sonido termine antes de cambiar escena)
	if audio.playing:
		print("NAZA: Esperando final del audio...")
		await audio.finished
	
	# 7. CAMBIO DE ESCENA
	print("NAZA: Despegue completado. Entrando en órbita.")
	get_tree().change_scene_to_file("res://Scenes/universo.tscn") # Verifica que la ruta sea correcta
