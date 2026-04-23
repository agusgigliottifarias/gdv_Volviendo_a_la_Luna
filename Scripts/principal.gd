extends CanvasLayer

#@export var main_scene: PackedScene

#func _on_menu_button_pressed() -> void:
	## get_tree().change_scene_to_file("res://Scenes/Map.scn")
	#get_tree().change_scene_to_packed(main_scene)


func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/universo.tscn")


func _on_configuracion_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/universo.tscn")


func _on_ruta_vuelo_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/universo.tscn")


func _on_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/universo.tscn")


func _on_salir_pressed() -> void:
	get_tree().free()
