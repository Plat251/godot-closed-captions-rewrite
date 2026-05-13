extends Node

## Determines the minimum volume required for sound sources to display captions. Is used in 2D and 3D with distance and attunement.
@export var audibility_cutoff: float = 0.2
## Sets the maximum amount of time a caption will linger for.
@export var max_linger_duration: float = 5.0
var active_paybacks: Array[CaptionedPlayback]
var caption_displays: Array[CaptionDisplay]

func push_caption(source: CaptionedAudioStreamPlayer, caption: Caption) -> Caption:
	print("meep")
	if _assure_audibility(source, source.bus):
		var outputs:Array[CaptionDisplay]
		for display in caption_displays:
			if display.is_receiving_bus(source.bus): outputs.append(display)
		outputs.sort_custom(func(a:CaptionDisplay, b:CaptionDisplay) -> bool: return a.priority > b.priority)
		outputs[0].display_caption(caption)
		return caption
	return null

func push_caption_2d(source: CaptionedAudioStreamPlayer2D, caption: Caption) -> Caption:
	if _assure_audibility(source, source.bus):
		var audio_listener: Node2D = source.get_viewport().get_audio_listener_2d()
		if audio_listener == null:
			source.get_viewport().get_camera_2d()
		if audio_listener == null: return null
		var direction: Vector2 = audio_listener.to_local(source.global_position)
		var distance: float = source.position.distance_to(audio_listener.position)
		if source.volume_linear * (distance ** source.attenuation) > audibility_cutoff and distance < source.max_distance:
			var outputs:Array[CaptionDisplay]
			for display in caption_displays:
				if display.is_receiving_bus(source.bus): outputs.append(display)
			outputs.sort_custom(func(a:CaptionDisplay, b:CaptionDisplay) -> bool: return a.priority > b.priority)
			outputs[0].display_caption(caption, _resolve_position(direction, source.get_viewport_rect()))
			return caption
	return null

func _resolve_position(direction: Vector2, screen_rect) -> CaptionLabel.Positions:
	if direction.length() < (screen_rect.size.length() / 3.0):
		return CaptionLabel.Positions.CENTER
	var angle_to := fmod(direction.angle_to(Vector2.UP) / PI + .125, 2.0)
	if angle_to > .25: return CaptionLabel.Positions.TOP
	elif angle_to > 0.5: return CaptionLabel.Positions.TOP_LEFT
	elif angle_to > 0.75: return CaptionLabel.Positions.LEFT
	elif angle_to > 1.0: return CaptionLabel.Positions.BOTTOM_LEFT
	elif angle_to > 1.25: return CaptionLabel.Positions.BOTTOM
	elif angle_to > 1.5: return CaptionLabel.Positions.BOTTOM_RIGHT
	elif angle_to > 1.75: return CaptionLabel.Positions.RIGHT
	return CaptionLabel.Positions.TOP_RIGHT

func push_caption_3d(source: CaptionedAudioStreamPlayer3D, caption: Caption) -> Caption:
	if _assure_audibility(source, source.bus):
		var audio_listener: Node3D = source.get_viewport().get_audio_listener_3d()
		if audio_listener == null:
			source.get_viewport().get_camera_3d()
		if audio_listener == null: return null
		var direction: Vector3 = audio_listener.to_local(source.global_position)
		var distance: float = source.position.distance_to(audio_listener.position)
		if source.volume_linear * (distance ** source.attenuation) > audibility_cutoff and distance < source.max_distance:
			var outputs:Array[CaptionDisplay]
			for display in caption_displays:
				if display.is_receiving_bus(source.bus): outputs.append(display)
			outputs.sort_custom(func(a:CaptionDisplay, b:CaptionDisplay) -> bool: return a.priority > b.priority)
			if direction.angle_to(Vector3.BACK) > 1:
				outputs[0].display_caption(caption, _resolve_position(Vector2(direction.x, direction.z), source.get_viewport_rect()))
			else:
				outputs[0].display_caption(caption, CaptionLabel.Positions.BEHIND)
			return caption
	return null

enum Positions {
	TOP,
	LEFT,
	TOP_LEFT,
	BOTTOM_LEFT,
	CENTER,
	RIGHT,
	TOP_RIGHT,
	BOTTOM_RIGHT,
	BOTTOM,
	BEHIND,
	## used, because override_position can't be null.
	UNSET
}


func _assure_audibility(source: Node, bus: StringName):
	return is_listening(source.get_viewport()) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(source.bus)) 


func pull_caption(caption: Caption): for display in caption_displays: display.pull_caption(caption)

func is_listening(listener: Viewport):
	if listener == null or not (listener.audio_listener_enable_2d or listener.audio_listener_enable_3d):
		return false
	if listener.get_viewport() == get_tree().root:
		return true
	else:
		return is_listening(listener.get_viewport())
	

func signup_display(new: CaptionDisplay):
	if not caption_displays.has(new):
		caption_displays.append(new)
	
func signoff_display(old: CaptionDisplay):
	caption_displays.erase(old)

func start_playback(stream: CaptionedPlayback):
	active_paybacks.append(stream)

func stop_playback(stream: CaptionedPlayback):
	active_paybacks.erase(stream)

func _process(_delta: float) -> void:
	for playback in active_paybacks:
		var new_active: Caption = playback.get_active_caption()
		if playback._active_caption != new_active:
			if playback._active_caption != null:
				pull_caption(playback._active_caption)
			if new_active != null:
				if playback._active_caption:
					if playback._active_caption.duration == 0:
						new_active.previous = playback._active_caption
				match playback.source_type:
					CaptionedPlayback.type.PLAYER_OMNI:
						playback._active_caption = push_caption(playback.stream_source, new_active)
					CaptionedPlayback.type.PLAYER_2D:
						playback._active_caption = push_caption_2d(playback.stream_source_2d, new_active)
					CaptionedPlayback.type.PLAYER_3D:
						playback._active_caption = push_caption_3d(playback.stream_source_3d, new_active)
			
