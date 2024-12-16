extends Node2D
#Developed by jlwilley

#reference to the puzzle Board Display
var puzzleBoard

#reference to the consonants display
var consonants

#reference to the vowels display
var vowels

#reference to the score Panel
var scorePanel

#reference to the control Panel
var controlPanel

#Scores and Bank values for each team
@onready var team1Score:float = 0
@onready var team2Score:float = 0
@onready var team3Score:float = 0
@onready var team1Bank:float = 0
@onready var team2Bank:float = 0
@onready var team3Bank:float = 0


#reference to the window the control panel will be drawn in
@onready var control_window = get_node("Window")

#the main display window
@onready var main_window = get_viewport().get_window()

#video player for main display
@onready var videoPlayer = get_node("CanvasLayer/BoardControl/VideoStreamPlayer")

# Called when the node enters the scene tree for the first time.
func _ready():
	#creates a control panel window and makes it visible
	controlPanel = preload("res://scenes/control_panel.tscn").instantiate()
	controlPanel.setup(self)
	control_window.add_child(controlPanel)
	control_window.visible = true
	#updates references
	puzzleBoard = get_node("CanvasLayer/BoardControl/Puzzleboard")
	consonants = get_node("CanvasLayer/BoardControl/Consonants")
	vowels = get_node("CanvasLayer/BoardControl/Vowel Panel")
	scorePanel = get_node("CanvasLayer/BoardControl/ScorePanel")
	#refresh the scoreboard to display properly
	refreshScore()

#handle for alt enter keybind for fullscreen
func _input(_event):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		print("toggling fullscreen")
		if main_window.mode == Window.MODE_WINDOWED:
			main_window.mode = Window.MODE_FULLSCREEN
		else:
			main_window.mode = Window.MODE_WINDOWED

#when closing the control panel window save the puzzles first
func _on_window_close_requested():
	print("close requested")
	await controlPanel.save_puzzles()
	control_window.queue_free()

#takes in the teams numbers and a new name to update the team to
func updateTeamName(team, newName):
	if(team == 1):
		var team1Node = get_node("CanvasLayer/BoardControl/ScorePanel/team1Panel/teamName")
		team1Node.text = newName
	elif(team == 2):
		var team2Node = get_node("CanvasLayer/BoardControl/ScorePanel/team2Panel/teamName")
		team2Node.text = newName
	elif(team == 3):
		var team3Node = get_node("CanvasLayer/BoardControl/ScorePanel/team3Panel/teamName")
		team3Node.text = newName
	else:
		print("Invalid team name to update")
	controlPanel.refresh()


#resets the round with a new puzzle displayed on the board
func setup(clue, answer):
	await bank()
	await refreshScore()
	await reset()
	var clueLabel = get_node("CanvasLayer/BoardControl/CluePanel/ClueLabel")
	clueLabel.text = clue
	await puzzleBoard.formatStringToBoard(answer)
	puzzleBoard.setup_player.play()

#solves the puzzle
func solve():
	puzzleBoard.revealAll()
	puzzleBoard.solve_player.play()

#resets to its default state
func reset():
	for con in get_node("CanvasLayer/BoardControl/Consonants/HBoxContainer").get_children():
			con.set("theme_override_colors/font_color", Color(1,1,1))
	for vow in get_node("CanvasLayer/BoardControl/Vowel Panel/HBoxContainer").get_children():
			vow.set("theme_override_colors/font_color", Color(1,1,1))
	puzzleBoard.resetBoard()

#reveals the specified letter on the puzzle board
func reveal(letter):
	for con in get_node("CanvasLayer/BoardControl/Consonants/HBoxContainer").get_children():
		if(con.text.capitalize() == letter.capitalize()):
			con.set("theme_override_colors/font_color", Color(1,0,0))
	for vow in get_node("CanvasLayer/BoardControl/Vowel Panel/HBoxContainer").get_children():
		if(vow.text.capitalize() == letter.capitalize()):
			vow.set("theme_override_colors/font_color", Color(1,0,0))
	return await puzzleBoard.reveal(letter)

#refreshes the scoreboard with the most up to date values
func refreshScore():
	var team1Display = get_node("CanvasLayer/BoardControl/ScorePanel/team1Panel/points")
	var team2Display = get_node("CanvasLayer/BoardControl/ScorePanel/team2Panel/points")
	var team3Display = get_node("CanvasLayer/BoardControl/ScorePanel/team3Panel/points")
	team1Display.text = "$ " + str(team1Score)
	team2Display.text = "$ " + str(team2Score)
	team3Display.text = "$ " + str(team3Score)
	controlPanel.refresh()

#updates the specified teams points to a specific value
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

#makes the specified team go bankrupt
func bankrupt(team):
	puzzleBoard.bankrupt_player.play()
	updatePoints(team, 0)

#updates the specified teams bank value
func updateBank(team, points):
	if(points is float || points is int):
		if(team == 1):
			team1Bank = points
		elif(team == 2):
			team2Bank = points
		elif(team == 3):
			team3Bank = points
		else:
			print("Invalid Team Score")
		refreshScore()
	else:
		print("Invalid points value")

#add points to the specified team
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

#gets the score of the specified team
func getScore(team):
	if(team == 1):
		return team1Score
	elif(team == 2):
		return team2Score
	else:
		return team3Score

#banks all the score values for each team
func bank():
	team1Bank += team1Score
	team1Score = 0
	team2Bank += team2Score
	team2Score = 0
	team3Bank += team3Score
	team3Score = 0
	refreshScore()

#hides the current bank values for each team
func hideBank():
	team1Score = 0
	team2Score = 0
	team3Score = 0
	refreshScore()

#shows the current bank values for each team
func showBank():
	bank()
	team1Score = team1Bank
	team2Score = team2Bank
	team3Score = team3Bank
	refreshScore()

#select the team showing its there turn
func selectTeam(team):
	var team1Panel = get_node("CanvasLayer/BoardControl/ScorePanel/team1Panel")
	var team2Panel = get_node("CanvasLayer/BoardControl/ScorePanel/team2Panel")
	var team3Panel = get_node("CanvasLayer/BoardControl/ScorePanel/team3Panel")
	if team == 1:
		team1Panel.get_theme_stylebox("panel", "Panel").border_color = Color(0,1,0)
		team2Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
		team3Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
	elif team == 2:
		team1Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
		team2Panel.get_theme_stylebox("panel", "Panel").border_color = Color(0,1,0)
		team3Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
	else:
		team1Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
		team2Panel.get_theme_stylebox("panel", "Panel").border_color = Color(1,1,1)
		team3Panel.get_theme_stylebox("panel", "Panel").border_color = Color(0,1,0)
