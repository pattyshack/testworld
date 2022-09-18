# testworld

Learn lua via minetest game modding.

Gameplay, definitions, etc are loosely based on minetest game, mineclone 2, lord
of test, and hades revisited.

Texture files are also from these games, with file renamed to simplify
programming.

Note:

1. The modules will use Cartesian 3d coordinate system (where Z represents
the vertical axis) instead of the in-game/rendering coordinate system (where Z
represents the "depth" axis). i.e., module's (X, Y, Z) = minetest's (X, Z, Y).

2. All probability are expressed in basis points (i.e., 1/100 of a percent) when
odds are not expressed in (item, odds)-tuple list form
