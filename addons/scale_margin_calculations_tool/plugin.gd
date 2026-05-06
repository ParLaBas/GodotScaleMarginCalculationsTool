@tool
extends EditorPlugin

var dock_for_scale_margin_calculations: Control

func _enter_tree(
) -> void:
	# Load the UI script and instantiate it
	dock_for_scale_margin_calculations = (
		preload(
			"uid://b58qukrjppssu"
		).new(
			)
	)
	
	dock_for_scale_margin_calculations.name = (
		"Scale/Margin"
	)
	
	# Add it to the right dock in the editor
	add_control_to_dock(
		EditorPlugin.DOCK_SLOT_RIGHT_UL, 
		dock_for_scale_margin_calculations,
	)

func _exit_tree(
) -> void:
	
	if (
		dock_for_scale_margin_calculations
	):
		
		remove_control_from_docks(
			dock_for_scale_margin_calculations
		)
		
		dock_for_scale_margin_calculations.free(
			)
