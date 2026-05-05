
  A Basic Scale and Margin calculation tool for Godot fully written in GDScript

# How to install ? 

Download the scale_margin_calculations_tool folder and put it inside of your Godot's project 'addons' folder. 

Then, go to Project -> Project Settings -> Plugins and enable the plugin.

# What does it do ?

* Calculates the target scale based on original dimensions and the target of the minimum/maximum size in pixels of either width or height
* Calculates the position of the center of the sprite based 
 
# Features

* The position of the center of the sprite takes into account the starting/reference position, the different margins required for x and y as well as the direction (From left to Right/From right to left, and From Top to Bottom/From Bottom to Top)

# How to use ? GUI

Part A: The right scale

1) Enter the original dimensions of the texture
2) Enter the target dimensions
3) Select if those target dimensions are the maximum or the minimum 
e.g. Do you want your sprite to have a maximum width of 64 pixels and height of 128 pixels ? Select fit (max)
e.g. Do you want your sprite to have a minimum width of 256 pixels and height of 128 pixels ? Select cover (min)
4) Apply the scale to the texture: Enter the results into the Inspector tab of the texture -> Transform -> Scale

Part B: The right margins

1) Enter the starting position, which is the reference position from which the margins will start. 
e.g. Do you want to have margins starting from an item positioned at X = 128 and Y = 64 ?  Then enter X = 128 and Y = 64.
e.g. Do you want to have the margins starting from the top left of the screen ? Then enter X = 0 and Y = 0.
2) Select the directions and sizes of margins
e.g. Do you want to have margins going from Left to right and a size of 512 pixels ? then select L to R and put margin X = 512.
e.g. Do you want to have margins going from bottom to top and a size of 128 pixels ? then select Bot to Top and put margin Y = 128.
3) Select whether you want to use the results from Part A (Scale calculator) or not (in which case, select manual scaled size and enter the item size).
4) Enter the results of the position offset into the Inspector tab of the texture -> Transform -> Position

# How to use ? Function calls

| Function                                                                               | Returns   | Use When                                                |
| -------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------- |
| `_get_scale_multiplier_to_fit_or_cover_target_box(original, target, mode)`             | `float`   | You need to know "how much to scale by"                 |
| `_get_resulting_dimensions_after_applying_scale_multiplier(original, scale)`           | `Vector2` | You have a scale and need the new width/height          |
| `_get_center_position_offset_from_starting_coordinate(start, size, direction, margin)` | `Vector2` | You need to place something relative to an anchor point |


## Example — Scale + Position the car

**Scenario:** A 891×283 car needs to:

1.  Fit inside a 64×64 slot
    
2.  Be positioned 128px from the left of the screen, and 64px from the top of the screen


````
extends Node2D

const FOLLOW_SPEED = 4.0

@export var child_car1: Node2D


var weight_calculation
var new_position

func _ready() -> void:
	
	var original_car_size = (
		Vector2(
		891, # Width
		283, # Height
		)
	)
	var target_slot_size = (
		Vector2(
		64, # Width
		64, # Height
		)
	)

	# ===== STEP 1: SCALE =====
	var new_calculated_scale = (
		ScaleMarginCaculationsTool._get_scale_multiplier_to_fit_or_cover_target_box(
		original_car_size,
		target_slot_size,
		ScaleMarginCaculationsTool.FitMode.FIT_INSIDE
		)
	)
	
	print(
		"new_calculated_scale = ", 
		new_calculated_scale
	)

	var scaled_down_car_size = (
		ScaleMarginCaculationsTool._get_resulting_dimensions_after_applying_scale_multiplier(
		original_car_size,
		new_calculated_scale,
		)
	)
	
	print(
		"scaled_down_car_size = ", 
		scaled_down_car_size
	)
	
	# ===== STEP 2: POSITION =====
	
	var start_pos = (
		Vector2(
		0, # Start margins at top (0)
		0, # Start margins at left (0)
		)
	)
	
	var direction = (
		Vector2(
			1.0, # Direction: Left to RIGHT (+1)
			1.0, # Direction: Top to BOTTOM (+1)
		)
	)
	
	var margin = (
		Vector2(
		128, # Margins: X = 128, Y = 64
		64, # Margins: X = 128, Y = 64
		)
	)
	
	new_position = (
		ScaleMarginCaculationsTool._get_center_position_offset_from_starting_coordinate(
		start_pos,
		scaled_down_car_size,
		direction,
		margin
		)
	)
	
	print(
		"new_position = ", 
		new_position
	)

# Here, the car will move to the new position
func _physics_process(
	delta: float
) -> void:
	
	weight_calculation = 1 - exp(-FOLLOW_SPEED * delta)
	
	child_car1.global_position = (
		lerp(
			child_car1.global_position, 
			new_position, 
			weight_calculation,
		)
	)






