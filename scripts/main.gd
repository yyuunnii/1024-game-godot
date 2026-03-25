extends Node2D

@onready var board = $Board
@onready var score_label = $ScoreContainer/ScoreLabel
@onready var best_label = $ScoreContainer/BestLabel
@onready var game_over_panel = $GameOverPanel
@onready var win_panel = $WinPanel
@onready var final_score_label = $GameOverPanel/VBox/FinalScore

var score = 0
var best_score = 0
var game_over = false
var won = false
var can_continue = false

const WIN_VALUE = 1024

func _ready():
	start_game()

func start_game():
	score = 0
	game_over = false
	won = false
	can_continue = false
	game_over_panel.visible = false
	win_panel.visible = false
	update_ui()
	board.reset()

func _input(event):
	if game_over:
		if event.is_action_pressed("restart"):
			start_game()
		return
	
	if won and not can_continue:
		return
	
	var moved = false
	
	if event.is_action_pressed("ui_up"):
		moved = board.move(Vector2i.UP)
	elif event.is_action_pressed("ui_down"):
		moved = board.move(Vector2i.DOWN)
	elif event.is_action_pressed("ui_left"):
		moved = board.move(Vector2i.LEFT)
	elif event.is_action_pressed("ui_right"):
		moved = board.move(Vector2i.RIGHT)
	elif event.is_action_pressed("restart"):
		start_game()
		return
	
	if moved:
		await board.animation_finished
		score += board.last_merge_score
		update_ui()
		check_win()
		if not won or can_continue:
			check_game_over()

func update_ui():
	score_label.text = "Score: %d" % score
	best_label.text = "Best: %d" % max(best_score, score)

func check_win():
	if won:
		return
	
	if board.has_value(WIN_VALUE):
		won = true
		win_panel.visible = true
		
		# Animate win panel
		win_panel.scale = Vector2.ZERO
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT_BACK)
		tween.tween_property(win_panel, "scale", Vector2.ONE, 0.5)

func check_game_over():
	if not board.can_move():
		game_over = true
		final_score_label.text = "Final Score: %d" % score
		game_over_panel.visible = true
		
		# Animate game over panel
		game_over_panel.scale = Vector2.ZERO
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT_BACK)
		tween.tween_property(game_over_panel, "scale", Vector2.ONE, 0.5)
		
		if score > best_score:
			best_score = score
			update_ui()

func _on_restart():
	start_game()

func _on_continue():
	can_continue = true
	win_panel.visible = false
