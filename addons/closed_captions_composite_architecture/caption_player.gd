@tool
@icon("res://addons/closed_captions_composite_architecture/icons/CaptionedAudioStreamPlayer.svg")
extends Node
class_name CaptionPlayer


@export var audio_stream_player: Node
@export var caption_label: Node
@export var captioned_audio_stream: CaptionedAudioStream

var current_caption_index := 0

var current_caption_duration_timer: Timer
var next_caption_delay_timer: Timer


func _ready():
	_create_timers()


func _process(_delta):
	if Engine.is_editor_hint():
		update_configuration_warnings()


func play():
	audio_stream_player.set_stream(captioned_audio_stream.audio_stream)
	audio_stream_player.play()
	
	show_next_caption()


func show_next_caption():
	show_caption_at_index(current_caption_index)
	if current_caption_index + 1 < captioned_audio_stream.captions.size():
		next_caption_delay_timer.start(
			captioned_audio_stream.captions[current_caption_index + 1].delay
			- captioned_audio_stream.captions[current_caption_index].delay)
		current_caption_index += 1


func show_caption_at_index(index: int):
	var caption: Caption = captioned_audio_stream.captions[index]
	current_caption_duration_timer.stop()
	caption_label.visible = true
	caption_label.set_text(caption.text)
	if not is_zero_approx(caption.duration):
		print("last caption, timer started")
		current_caption_duration_timer.start(caption.duration)


func hide_caption():
	caption_label.visible = false
	caption_label.set_text("")


func _create_timers():
	if !Engine.is_editor_hint():
		current_caption_duration_timer = Timer.new()
		current_caption_duration_timer.one_shot = true
		self.add_child(current_caption_duration_timer)
		current_caption_duration_timer.timeout.connect(hide_caption)
		
		next_caption_delay_timer = Timer.new()
		next_caption_delay_timer.one_shot = true
		self.add_child(next_caption_delay_timer)
		next_caption_delay_timer.timeout.connect(show_next_caption)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if audio_stream_player == null:
		warnings.append("No node to play audio is set!")
	if caption_label == null:
		warnings.append("No node to display captions is set!")
	
	return warnings
