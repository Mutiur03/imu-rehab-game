
extends Node2D

# Game objects
@onready var player = $Player
@onready var target = $Target
@onready var start_marker = $StartMarker
@onready var start_marker_ring = $StartMarker/Ring

# Interface
@onready var score_label = $ScoreLabel
@onready var timer_label = $TimerLabel
@onready var message_label = $MessageLabel
@onready var summary_label = $SummaryLabel
@onready var continue_button = $ContinueButton


# Game configuration
const REQUIRED_REPS: int = 3
const START_POSITION: Vector2 = Vector2(150, 300)
const TARGET_RADIUS: float = 35.0


# Game state
enum GameState {
	PLAYING,
	LEVEL_SUMMARY,
	FINISHED
}

var game_state: GameState = GameState.PLAYING

var current_level: int = 1
var repetitions: int = 0

var reached_target: bool = false
var movement_started: bool = false


# Timing
var start_time: float = 0.0
var outward_time: float = 0.0
var elapsed_time: float = 0.0


# Session records
var repetition_data: Array[Dictionary] = []


func _ready() -> void:

	player.position = START_POSITION
	start_marker.hide()

	continue_button.hide()
	summary_label.hide()

	continue_button.pressed.connect(
		_on_continue_button_pressed
	)

	update_display()


func _process(_delta: float) -> void:

	# Do not process movement after a level ends.
	if game_state != GameState.PLAYING:
		return

	# Start timing when movement begins.
	if not movement_started:

		if player.position.distance_to(
			START_POSITION
		) > 5.0:

			movement_started = true

			start_time = (
				Time.get_ticks_msec() / 1000.0
			)

	# Update timer continuously.
	if movement_started:

		elapsed_time = get_elapsed_time()

		timer_label.text = (
			"Elapsed Time: %.2f s" % elapsed_time
		)

	# Level 1: One-way reaching
	if current_level == 1:

		if movement_started:

			if player.position.distance_to(
				target.position
			) <= TARGET_RADIUS:

				outward_time = get_elapsed_time()

				complete_repetition()

	# Level 2: Reach and return
	elif current_level == 2:

		if not reached_target:

			if movement_started:

				if player.position.distance_to(
					target.position
				) <= TARGET_RADIUS:

					outward_time = get_elapsed_time()

					reached_target = true

					start_marker_ring.modulate = Color.WHITE
					target.modulate = Color(1.0, 1.0, 1.0, 0.35)

					message_label.text = (
						"Target reached! Return to the blue START circle."
					)

		else:

			if player.position.distance_to(
				START_POSITION
			) <= TARGET_RADIUS:

				complete_repetition()


func get_elapsed_time() -> float:

	return (
		Time.get_ticks_msec() / 1000.0
	) - start_time


func complete_repetition() -> void:

	var total_time: float = get_elapsed_time()

	var return_time: float = 0.0

	if current_level == 2:
		return_time = total_time - outward_time

	repetitions += 1

	# Save repetition data.
	var record: Dictionary = {
		"level": current_level,
		"repetition": repetitions,
		"outward_time": outward_time,
		"return_time": return_time,
		"total_time": total_time
	}

	repetition_data.append(record)

	print("Repetition completed: ", record)

	# Stop the timer for this repetition.
	movement_started = false
	reached_target = false

	if current_level == 2:
		show_outward_cues()

	timer_label.text = (
		"Last Repetition: %.2f s" % total_time
	)

	# Check if the level is complete.
	if repetitions >= REQUIRED_REPS:

		finish_level()

	else:

		player.position = START_POSITION

		outward_time = 0.0
		elapsed_time = 0.0

		update_display()


func finish_level() -> void:

	# Stop the player and movement processing.
	player.movement_enabled = false
	player.hide()
	target.hide()
	start_marker.hide()
	target.modulate = Color.WHITE

	game_state = GameState.LEVEL_SUMMARY

	show_level_summary()

	if current_level == 1:

		message_label.text = (
            "Level 1 Completed!"
		)

		continue_button.show()

	else:

		finish_game()


func show_level_summary() -> void:

	var summary: String = (
		"LEVEL %d SUMMARY\n\n" % current_level
	)

	var total_level_time: float = 0.0
	var level_rep_count: int = 0

	for record in repetition_data:

		if record["level"] == current_level:

			level_rep_count += 1

			var rep_time: float = (
				record["total_time"]
			)

			total_level_time += rep_time

			summary += (
                "Repetition %d: %.2f s\n"
				% [
					record["repetition"],
					rep_time
				]
			)

	var average_time: float = 0.0

	if level_rep_count > 0:

		average_time = (
			total_level_time / level_rep_count
		)

	summary += (
        "\nTotal Time: %.2f s\n"
		% total_level_time
	)

	summary += (
        "Average Time: %.2f s"
		% average_time
	)

	summary_label.text = summary

	summary_label.show()

	print(summary)


func _on_continue_button_pressed() -> void:

	# Only allow progression from Level 1.
	if current_level != 1:
		return

	if game_state != GameState.LEVEL_SUMMARY:
		return

	current_level = 2
	repetitions = 0

	movement_started = false
	reached_target = false

	outward_time = 0.0
	elapsed_time = 0.0

	player.position = START_POSITION

	player.show()
	target.show()
	player.movement_enabled = true

	summary_label.hide()
	continue_button.hide()

	game_state = GameState.PLAYING

	timer_label.text = "Elapsed Time: 0.00 s"
	show_outward_cues()

	update_display()


func finish_game() -> void:

	game_state = GameState.FINISHED

	player.movement_enabled = false

	continue_button.hide()

	message_label.text = (
        "SUCCESS! ALL LEVELS COMPLETED!"
	)

	score_label.text = (
        "Game Completed: 2/2 Levels"
	)

	print("GAME COMPLETED SUCCESSFULLY!")

	# No additional repetitions are allowed.


func update_display() -> void:

	score_label.text = (
        "Level: %d | Repetitions: %d/%d"
		% [
			current_level,
			repetitions,
			REQUIRED_REPS
		]
	)

	if current_level == 1:

		message_label.text = (
            "Reach the target"
		)

	else:

		message_label.text = (
			"Move to the green target, then return to START."
		)


func show_outward_cues() -> void:

	# Keep the home position visible without competing with the current target.
	start_marker.show()
	start_marker.modulate = Color.WHITE
	start_marker_ring.modulate = Color(1.0, 1.0, 1.0, 0.60)
	target.modulate = Color.WHITE
