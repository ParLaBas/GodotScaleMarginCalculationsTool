@tool
extends ScrollContainer
class_name ScaleMarginCaculationsTool

enum FitMode { FIT_INSIDE, COVER }
enum SizeSource { ORIGINAL, STEP_1_RESULT, MANUAL_SCALED }

# --- State Variables (UI State) ---
var orig_w: float = 1000.0
var orig_h: float = 500.0
var target_w: float = 64.0
var target_h: float = 64.0
var fit_mode: int = FitMode.FIT_INSIDE

var start_x: float = 0.0
var start_y: float = 0.0
var dir_x: int = 0 # 0 for (+), 1 for (-)
var dir_y: int = 0 # 0 for (+), 1 for (-)

var size_source: int = SizeSource.STEP_1_RESULT
var scale_val: float = 1.0

var margin_x: float = 64.0
var margin_y: float = 64.0

var manual_scaled_w: float = 64.0
var manual_scaled_h: float = 32.0

# --- UI Element References ---
var lbl_scale: Label
var lbl_result: Label
var lbl_offset_x: Label
var lbl_offset_y: Label

var box_original_scale: Control
var box_step1_label: Control
var box_manual_scale: Control


# ==========================================
# --- Pure Math Functions (Callable from external code) ---
# ==========================================

## Calculates the required scale multiplier to fit/cover a target box.
## Returns a single float: the scale multiplier.
static func _get_scale_multiplier_to_fit_or_cover_target_box(
	original_width_and_height: Vector2, 
	target_bounding_box_width_and_height: Vector2, 
	scale_fit_or_cover_mode: FitMode
) -> float:
	
	# Prevent division by zero
	var safe_original_width = original_width_and_height.x if original_width_and_height.x != 0 else 0.001
	var safe_original_height = original_width_and_height.y if original_width_and_height.y != 0 else 0.001
	
	var scale_multiplier_for_width = target_bounding_box_width_and_height.x / safe_original_width
	var scale_multiplier_for_height = target_bounding_box_width_and_height.y / safe_original_height
	
	var final_scale_multiplier: float
	
	if scale_fit_or_cover_mode == FitMode.FIT_INSIDE:
		final_scale_multiplier = minf(scale_multiplier_for_width, scale_multiplier_for_height)
	else:
		final_scale_multiplier = maxf(scale_multiplier_for_width, scale_multiplier_for_height)
		
	return final_scale_multiplier


## Calculates the final width and height after applying a scale multiplier to an original size.
## Returns a single Vector2: the resulting dimensions.
static func _get_resulting_dimensions_after_applying_scale_multiplier(
	original_width_and_height: Vector2,
	scale_multiplier: float
) -> Vector2:
	
	var final_calculated_width = original_width_and_height.x * scale_multiplier
	var final_calculated_height = original_width_and_height.y * scale_multiplier
	
	return Vector2(final_calculated_width, final_calculated_height)


## Takes a starting coordinate and calculates where the CENTER of an object will be placed, 
## moving in a specific direction (positive or negative), and factoring in half its size + margin.
## Returns a single Vector2: the center position offset from the starting coordinate.
static func _get_center_position_offset_from_starting_coordinate(
	starting_coordinate_point: Vector2, 
	element_width_and_height_dimensions: Vector2, 
	direction_modifier_1_or_minus_1: Vector2, 
	additional_margin_padding: Vector2
) -> Vector2:
	
	var half_element_width = element_width_and_height_dimensions.x / 2.0
	var half_element_height = element_width_and_height_dimensions.y / 2.0
	
	var total_movement_distance_x = half_element_width + additional_margin_padding.x
	var total_movement_distance_y = half_element_height + additional_margin_padding.y
	
	var final_center_x_position = starting_coordinate_point.x + (direction_modifier_1_or_minus_1.x * total_movement_distance_x)
	var final_center_y_position = starting_coordinate_point.y + (direction_modifier_1_or_minus_1.y * total_movement_distance_y)
	
	return Vector2(final_center_x_position, final_center_y_position)


# ==========================================
# --- UI Setup & Logic ---
# ==========================================

func _init() -> void:
	# Setup main container
	custom_minimum_size = Vector2(280, 0)
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(main_vbox)
	
	main_vbox.add_child(_header("Scale & Margin Tool"))
	
	# STEP 1: SCALE
	main_vbox.add_child(HSeparator.new())
	main_vbox.add_child(_header("1) Scale Calculator"))
	
	main_vbox.add_child(_create_row("Original:", [
		_spinbox("W ", orig_w, func(v): orig_w = v),
		_spinbox("H ", orig_h, func(v): orig_h = v)
	]))
	
	main_vbox.add_child(_create_row("Target:", [
		_spinbox("W ", target_w, func(v): target_w = v),
		_spinbox("H ", target_h, func(v): target_h = v)
	]))
	
	var fit_opt = OptionButton.new()
	fit_opt.add_item("Fit (max)", FitMode.FIT_INSIDE)
	fit_opt.add_item("Cover (min)", FitMode.COVER)
	fit_opt.selected = fit_mode
	fit_opt.item_selected.connect(func(idx): fit_mode = idx; _recalculate_ui_values())
	main_vbox.add_child(_create_row("Mode:", [fit_opt]))
	
	lbl_scale = Label.new()
	lbl_result = Label.new()
	main_vbox.add_child(lbl_scale)
	main_vbox.add_child(lbl_result)
	
	# STEP 2: POSITION
	main_vbox.add_child(HSeparator.new())
	main_vbox.add_child(_header("2) Position (center-based)"))
	
	main_vbox.add_child(_create_row("Start Pos:", [
		_spinbox("X ", start_x, func(v): start_x = v),
		_spinbox("Y ", start_y, func(v): start_y = v)
	]))
	
	var opt_dir_x = OptionButton.new()
	opt_dir_x.add_item("+ (L to R)")
	opt_dir_x.add_item("- (R to L)")
	opt_dir_x.selected = dir_x
	opt_dir_x.item_selected.connect(func(idx): dir_x = idx; _recalculate_ui_values())
	
	var opt_dir_y = OptionButton.new()
	opt_dir_y.add_item("+ (Top to Bot)")
	opt_dir_y.add_item("- (Bot to Top)")
	opt_dir_y.selected = dir_y
	opt_dir_y.item_selected.connect(func(idx): dir_y = idx; _recalculate_ui_values())
	
	main_vbox.add_child(_create_row("Dir X/Y:", [opt_dir_x, opt_dir_y]))
	
	main_vbox.add_child(_create_row("Margin:", [
		_spinbox("X ", margin_x, func(v): margin_x = v),
		_spinbox("Y ", margin_y, func(v): margin_y = v)
	]))
	
	main_vbox.add_child(_label("Size source:"))
	var source_opt = OptionButton.new()
	source_opt.add_item("Original size", SizeSource.ORIGINAL)
	source_opt.add_item("Use Step 1 result", SizeSource.STEP_1_RESULT)
	source_opt.add_item("Manual scaled size", SizeSource.MANUAL_SCALED)
	source_opt.selected = size_source
	source_opt.item_selected.connect(func(idx): size_source = idx; _recalculate_ui_values())
	main_vbox.add_child(source_opt)
	
	box_original_scale = _create_row("Scale:", [_spinbox("", scale_val, func(v): scale_val = v)])
	box_step1_label = _label("Using Step 1 computed size")
	box_manual_scale = _create_row("Scaled:", [
		_spinbox("W ", manual_scaled_w, func(v): manual_scaled_w = v),
		_spinbox("H ", manual_scaled_h, func(v): manual_scaled_h = v)
	])
	
	main_vbox.add_child(box_original_scale)
	main_vbox.add_child(box_step1_label)
	main_vbox.add_child(box_manual_scale)
	
	main_vbox.add_child(HSeparator.new())
	main_vbox.add_child(_label("Center position offset from start:"))
	
	lbl_offset_x = Label.new()
	lbl_offset_y = Label.new()
	lbl_offset_x.add_theme_font_override("font", ThemeDB.fallback_font)
	lbl_offset_y.add_theme_font_override("font", ThemeDB.fallback_font)
	main_vbox.add_child(lbl_offset_x)
	main_vbox.add_child(lbl_offset_y)
	
	main_vbox.add_child(HSeparator.new())
	
	_recalculate_ui_values()

# --- Connecting UI to Pure Math Functions ---
func _recalculate_ui_values() -> void:
	# 1. Use pure function for Step 1 - get scale multiplier
	var ui_calculated_scale_multiplier = _get_scale_multiplier_to_fit_or_cover_target_box(
		Vector2(orig_w, orig_h), 
		Vector2(target_w, target_h), 
		fit_mode
	)
	
	# 1b. Get resulting dimensions using the scale multiplier
	var ui_calculated_resulting_dimensions = _get_resulting_dimensions_after_applying_scale_multiplier(
		Vector2(orig_w, orig_h),
		ui_calculated_scale_multiplier
	)
	
	lbl_scale.text = "Scale: %.4f" % ui_calculated_scale_multiplier
	lbl_result.text = "Result: %.2f x %.2f" % [ui_calculated_resulting_dimensions.x, ui_calculated_resulting_dimensions.y]
	
	# UI Visibility Toggle
	box_original_scale.visible = (size_source == SizeSource.ORIGINAL)
	box_step1_label.visible = (size_source == SizeSource.STEP_1_RESULT)
	box_manual_scale.visible = (size_source == SizeSource.MANUAL_SCALED)
	
	# Determine base size for Step 2
	var final_size_to_use_for_offset_calculation: Vector2
	match size_source:
		SizeSource.ORIGINAL:
			final_size_to_use_for_offset_calculation = Vector2(orig_w * scale_val, orig_h * scale_val)
		SizeSource.STEP_1_RESULT:
			final_size_to_use_for_offset_calculation = ui_calculated_resulting_dimensions
		SizeSource.MANUAL_SCALED:
			final_size_to_use_for_offset_calculation = Vector2(manual_scaled_w, manual_scaled_h)
			
	var math_direction_signs = Vector2(
		1.0 if dir_x == 0 else -1.0,
		1.0 if dir_y == 0 else -1.0
	)
			
	# 2. Use pure function for Step 2
	var final_ui_calculated_center_offset = _get_center_position_offset_from_starting_coordinate(
		Vector2(start_x, start_y),
		final_size_to_use_for_offset_calculation,
		math_direction_signs,
		Vector2(margin_x, margin_y)
	)
	
	lbl_offset_x.text = "X = %.2f" % final_ui_calculated_center_offset.x
	lbl_offset_y.text = "Y = %.2f" % final_ui_calculated_center_offset.y


# --- UI Helper Functions ---
static func _label(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	return l

static func _header(txt: String) -> Label:
	var l = _label(txt)
	l.add_theme_font_size_override("font_size", 16)
	return l

static func _create_row(label_text: String, controls: Array) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	var l = _label(label_text)
	l.custom_minimum_size = Vector2(70, 0)
	hbox.add_child(l)
	for c in controls:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(c)
	return hbox

func _spinbox(prefix: String, val: float, callback: Callable) -> SpinBox:
	var sb = SpinBox.new()
	sb.min_value = -99999.0
	sb.max_value = 99999.0
	sb.step = 0.01
	sb.value = val
	sb.prefix = prefix
	sb.custom_arrow_step = 1.0
	sb.value_changed.connect(func(new_val):
		callback.call(new_val)
		_recalculate_ui_values()
	)
	return sb
