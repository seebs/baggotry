What is this baggotry?

This is mostly built to be a command line test harness for LibBaggotry.  It's
also occasionally useful, since autosplitting and automerging are two commonly
requested features.

Usage:
	/bag [-f filter] [-n count] [-S|-M] [-c category] [name ...]

[-f filter] lets you name filters; "filter" can be a string and is used
as an index into a table.  Modifiers like "-c category" or "name" are
added to filter as :includes (see LibBaggotry for explanations).  You
can then use -f filter without having to type the stuff out.  Filters
are not currently saved.

The default is just to dump the list of items found.  The interesting
part is the -M (merge) and -S (split) options.
	/bag -M -c crafting

Tries to combine all things tagged as "crafting" into the largest stacks
it can.

	/bag -n 1 -S -c collectible

Tries to split all collectibles (such as artifacts) into stacks of 1.

	/bag -n 10 -S -c material

Tries to split all "materials" into stacks of 10 -- which actually
implies merging them if you have smaller stacks.

