extends VBoxContainer

#2d arrary for storing all letters in the board
var board =[]
#theme that a empty letterbox has
var emptyBoxTheme
#theme that a letter box has without a letter
var letterBoxTheme
#theme that a letterbox has with a correct letter
var correctBoxTheme
#audio player for ding sound effect
var ding_player
#audio player for setting up puzzle
var setup_player
#audio player for solving puzzle
var solve_player
#audio player for incorrect answer
var incorrect_player
#audio player for bankrupt sound
var bankrupt_player

#converts the current puzzle board to displayable text
func boardToText():
	var outputString = ""
	for row in board:
		for col in row:
			if col.value != null:
				outputString += col.value
			else:
				outputString += " "
		outputString += "\n"
	return outputString

#entries for being stored in a puzzle board
class entry:
	#if the entry has been revealed
	var revealed = false
	#correct value for entry
	var value = null
	#reference to label that will display entry
	var label = null
	#panel containing outline for label
	var display = null
	
	#resets the entry to default values
	func reset():
		label.text = ""
		value = null
		revealed = false
	
	#reveals the entry and updates its label
	func reveal():
		label.text = value
		revealed = true

#fills in the board and generates the correct themes
func setupBoard():
	var i = 0
	for child in get_children():
		board.append([])
		for panel in child.get_children():
			if(panel.get_child_count() != 0):
				var newValue = entry.new()
				newValue.label = panel.get_children()[0]
				newValue.display = panel
				board[i].append(newValue)
		i+=1
	letterBoxTheme = board[0][0].display.get_theme_stylebox("panel")
	emptyBoxTheme = letterBoxTheme.duplicate()
	emptyBoxTheme.bg_color = Color(0,.502,0)
	correctBoxTheme = letterBoxTheme.duplicate()
	correctBoxTheme.bg_color = Color(0,.749,1)
	print("Board Setup")

#reveals all unrevealed entries on the board
func revealAll():
	for row in board:
		for col in row:
			if col.revealed == false && col.value != null:
				col.reveal()
				await get_tree().create_timer(.125).timeout
	print("revealing")

#reveals the specified character on the board and returns the number of that character that was on board
func reveal(character):
	var charCount = 0
	for row in board:
		for col in row:
			#checks if the entry has been revealed and if the value matches the specified one
			if col.revealed == false && col.value != null && col.value == character.capitalize():
				col.display.add_theme_stylebox_override("panel", correctBoxTheme)
				ding_player.play()
				await get_tree().create_timer(.4).timeout
				col.reveal()
				col.display.add_theme_stylebox_override("panel", letterBoxTheme)
				await get_tree().create_timer(.7).timeout
				charCount += 1
				
	#If there was no value play the incorrect sound effect
	if charCount == 0:
		incorrect_player.play()
	return charCount

#format the given string to the board by updating entries
#this function tries to display the string on the board in the best possible way using the minimum
#number of lines and trying to center it if only one line
func formatStringToBoard(inputString):
	var words = inputString.split(" ")
	var min_row = min_display_rows(words)
	
	print("Displaying on " + str(min_row) +  " rows.")
	if(min_row == 1):
		var offset_length = null
		var char_length = 0
		var idx = 0
		for word in words:
			if idx >= 1:
				char_length += 1
			char_length += len(word)
			idx += 1
		offset_length = floor((14 - float(char_length)) / 2)
		var charCount = offset_length
		for word in words:
			for c in word:
				board[1][charCount].value = c.capitalize()
				if(c.capitalize() in ",.'!?"):
					board[1][charCount].reveal()
				charCount += 1
			charCount +=1
		format_colors()
		print("1 row setup")
	elif(min_row == 2):
		var charCount = 0
		var rowCount = 1
		for word in words:
			if(len(word) > 14 - charCount):
				rowCount += 1
				charCount = 0
			for c in word:
				board[rowCount][charCount].value = c.capitalize()
				if(c.capitalize() in ",.'!?"):
					board[rowCount][charCount].reveal()
				charCount += 1
			charCount +=1
		format_colors()
		print("2 rows setup")
	elif(min_row in [3,4]):
		var charCount = 0
		var rowCount = 0
		for word in words:
			if(len(word) > 12 - charCount):
				rowCount += 1
				charCount = 0
			for c in word:
				if(rowCount in [0,3]):
					board[rowCount][charCount].value = c.capitalize()
					if(c.capitalize() in ",.'!?"):
						board[rowCount][charCount].reveal()
				else:
					board[rowCount][charCount + 1].value = c.capitalize()
					if(c.capitalize() in ",.'!?"):
						board[rowCount][charCount + 1].reveal()
				charCount += 1
			charCount +=1
		format_colors()
		print(str(min_row)+ " rows setup")
	else:
		format_colors()
		print("Invalid string will not fit on board")
		return

#update the background colors of the entries
func format_colors():
	for row in board:
		for col in row:
			if(col.value == null):
				col.display.add_theme_stylebox_override("panel", emptyBoxTheme)
			else:
				col.display.add_theme_stylebox_override("panel", letterBoxTheme)

#calculates the minimum number of rows needed to display the given words
func min_display_rows(words):
	var word_count = 0
	var total_length = 0
	var largest_word_length = 0
	for word in words:
		if len(word) > largest_word_length:
			largest_word_length = len(word)
		if word_count >= 1:
			total_length += 1
		total_length += len(word)
		word_count += 1
	
	if(largest_word_length > 14):
		return 5
	elif(total_length <= 14):
		return 1
	elif(total_length <= 29 && checkOverflow(words, 2)):
		return 2
	elif(total_length <= 51 && largest_word_length > 12):
		return 5
	elif(total_length <= 38 && checkOverflow(words, 3)):
		return 3
	elif(total_length <= 51 && checkOverflow(words, 4)):
		return 4
	else:
		return 5

#check if displaying the given words will generate overflow
func checkOverflow(words, num_lines):
	var max_line_length
	if(num_lines == 2):
		max_line_length = 14
	elif num_lines in [3,4]:
		max_line_length = 12
	else:
		return false
	var current_line_length = 0
	var line_count = 1
	
	for word in words:
		var new_line_length
		if current_line_length >0:
			new_line_length = current_line_length + 1 + len(word)
		else:
			new_line_length = len(word)
		if new_line_length > max_line_length:
			line_count += 1
			current_line_length = len(word)
		else:
			current_line_length = new_line_length
		if line_count > num_lines:
			print("Overflow detected")
			return false
	print("Not overflow found")
	return true

#resets all entries in the board
func resetBoard():
	for row in board:
		for col in row:
			col.reset()
	print("resetting")

#sets up all the audio players for playing
func setupAudio():
	ding_player = AudioStreamPlayer.new()
	ding_player.stream = preload("res://sounds/Ding.mp3")
	add_child(ding_player)
	solve_player = AudioStreamPlayer.new()
	solve_player.stream = preload("res://sounds/Solve.mp3")
	add_child(solve_player)
	setup_player = AudioStreamPlayer.new()
	setup_player.stream = preload("res://sounds/PuzzleSetup.mp3")
	add_child(setup_player)
	bankrupt_player = AudioStreamPlayer.new()
	bankrupt_player.stream = preload("res://sounds/Bankrupt.mp3")
	add_child(bankrupt_player)
	incorrect_player = AudioStreamPlayer.new()
	incorrect_player.stream = preload("res://sounds/Incorrect.mp3")
	add_child(incorrect_player)

#on first load set up board and audio players
func _ready():
	setupBoard()
	setupAudio()
