What is this baggotry?

This is mostly built to be a command line test harness for LibBaggotry.  It's
also occasionally useful, since autosplitting and automerging are two commonly
requested features.

Usage:
	/bag [-f filter] [-rx] [-l] [-SD] [-c category] [-q rarity] [name ...]

[-f filter] lets you name filters; "filter" can be a string and is used
as an index into a table, and modifiers are stored in that filter, which
then persists through the rest of your session.  If you do not specify
a filter, each /bag invocation starts a brand new filter.

Modifiers like "-c category" or "name" are added to the filter, as :includes
by default, or as :requires (-r) or :excludes (-x).  See LibBaggotry for
explanations.

The default is just to dump the list of items found.  The interesting
part is the -S (stack) option.  This tries to move things into stacks of
a specified size.  If the size specified is less than 1, it counts down
from the maximum stack size for the object; for instance, a stack size of
0 is the same as "whatever size the object stacks to".

	/bag -S 0 -c crafting

Tries to combine all things tagged as "crafting" into the largest stacks
it can.

	/bag -S 1 -c collectible

Tries to split all collectibles (such as artifacts) into stacks of 1.  Of
course, you could use a built-in filter:

	/bag -S 1 -f a

How would you know about that?  Why, you'd list the filters:

	/bag -l

I'm hoping to add some clever way to save filters, but it's obviously
impossible in the general case, because you could provide a function
reference as part of a filter, and there's no way for me to save that
properly.

You can dump a specific filter:
	/bag -D -f a

and see what rules that filter uses.

You can sum the value of a filter with the -s option.
