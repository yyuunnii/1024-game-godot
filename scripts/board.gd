extends Node2D

@export var tile_scene: PackedScene

@onready var tiles_container = $Tiles
@onready var effects_container = $Effects

const GRID_SIZE = 4
const TILE_SIZE = 90
const TILE_SPACING = 95
const ANIMATION_DURATION = 0.15

var grid = []
var tiles = {}
var last_merge_score = 0
var animation_finished = true

# Tile colors for different values
var tile_colors = {
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

var tile_text_colors = {
	2: Color(0.47, 0.43, 0.40),
	4: Color(0.47, 0.43, 0.40),
}

func _ready():
	reset()

func reset():
	# Clear existing tiles
	for tile in tiles_container.get_children():
		tile.queue_free()
	for effect in effects_container.get_children():
		effect.queue_free()
	
	tiles.clear()
	grid = []
	for x in range(GRID_SIZE):
		grid.append([])
		for y in range(GRID_SIZE):
			grid[x].append(0)
	
	last_merge_score = 0
	animation_finished = true
	
	# Spawn initial tiles
	spawn_tile()
	spawn_tile()

func get_tile_position(x: int, y: int) -> Vector2:
	var offset = (GRID_SIZE * TILE_SPACING) / 2.0 - TILE_SPACING / 2.0
	return Vector2(
		x * TILE_SPACING - offset,
		y * TILE_SPACING - offset
	)

func spawn_tile():
	var empty_cells = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == 0:
				empty_cells.append(Vector2i(x, y))
	
	if empty_cells.size() == 0:
		return
	
	var pos = empty_cells[randi() % empty_cells.size()]
	var value = 4 if randf() > 0.9 else 2
	
	grid[pos.x][pos.y] = value
	
	var tile = tile_scene.instantiate()
	tile.setup(value, get_tile_position(pos.x, pos.y))
	tiles[pos] = tile
	tiles_container.add_child(tile)
	
	# Spawn animation
	tile.play_spawn_effect()

func move(direction: Vector2i) -> bool:
	if not animation_finished:
		return false
	
	animation_finished = false
	var moved = false
	last_merge_score = 0
	
	var new_grid = []
	for x in range(GRID_SIZE):
		new_grid.append([])
		for y in range(GRID_SIZE):
			new_grid[x].append(grid[x][y])
	
	if direction == Vector2i.LEFT:
		for y in range(GRID_SIZE):
			var line = []
			for x in range(GRID_SIZE):
				line.append(grid[x][y])
			var result = process_line(line)
			for x in range(GRID_SIZE):
				if new_grid[x][y] != result[x]:
					moved = true
				new_grid[x][y] = result[x]
	elif direction == Vector2i.RIGHT:
		for y in range(GRID_SIZE):
			var line = []
			for x in range(GRID_SIZE):
				line.append(grid[x][y])
			line.reverse()
			var result = process_line(line)
			for x in range(GRID_SIZE):
				if new_grid[3-x][y] != result[x]:
					moved = true
				new_grid[3-x][y] = result[x]
	elif direction == Vector2i.UP:
		for x in range(GRID_SIZE):
			var line = []
			for y in range(GRID_SIZE):
				line.append(grid[x][y])
			var result = process_line(line)
			for y in range(GRID_SIZE):
				if new_grid[x][y] != result[y]:
					moved = true
				new_grid[x][y] = result[y]
	elif direction == Vector2i.DOWN:
		for x in range(GRID_SIZE):
			var line = []
			for y in range(GRID_SIZE):
				line.append(grid[x][y])
			line.reverse()
			var result = process_line(line)
			for y in range(GRID_SIZE):
				if new_grid[x][3-y] != result[y]:
					moved = true
				new_grid[x][3-y] = result[y]
	
	if moved:
		await get_tree().create_timer(ANIMATION_DURATION).timeout
		
		# Update grid and spawn new tile
		grid = new_grid
		update_tile_positions()
		spawn_tile()
	
	animation_finished = true
	return moved

func process_line(line: Array) -> Array:
	var result = []
	var non_zero = []
	
	# Remove zeros
	for val in line:
		if val != 0:
			non_zero.append(val)
	
	# Merge
	var i = 0
	while i < non_zero.size():
		if i + 1 < non_zero.size() and non_zero[i] == non_zero[i + 1]:
			var merged = non_zero[i] * 2
			result.append(merged)
			last_merge_score += merged
			i += 2
		else:
			result.append(non_zero[i])
			i += 1
	
	# Pad with zeros
	while result.size() < GRID_SIZE:
		result.append(0)
	
	return result

func update_tile_positions():
	# Remove old tiles
	for pos in tiles.keys():
		if tiles[pos]:
			tiles[pos].queue_free()
	tiles.clear()
	
	# Create new tiles
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] != 0:
				var tile = tile_scene.instantiate()
				tile.setup(grid[x][y], get_tile_position(x, y))
				tiles[Vector2i(x, y)] = tile
				tiles_container.add_child(tile)

func can_move() -> bool:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == 0:
				return true
			if x < GRID_SIZE - 1 and grid[x][y] == grid[x + 1][y]:
				return true
			if y < GRID_SIZE - 1 and grid[x][y] == grid[x][y + 1]:
				return true
	return false

func has_value(value: int) -> bool:
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == value:
				return true
	return false
