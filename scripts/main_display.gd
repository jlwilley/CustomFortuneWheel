extends Node2D

var puzzleBoard
var consonants
var vowels
var scorePanel
var controlPanel

@onready var team1Score:float = 0
@onready var team2Score:float = 0
@onready var team3Score:float = 0
@onready var team1Bank:float = 0
@onready var team2Bank:float = 0
@onready var team3Bank:float = 0



@onready var control_window = get_node("Window")
@onready var main_window = get_viewport().get_window()
# Called when the node enters the scene tree for the first time.
func _ready():
	controlPanel = preload("res://scenes/control_panel.tscn").instantiate()
	controlPanel.setup(self)
	control_window.add_child(controlPanel)
	control_window.visible = true
	var original_font = control_window.get_theme_font("font","")
	var font_instance = original_font.duplicate()
	control_window.add_theme_font_override("font", font_instance)
	puzzleBoard = get_node("CanvasLayer/BoardControl/Puzzleboard")
	consonants = get_node("CanvasLayer/BoardControl/Consonants")
	vowels = get_node("CanvasLayer/BoardControl/Vowel Panel")
	scorePanel = get_node("CanvasLayer/BoardControl/ScorePanel")
	setup("test", "test puzzle")

func _input(event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		print("toggling fullscreen")
		if main_window.mode == Window.MODE_WINDOWED:
			main_window.mode = Window.MODE_FULLSCREEN
			controlPanel.queue_redraw()
		else:
			main_window.mode = Window.MODE_WINDOWED
			controlPanel.queue_redraw()


func _on_window_close_requested():
	print("close requested")
	control_window.queue_free()
	await controlPanel.save_puzzles()

func updateTeamName(team, name):
	if(team == 1):
		var team1Node = get_node("CanvasLayer/BoardControl/ScorePanel/team1Panel/teamName")
		team1Node.text = name
	elif(team == 2):
		var team2Node = get_node("CanvasLayer/BoardControl/ScorePanel/team2Panel/teamName")
		team2Node.text = name
	elif(team == 3):
		var team3Node = get_node("CanvasLayer/BoardControl/ScorePanel/team3Panel/teamName")
		team3Node.text = name
	else:
		print("Invalid team name to update")
	controlPanel.refresh()

func setup(clue, answer):
	await bank()
	await refreshScore()
	await reset()
	var clueLabel = get_node("CanvasLayer/BoardControl/CluePanel/ClueLabel")
	clueLabel.text = clue
	await puzzleBoard.formatStringToBoard(answer)
	puzzleBoard.setup_player.play()

func solve():
	puzzleBoard.revealAll()
	puzzleBoard.solve_player.play()

func reset():
	for con in get_node("CanvasLayer/BoardControl/Consonants/HBoxContainer").get_children():
			con.set("theme_override_colors/font_color", Color(1,1,1))
	for vow in get_node("CanvasLayer/BoardControl/Vowel Panel/HBoxContainer").get_children():
			vow.set("theme_override_colors/font_color", Color(1,1,1))
	puzzleBoard.resetBoard()

func reveal(letter):
	for con in get_node("CanvasLayer/BoardControl/Consonants/HBoxContainer").get_children():
		if(con.text.capitalize() == letter.capitalize()):
			con.set("theme_override_colors/font_color", Color(1,0,0))
	for vow in get_node("CanvasLayer/BoardControl/Vowel Panel/HBoxContainer").get_children():
		if(vow.text.capitalize() == letter.capitalize()):
			vow.set("theme_override_colors/font_color", Color(1,0,0))
	return await puzzleBoard.reveal(letter)

func refreshScore():
	var team1Display = get_node("CanvasLayer/BoardControl/ScorePanel/team1Panel/points")
	var team2Display = get_node("CanvasLayer/BoardControl/ScorePanel/team2Panel/points")
	var team3Display = get_node("CanvasLayer/BoardControl/ScorePanel/team3Panel/points")
	team1Display.text = "$ " + str(team1Score)
	team2Display.text = "$ " + str(team2Score)
	team3Display.text = "$ " + str(team3Score)
	controlPanel.refresh()

func updatePoints(team, points):
	if(points is float || points is int):
		if(team == 1):
			team1Score = points
		elif(team == 2):
			team2Score = points
		elif(team == 3):
			team3Score = points
		else:
			print("Invalid Team Score")
		refreshScore()
	else:
		print("Invalid points value")


func addPoints(team, points):
	if(points is float || points is int):
		if(team == 1):
			team1Score += points
		elif(team == 2):
			team2Score += points
		elif(team == 3):
			team3Score += points
		else:
			print("Invalid Team Score")
		refreshScore()
	else:
		print("Invalid points value")


func bank():
	team1Bank += team1Score
	team1Score = 0
	team2Bank += team2Score
	team2Score = 0
	team3Bank += team3Score
	team3Score = 0
	refreshScore()

func hideBank():
	team1Score = 0
	team2Score = 0
	team3Score = 0
	refreshScore()

func showBank():
	team1Score = team1Bank
	team2Score = team2Bank
	team3Score = team3Bank
	refreshScore()
