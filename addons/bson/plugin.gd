@tool
extends EditorPlugin


const AUTOLOAD_NAME = "BSON"


#func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	#pass

#func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	#pass

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/bson/bson.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
