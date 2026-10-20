class_name RadioSpeech
extends RefCounted
## Assemble dynamic radio data from the same bundled voice as the full reports.
## Missing proper names are spelled, never silently omitted.

static var _numbers := RegEx.create_from_string("-?[0-9]+(?:\\.[0-9]+)?")
static var _fix := RegEx.create_from_string("([0-9])([nsewNSEW])\\b")
const SMALL := ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const TENS := ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
const UNITS := {"brg": "bearing", "hdg": "heading", "km": "kilometres", "min": "minutes", "s": "seconds",
	"c": "degrees"}


## A queue entry is [recording, sentence ends here]. Full recorded phrases win.
static func plan(text: String, phrase: Callable) -> Array[Array]:
	var out: Array[Array] = []
	var words := normalize(text)
	for sentence in words.replace("!", ".").replace("?", ".").replace(";", ".").split(".", false):
		var tokens := PackedStringArray()
		for token in sentence.replace(",", " ").replace(":", " ").replace("-", " ").split(" ", false):
			tokens.append(UNITS.get(token, token))
		var whole := phrase.call(" ".join(tokens) + ".") as AudioStream
		if whole != null:
			out.append([whole, true])
			continue
		var i := 0
		while i < tokens.size():
			var length := mini(10, tokens.size() - i)
			while length > 1 and not VoiceWords.SPANS.has(" ".join(tokens.slice(i, i + length))):
				length -= 1
			var word := " ".join(tokens.slice(i, i + length))
			if VoiceWords.SPANS.has(word):
				out.append([VoiceWords.track(word), i + length == tokens.size()])
			else:
				for letter in word:
					if VoiceWords.SPANS.has(letter):
						out.append([VoiceWords.track(letter), false])
				if not out.is_empty():
					out[-1][1] = i + length == tokens.size()
			i += length
	return out


static func normalize(text: String) -> String:
	text = text.to_lower().replace("m/s", "metres a second").replace("%", " percent ").replace(" · ", ". ").replace("//", ". ")
	# Coordinate suffixes are directions; a standalone duration suffix is seconds.
	for fix in _fix.search_all(text).duplicate():
		var suffix: String = fix.get_string(2)
		var direction: String = {"n": "north", "s": "south", "e": "east", "w": "west"}[suffix]
		text = text.replace(fix.get_string(), fix.get_string(1) + " " + direction)
	var out := ""
	var at := 0
	for found in _numbers.search_all(text):
		out += text.substr(at, found.get_start() - at)
		var value: String = found.get_string()
		var parts := value.trim_prefix("-").split(".")
		out += "minus " if value.begins_with("-") else ""
		out += number(int(parts[0]))
		if parts.size() > 1:
			out += " point"
			for digit in parts[1]:
				out += " " + SMALL[int(digit)]
		at = found.get_end()
	out += text.substr(at)
	# Separators and radio punctuation are pauses, not spoken symbols.
	var letters := RegEx.create_from_string("[^a-z .,;!?:-]+")
	return letters.sub(out, " ", true).strip_edges()


static func number(value: int) -> String:
	for scale: int in [1000000000, 1000000, 1000]:
		if value >= scale:
			var unit: String = {1000000000: "billion", 1000000: "million", 1000: "thousand"}[scale]
			return number(value / scale) + " " + unit + (" " + number(value % scale) if value % scale else "")
	if value >= 100:
		return SMALL[value / 100] + " hundred" + (" " + number(value % 100) if value % 100 else "")
	if value < 20:
		return SMALL[value]
	return TENS[value / 10] + (" " + SMALL[value % 10] if value % 10 else "")
