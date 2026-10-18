class_name Terminal
extends RefCounted
## What a machine prints to a screen: short lines, each from a sender. Logs and
## forms are kept, newest last, a few dozen at most; a readout is a sender's
## live rows, printed over its last. People never talk through it; machines
## do, and a sender's personality is in its formatting, never in paragraphs:
## a "!" before a line marks it urgent, and a row indented runs on from the
## one before. It prints and never asks: a screen that shows it is worked by
## use, like any device. One system for every sender: a Console's own messages
## now, later gods and their dispatches.

## Lines kept.
const KEEP := 32

## Every line kept, oldest first: {t, at, from, text}, at the local time it
## printed as a screen shows it.
var lines: Array = []
## Each sender's live readout rows, by sender.
var readouts := {}


## One log line from a sender, at world time t, `at` its local time as shown.
func log_line(from: String, text: String, t: float, at: String) -> void:
	lines.append({"t": t, "at": at, "from": from, "text": text})
	if lines.size() > KEEP:
		lines = lines.slice(lines.size() - KEEP)


## A form: its title, then each field as a key and its value, kept as lines.
func form(from: String, title: String, fields: Array, t: float, at: String) -> void:
	log_line(from, title, t, at)
	for field: Array in fields:
		log_line(from, "  %-8s %s" % [field[0], field[1]], t, at)


## A sender's live rows, in place of its last.
func readout(from: String, rows: PackedStringArray) -> void:
	readouts[from] = rows


## The newest n lines of several terminals, oldest first: what linked
## screens show as one.
static func merged(terminals: Array, n: int) -> Array:
	var all: Array = []
	for k in terminals.size():
		var own: Array = terminals[k].lines
		for i in own.size():
			all.append([own[i].t, k, i, own[i]])
	# By time, and a form's lines stay in their order.
	all.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] or a[0] == b[0] and (a[1] < b[1] or a[1] == b[1] and a[2] < b[2]))
	return all.slice(maxi(all.size() - n, 0)).map(func(e: Array) -> Dictionary: return e[3])
