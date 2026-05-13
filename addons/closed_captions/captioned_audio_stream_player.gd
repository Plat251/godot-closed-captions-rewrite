@tool
extends AudioStreamPlayer
class_name CaptionedAudioStreamPlayer

signal new_caption_started(caption: Caption)

@export var captioned_stream:CaptionedAudioStream:
	set(sub_stream):
		if not sub_stream == null:
			stream = sub_stream.audio_stream
			sub_stream.audio_stream_replaced.connect(_on_stream_changed)
		else:
			stream == null
		captioned_stream = sub_stream

## forces the first occurance of a name occuring in the stream to always show.
@export var force_display_names: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name == "stream":
		property.usage |= PROPERTY_USAGE_READ_ONLY
	

func _set(property: StringName, value: Variant) -> bool:
	if property == "stream":
		if value != null and not captioned_stream.audio_stream == value:
			captioned_stream.audio_stream = value
			return true
	if property == "playing":
		print("set playing!!!")
		if value and not playing:
			self.play()
			self.playing = true
		elif not value and playing:
			self.stop()
			self.playing = false
	return false

func _ready():
	if autoplay and not Engine.is_editor_hint():
		_play()
	
	new_caption_started.connect(CaptionServer.push_caption)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings:PackedStringArray = []
	if captioned_stream == null: return warnings
	if captioned_stream.audio_stream != stream: warnings.append("Set Stream in \"Captioned Stream\", not in AudioPlayer.")
	var caption_warnings:int = captioned_stream.get_caption_warnings()
	if bool(caption_warnings & 2**CaptionedAudioStream.ConfigurationWarnings.MISSING): warnings.append("No captions have been set up yet.")
	if bool(caption_warnings & 2**CaptionedAudioStream.ConfigurationWarnings.EMPTY): warnings.append("Some Captions are empty.")
	if bool(caption_warnings & 2**CaptionedAudioStream.ConfigurationWarnings.TOO_LONG): warnings.append("Some captions are too longer, than 15 words.")
	if bool(caption_warnings & 2**CaptionedAudioStream.ConfigurationWarnings.MISSING_SPEAKER): warnings.append("Some captions have spoken text formatting but no spaker name.")
	return warnings

func play(from_position: float = 0.0):
	super.play(from_position)
	self._play(from_position)
	print("called!!!")

func stop():
	super.stop()
	self._stop()

var _captioned_playback: CaptionedPlayback = null
func _play(from_position: float = 0.0):
	if captioned_stream == null:
		push_warning("CaptionedAudioStream of player %s is playing but missing Captions." % name)
		return

	_captioned_playback = CaptionedPlayback.new(self, captioned_stream, get_stream_playback())
	CaptionServer.start_playback(_captioned_playback)
	

func _stop():
	CaptionServer.stop_playback(_captioned_playback)
	_captioned_playback = null

func _on_stream_changed(new_stream: AudioStream):
	stream = new_stream

func _notification(what: int) -> void:
	if what == Node.NOTIFICATION_EDITOR_POST_SAVE:
		PluginReference.save_cast()
