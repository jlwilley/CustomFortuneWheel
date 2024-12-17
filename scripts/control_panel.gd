extends Node2D

#reference to the parent main display
var main_display
#the puzzles loaded from file
var puzzles
#the reward for the current puzzle
var currentReward = 0
# Filepath for saving puzzles
const save_path = "user://puzzles.json"
#file path for loading vieos
const video_folder = "user://videos/"
#the required video format
const SUPPORTED_FORMATS = ["ogv"]
#reference to the puzzle selector option box
@onready var puzzleSelector = get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/managePuzzleBox/VBoxContainer/puzzleSelector")
#valid vowels
const vowels = "aeiou"
#valid consonants
const consonants = "bcdfghjklmnpqrstvwxyz"
#the cost to buy a vowel
const vowelCost = 250
#reference to the option for the currently selected team
@onready var teamBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/teamOption")
#reference to the different possible wheel tiles
var wheelTiles = [300,350,400,450,500,550,600,650,700,750,800,850,900,950,1000,2500]
#reference to the currently spun wheel tile
var wheelOption
#if the board is currently revealing letters
var isRevealing = false
#if the display is currently showing bank values
var isShowingBank = false
#if the happy song is playing
var isPlayingHappy = false
#if the thinking song is playing
var isPlayingThinking = false
#reference to the option box that displays videos
@onready var videoOption = get_node("CanvasLayer/Control/Panel/VBoxContainer/videoOptionRow/videoOption")
#audio player for thinking song
@onready var thinking_song_player = AudioStreamPlayer.new()
@onready var tension_song_player = AudioStreamPlayer.new()
@onready var happy_song_player = AudioStreamPlayer.new()
@onready var playHappyButton = get_node("CanvasLayer/Control/Panel/VBoxContainer/musicButtons/playHappy")
@onready var playThinkingButton = get_node("CanvasLayer/Control/Panel/VBoxContainer/musicButtons/playThinking")
#class that contains puzzles
#puzzles have a clue, solution, and reward
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
func from_dict(data: Dictionary) -> puzzle:
	var instance = puzzle.new()
	instance.clue = data.get("clue", "")
	instance.solution = data.get("solution", "")
	instance.reward = data.get("reward", 0)
	return instance

#when program is quitting save
func _on_about_to_quit():
	print("Exit Called Saving")
	save_puzzles()


func setup_audio():
	thinking_song_player.stream = preload("res://music/thinkingSong.wav")
	add_child(thinking_song_player)
	thinking_song_player.finished.connect(_on_thinking_finished)
	happy_song_player.stream = preload("res://music/happySong.wav")
	add_child(happy_song_player)
	tension_song_player.stream = preload("res://music/tensionSong.wav")
	add_child(tension_song_player)

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_audio()
	#setup randomizer
	randomize()
	#initalize variables
	puzzles = []
	currentReward = 0
	#load puzzles from file
	load_puzzles()
	#set team 1 as first player
	main_display.selectTeam(1)
	#add all wheel options to the button
	wheelOption = get_node("CanvasLayer/Control/Panel/VBoxContainer/consonantContainer/WheelOption")
	for value in wheelTiles:
		wheelOption.add_item(str(value))
	#ensure folder for loading videos exist
	create_video_folder()
	#load all videos
	load_videos()

#handle presses alt enter for changing to full screen
func _input(_event):
	var control_window = get_viewport().get_window()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		print("toggling fullscreen")
		if control_window.mode == Window.MODE_WINDOWED:
			control_window.mode = Window.MODE_FULLSCREEN
		else:
			control_window.mode = Window.MODE_WINDOWED 

#setup reference to main display
func setup(mainDisplay):
	main_display = mainDisplay

#refresh displayed scores on control panel
func refresh():
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry9/currentTeamPoints").text = str(main_display.team1Score)
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry13/currentTeamBank").text = str(main_display.team1Bank)
	get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry9/currentTeamPoints").text = str(main_display.team2Score)
	get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry13/currentTeamBank").text = str(main_display.team2Bank)
	get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry9/currentTeamPoints").text = str(main_display.team3Score)
	get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry13/currentTeamBank").text = str(main_display.team3Bank)

#refresh puzzles loaded
func refreshPuzzles():
	puzzleSelector.clear()
	for item in puzzles:
		puzzleSelector.add_item(item.solution)
	if puzzles.size() >= 1:
		_on_puzzle_selector_item_selected(0)

#convert all puzzles in array to json format and then save to file
func save_puzzles():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		# Convert each puzzle in the array to a dictionary
		var serialized_array = []
		for p in puzzles:
			serialized_array.append(p.to_dict())
		var json_data = JSON.stringify(serialized_array)  # Serialize the array of dictionaries
		file.store_string(json_data)
		file.close()
		print("Array saved successfully!")
	else:
		print("Failed to save the file.")

#load puzzles from json file and convert to puzzles object and add to array
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
	

#setup the vowels and consonants in the control boxes for adding and removing later
func setup_letters():
	var vowelBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/vowelContainer/vowelOption")
	var consonantBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/consonantContainer/ConsonantOption")
	vowelBox.clear()
	consonantBox.clear()
	for v in vowels:
		vowelBox.add_item(v)
	for c in consonants:
		consonantBox.add_item(c)

#create a new puzzle with specified info
func add_puzzle(clue, solution, points):
	var p = puzzle.new()
	p.clue = clue
	p.solution = solution
	p.reward = float(points)
	puzzles.append(p)
	refreshPuzzles()
	save_puzzles()

#delete puzzle at specified index
func delete_puzzle(idx):
	puzzles.remove_at(idx)
	refreshPuzzles()
	save_puzzles()


#load puzzle from specified index
func load_puzzle(idx):
	if(idx != -1):
			var p = puzzles[idx]
			main_display.setup(p.clue, p.solution)
			currentReward = p.reward
			setup_letters()
	else:
		print("cannot load puzzle")

#create a video folder in the user folder if it does not exist
func create_video_folder():
	var dir = DirAccess.open(video_folder)
	if dir == null:
		# Use a new DirAccess instance to create the directory
		var dir_creator = DirAccess.open("user://")
		if dir_creator and dir_creator.make_dir_recursive("videos") != OK:
			print("Failed to create video folder:", video_folder)
		else:
			print("Video folder created:", video_folder)

#load all possible videos from the video folder
func load_videos():
	var dir = DirAccess.open(video_folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and is_supported_format(file_name):
				# Add video file to OptionButton
				var file_path = video_folder + file_name
				videoOption.add_item(file_name)
				videoOption.set_item_metadata(videoOption.get_item_count() - 1, file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open video folder:", video_folder)

#checks if the video is of a proper format
func is_supported_format(file_name: String) -> bool:
	# Check if the file has a supported extension
	var extension = file_name.get_extension().to_lower()
	return extension in SUPPORTED_FORMATS

#when add puzzle button is pressed add puzzle
func _on_add_puzzle_button_pressed():
	var clue = get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/addPuzzleBox/VBoxContainer/clueEdit").text
	var solution = get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/addPuzzleBox/VBoxContainer/solutionEdit").text
	var points = get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/addPuzzleBox/VBoxContainer/pointsEdit").text
	add_puzzle(clue, solution, points)

#when delete puzzle button is pressed delete selected puzzle
func _on_delete_puzzle_button_pressed():
	delete_puzzle(puzzleSelector.get_selected_id())

#when load puzzle button is pressed load selected puzzle
func _on_load_puzzle_button_pressed():
	load_puzzle(puzzleSelector.get_selected_id())

#when changing selected puzzle update all relevant fields
func _on_puzzle_selector_item_selected(_index):
	var currentIdx = puzzleSelector.get_selected_id()
	get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/managePuzzleBox/VBoxContainer/solutionPanel/puzzleSolution").text = puzzles[currentIdx].clue
	get_node("CanvasLayer/Control/puzzleControls/VBoxContainer/managePuzzleBox/VBoxContainer/pointsPanel/points").text = "$ " + str(puzzles[currentIdx].reward)

#checks if selected team can buy a vowel if they can reveal it
func _on_buy_vowel_button_pressed():
	var vowelBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/vowelContainer/vowelOption")
	if main_display.getScore(teamBox.get_selected_id()) >= vowelCost:
		main_display.reveal(vowelBox.get_item_text(vowelBox.selected), true)
		vowelBox.remove_item(vowelBox.selected)
		main_display.addPoints(teamBox.get_selected_id(), -250)
	else:
		print("Cannot Purchase Vowel")

#reveal vowel that is selected
func _on_free_play_button_pressed():
	var vowelBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/vowelContainer/vowelOption")
	main_display.reveal(vowelBox.get_item_text(vowelBox.selected),true)
	vowelBox.remove_item(vowelBox.selected) 

#updates team 1 name
func _on_team_1_update_name_pressed():
	var textBoxNode = get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry6/teamTextBox")
	get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry5/currentTeamName").text = textBoxNode.text
	main_display.updateTeamName(1, textBoxNode.text)
	teamBox.set_item_text(0, textBoxNode.text)
	textBoxNode.text = "Team 1"

#updates team 2 name
func _on_team_2_update_name_button_pressed():
	var textBoxNode = get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry6/teamTextBox")
	get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry5/currentTeamName").text = textBoxNode.text
	main_display.updateTeamName(2, textBoxNode.text)
	teamBox.set_item_text(1, textBoxNode.text)
	textBoxNode.text = "Team 2" # Replace with function body.

#updates team 3 name
func _on_team_3_update_name_button_pressed():
	var textBoxNode = get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry6/teamTextBox")
	get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry5/currentTeamName").text = textBoxNode.text
	main_display.updateTeamName(3, textBoxNode.text)
	teamBox.set_item_text(2, textBoxNode.text)
	textBoxNode.text = "Team 3" # Replace with function body.

#updates team 1 points
func _on_team_1_update_points_pressed():
	main_display.updatePoints(1, float(get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry10/teamPointsBox").text))

#updates team 2 points
func _on_team_2_update_points_pressed():
	main_display.updatePoints(2, float(get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry10/teamPointsBox").text))

#updates team 3 points
func _on_team_3_update_points_pressed():
	main_display.updatePoints(3, float(get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry10/teamPointsBox").text))

#updates team 1 bank
func _on_team_1_update_bank_pressed():
	main_display.updateBank(1, float(get_node("CanvasLayer/Control/VBoxContainer/team1Panel/GridContainer/gridEntry14/teamBankBox").text))

#updates team 2 bank
func _on_team_2_update_bank_pressed():
	main_display.updateBank(2, float(get_node("CanvasLayer/Control/VBoxContainer/team2Panel/GridContainer/gridEntry14/teamBankBox").text))

#updates team 3 bank
func _on_team_3_update_bank_pressed():
	main_display.updateBank(3, float(get_node("CanvasLayer/Control/VBoxContainer/team3Panel/GridContainer/gridEntry14/teamBankBox").text))

#updates display to reflect newly selected team
func _on_team_option_item_selected(_index):
	main_display.selectTeam(teamBox.get_selected_id())

#moves to the next teams turn
func next_team():
	if teamBox.selected == 2:
		teamBox.select(0)
	else:
		teamBox.select(teamBox.selected +1 )
	main_display.selectTeam(teamBox.get_selected_id())

#skips selected teams turn
func _on_skip_turn_button_pressed():
	main_display.puzzleBoard.bankrupt_player.play()
	next_team()

#bankrupts selected team
func _on_bankrupt_button_pressed():
	main_display.bankrupt(teamBox.get_selected_id())
	next_team()

#adds points to the selected team
func addPoints(points):
	main_display.addPoints(teamBox.get_selected_id(), points)

#solves the puzzle and rewards selected team
func _on_solve_button_pressed():
	main_display.solve()
	addPoints(currentReward)
	next_team()


#reveals consonants and calculates how many points it was worth for selected team
func _on_reveal_consonant_pressed():
	var consonantBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/consonantContainer/ConsonantOption")
	var letter_count = await main_display.reveal(consonantBox.get_item_text(consonantBox.selected),true)
	if(letter_count == 0):
		next_team()
	else:
		addPoints(letter_count * float(wheelOption.get_item_text(wheelOption.selected)))
	consonantBox.remove_item(consonantBox.selected)

#toggles between slowly revealing letters and not
func _on_slow_reveal_pressed():
	var slowRevealButton = get_node("CanvasLayer/Control/Panel/VBoxContainer/toggleButtons/slowReveal")
	if isRevealing:
		tension_song_player.stop()
		isRevealing = false
		slowRevealButton.text = "Slow Reveal"
	else:
		isPlayingThinking = false
		playThinkingButton.text = "Play Thinking"
		thinking_song_player.stop()
		isPlayingHappy = false
		playHappyButton.text = "Play Happy"
		happy_song_player.stop()
		tension_song_player.play()
		isRevealing = true
		slowRevealButton.text = "Stop Revealing"
		slowReveal()

#slow reveal loop that reveals random remaining letter
func slowReveal():
	var consonantBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/consonantContainer/ConsonantOption")
	var vowelBox = get_node("CanvasLayer/Control/Panel/VBoxContainer/vowelContainer/vowelOption")
	while isRevealing:
		var consonantCount = consonantBox.get_item_count()
		var vowelCount = vowelBox.get_item_count()
		var totalCount = vowelCount + consonantCount
		if totalCount == 0:
			print("nothing to reveal")
			return
		var random_index = randi() % totalCount
		if random_index < consonantCount:
			await main_display.reveal(consonantBox.get_item_text(random_index),false)
			consonantBox.remove_item(random_index)
		else:
			var adjustedIndex = random_index - consonantCount
			await main_display.reveal(vowelBox.get_item_text(adjustedIndex),false)
			vowelBox.remove_item(adjustedIndex)
		await get_tree().create_timer(.75).timeout

#toggles between showing and hiding bank
func _on_toggle_bank_pressed():
	var toggleBankButton = get_node("CanvasLayer/Control/Panel/VBoxContainer/toggleButtons/toggleBank")
	if isShowingBank:
		isShowingBank = false
		toggleBankButton.text = "Show Bank"
		main_display.hideBank()
	else:
		isShowingBank = true
		toggleBankButton.text = "Hide Bank"
		main_display.showBank()

#plays selected video
func _on_play_video_pressed():
	var video_path = videoOption.get_item_metadata(videoOption.selected)
	if video_path != null and video_path != "":
		main_display.videoPlayer.stream = load(video_path)
		main_display.videoPlayer.play()

#stops selected video
func _on_stop_video_pressed():
	if(main_display.videoPlayer.is_playing()):
		main_display.videoPlayer.stop()

#opens video folder
func _on_open_folder_pressed():
	var absolute_path = ProjectSettings.globalize_path(video_folder)
	OS.shell_open(absolute_path)

#happy song player
func _on_play_happy_pressed():
	if isPlayingHappy:

		isPlayingHappy = false
		playHappyButton.text = "Play Happy"
		happy_song_player.stop()
	else:
		isPlayingThinking = false
		playThinkingButton.text = "Play Thinking"
		thinking_song_player.stop()
		isPlayingHappy = true
		playHappyButton.text = "Stop Happy"
		happy_song_player.play()

#if thinking player finished on its own update button
func _on_thinking_finished():
	isPlayingThinking = false
	playThinkingButton.text = "Play Thinking"

func _on_play_thinking_pressed():
	if isPlayingThinking:
		isPlayingThinking = false
		playThinkingButton.text = "Play Thinking"
		thinking_song_player.stop()
	else:
		isPlayingHappy = false
		playHappyButton.text = "Play Happy"
		happy_song_player.stop()
		isPlayingThinking = true
		playThinkingButton.text = "Stop Thinking"
		thinking_song_player.play()

#setups bonus round with player letters
func _on_setup_bonus_pressed():
	var newLetters = get_node("CanvasLayer/Control/Panel/VBoxContainer/finalPuzzleButton/LineEdit").text
	for c in newLetters:
		await get_tree().create_timer(.6).timeout
		await main_display.reveal(c, true)

#sets up bonus round with rstlne
func _on_rstlne_button_pressed():
	var newLetters = "rstlne"
	for c in newLetters:
		await get_tree().create_timer(.6).timeout
		await main_display.reveal(c, true)
