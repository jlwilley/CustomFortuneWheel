extends Node2D

var main_display
var puzzles
var currentReward
# Filepath for saving
var save_path = "user://puzzles.json"
@onready var puzzleSelector = get_node("CanvasLayer/Control/puzzleControls/managePuzzleBox/VBoxContainer/puzzleSelector")

class puzzle:
	var clue
	var solution
	var reward
	
	# Convert puzzle instance to a dictionary
	func to_dict() -> Dictionary:
		return {
			"clue": clue,
			"solution": solution,
			"reward": reward,
		}
	
# Create a puzzle instance from a dictionary
static func from_dict(data: Dictionary) -> puzzle:
	var instance = puzzle.new()
	instance.clue = data.get("clue", "")
	instance.solution = data.get("solution", "")
	instance.reward = data.get("reward", 0)
	return instance

func _on_about_to_quit():
	print("Exit Called Saving")
	save_puzzles()

# Called when the node enters the scene tree for the first time.
func _ready():
	puzzles = []
	currentReward = 0
	load_puzzles()
	
func _input(event):
	var control_window = get_viewport().get_window()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		print("toggling fullscreen")
		if control_window.mode == Window.MODE_WINDOWED:
			control_window.mode = Window.MODE_FULLSCREEN
		else:
			control_window.mode = Window.MODE_WINDOWED 
			
func setup(mainDisplay):
	main_display = mainDisplay

func refresh():
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry9/currentTeamName").text = str(main_display.team1Score)
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry13/currentTeamName").text = str(main_display.team1Bank)
	get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry9/currentTeamName").text = str(main_display.team2Score)
	get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry13/currentTeamName").text = str(main_display.team2Bank)
	get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry9/currentTeamName").text = str(main_display.team3Score)
	get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry13/currentTeamName").text = str(main_display.team3Bank)

func refreshPuzzles():
	puzzleSelector.clear()
	for item in puzzles:
		puzzleSelector.add_item(item.clue)
	
func _on_team_1_update_name_pressed():
	var textBoxNode = get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry6/teamTextBox")
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry5/currentTeamName").text = textBoxNode.text
	main_display.updateTeamName(1, textBoxNode.text)
	textBoxNode.text = "Team 1"


func save_puzzles():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		# Convert each puzzle in the array to a dictionary
		var serialized_array = []
		for puzzle in puzzles:
			serialized_array.append(puzzle.to_dict())
		
		var json_data = JSON.stringify(serialized_array)  # Serialize the array of dictionaries
		file.store_string(json_data)
		file.close()
		print("Array saved successfully!")
	else:
		print("Failed to save the file.")

	
func load_puzzles():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_data = file.get_as_text()  # Read the file's content
			file.close()
			# Parse the JSON data
			var parsed_result = JSON.parse_string(json_data)
			if parsed_result:
				# Convert each dictionary back into a Puzzle instance
				puzzles = []
				for data in parsed_result:
					puzzles.append(from_dict(data))
				print("Array loaded successfully: ", puzzles)
			else:
				print("Error parsing JSON: Invalid format")
		else:
			print("Failed to open the file.")
	else:
		print("Save file does not exist.")
	refreshPuzzles()


func add_puzzle(clue, solution, points):
	var p = puzzle.new()
	p.clue = clue
	p.solution = solution
	p.reward = float(points)
	puzzles.append(p)
	refreshPuzzles()
	save_puzzles()

func delete_puzzle(idx):
	puzzles.remove_at(idx)
	refreshPuzzles()
	save_puzzles()
	
func load_puzzle(idx):
	var p = puzzles[idx]
	main_display.setup(p.clue, p.solution)
	currentReward = p.reward

func _on_add_puzzle_button_pressed():
	var clue = get_node("CanvasLayer/Control/puzzleControls/addPuzzleBox/VBoxContainer/clueEdit").text
	var solution = get_node("CanvasLayer/Control/puzzleControls/addPuzzleBox/VBoxContainer/solutionEdit").text
	var points = get_node("CanvasLayer/Control/puzzleControls/addPuzzleBox/VBoxContainer/pointsEdit").text
	add_puzzle(clue, solution, points)


func _on_delete_puzzle_button_pressed():
	delete_puzzle(puzzleSelector.get_selected_id())


func _on_load_puzzle_button_pressed():
	load_puzzle(puzzleSelector.get_selected_id())


func _on_puzzle_selector_item_selected(index):
	var currentIdx = puzzleSelector.get_selected_id()
	get_node("CanvasLayer/Control/puzzleControls/managePuzzleBox/VBoxContainer/solutionPanel/puzzleSolution").text = puzzles[currentIdx].solution
	get_node("CanvasLayer/Control/puzzleControls/managePuzzleBox/VBoxContainer/pointsPanel/points").text = "$ " + str(puzzles[currentIdx].reward)
