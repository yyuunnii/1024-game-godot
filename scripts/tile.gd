extends Node2D

@onready var panel: Panel
@onready var label: Label
@onready var particles: CPUParticles2D

var value: int = 2

func _ready():
	panel = $Panel
	label = $Panel/Label
	particles = $Particles
	update_appearance()

# Colors for different values
var colors = {
	2: Color(0.93, 0.89, 0.85),
	4: Color(0.93, 0.88, 0.78),
	8: Color(0.95, 0.69, 0.47),
	16: Color(0.96, 0.58, 0.39),
	32: Color(0.96, 0.48, 0.37),
	64: Color(0.96, 0.37, 0.23),
	128: Color(0.93, 0.81, 0.45),
	256: Color(0.93, 0.80, 0.38),
	512: Color(0.93, 0.79, 0.31),
	1024: Color(0.93, 0.77, 0.25),
	2048: Color(0.93, 0.76, 0.18),
}

var text_colors = {
	2: Color(0.47, 0.43, 0.40),
	4: Color(0.47, 0.43, 0.40),
}

func setup(tile_value: int, pos: Vector2):
	value = tile_value
	position = pos
	# Defer appearance update to ensure nodes are ready
	call_deferred("update_appearance")

func update_appearance():
	# Ensure label is available
	if label == null:
		label = $Panel/Label
	label.text = str(value)
	
	# Set background color
	var bg_color = colors.get(value, Color(0.93, 0.76, 0.18))
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = bg_color
	
	# Set text color
	var text_color = text_colors.get(value, Color.WHITE)
	label.add_theme_color_override("font_color", text_color)
	
	# Adjust font size for larger numbers
	if value >= 1000:
		label.add_theme_font_size_override("font_size", 22)
	elif value >= 100:
		label.add_theme_font_size_override("font_size", 24)
	else:
		label.add_theme_font_size_override("font_size", 28)

func play_merge_effect():
	# Scale bounce
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	
	# Flash color
	var flash_tween = create_tween()
	var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	var original_color = style.bg_color
	flash_tween.tween_property(style, "bg_color", Color.WHITE, 0.05)
	flash_tween.tween_property(style, "bg_color", original_color, 0.1)
	
	# Particles
	particles.color = colors.get(value, Color.GOLD)
	particles.restart()
	particles.emitting = true

func play_spawn_effect():
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
