@tool
extends EditorPlugin

var dock: Control

func _enter_tree(
) -> void:
	# Load the UI script and instantiate it
	dock = (
		preload(
			"uid://b58qukrjppssu"
		).new(
			)
	)
	
	dock.name = (
		"Scale/Margin"
	)
	
	# Add it to the right dock in the editor
	add_control_to_dock(
		EditorPlugin.DOCK_SLOT_RIGHT_UL, 
		dock
	)

func _exit_tree(
) -> void:
	
	if (
		dock
	):
		
		remove_control_from_docks(
			dock
		)
		
		dock.free(
			)
