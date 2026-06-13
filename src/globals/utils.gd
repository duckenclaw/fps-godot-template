class_name Utils
extends RefCounted
## Grab-bag of small, genre-agnostic static helpers used across the template.
## Call statically, e.g. Utils.remap_range(v, 0, 100, 0, 1).

## Remap a value from one range to another (no clamping).
static func remap_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	if is_equal_approx(in_max, in_min):
		return out_min
	return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)

## Same as remap_range but clamped to the output range.
static func remap_clamped(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return clampf(remap_range(value, in_min, in_max, out_min, out_max), minf(out_min, out_max), maxf(out_min, out_max))

## Pick a random index given an array of relative weights. Returns -1 if empty.
static func weighted_pick(weights: Array) -> int:
	var total: float = 0.0
	for w in weights:
		total += maxf(0.0, float(w))
	if total <= 0.0:
		return -1
	var roll := randf() * total
	var acc := 0.0
	for i in weights.size():
		acc += maxf(0.0, float(weights[i]))
		if roll <= acc:
			return i
	return weights.size() - 1

## Pick a random element from an array (null/empty-safe).
static func random_element(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()]

## Frame-rate independent lerp factor for exponential smoothing.
## Use as: value = lerp(value, target, Utils.damp(speed, delta)).
static func damp(speed: float, delta: float) -> float:
	return 1.0 - exp(-speed * delta)

## Format seconds as M:SS (handy for timers / playtime displays).
static func format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%d:%02d" % [total / 60, total % 60]
