class_name CaptionedPlayback extends Object

enum type {
	PLAYER_OMNI,
	PLAYER_2D,
	PLAYER_3D
}

var captioned_stream: CaptionedAudioStream
var audio_stream_playback: AudioStreamPlayback
var stream_source: CaptionedAudioStreamPlayer
var stream_source_2D: CaptionedAudioStreamPlayer2D
var stream_source_3D: CaptionedAudioStreamPlayer3D
var source_type: type
var _active_caption: Caption = null

func _init(player: Node, captioned_stream: CaptionedAudioStream, audio_stream_playback: AudioStreamPlayback) -> void:
	if player is CaptionedAudioStreamPlayer:
		stream_source = player
		source_type = type.PLAYER_OMNI
	elif player is CaptionedAudioStreamPlayer2D:
		stream_source_2D = player
		source_type = type.PLAYER_OMNI
	elif player is CaptionedAudioStreamPlayer3D:
		stream_source_3D = player
		source_type = type.PLAYER_OMNI
	else: push_error("captionplayback: player must be a [CaptionedAudioStreamPlayer] or one of its sibilings.")
	self.captioned_stream = captioned_stream
	self.audio_stream_playback = audio_stream_playback
	
func get_active_caption() -> Caption:
	return captioned_stream.get_displaying_caption(stream_source.get_playback_position())
