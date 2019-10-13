# ENERGIZE!

You are a petty officer aboard the USS Lakota assigned to the transporter
room. You learn the basics of transporter operation in a series of simple
assignments, and as you progress in rank you come across more and more
difficult challenges.

## Running during development:

### Requirements
* love2d version 11 or newer https://love2d.org/
* luafilesystem (provides better completion for in-game editor)

run `make` to start the game

## Building for distribution

### Requirements

* lua 5.1+ (for AOT compilation)
* [butler](https://itch.io/docs/butler/installing.html)
* an itch.io account

Run `make release` to build releases for Linux, Mac, and Windows, and
have them uploaded to itch.io using Butler. You'll need to run `butler
login` to log into your itch.io account if you haven't done that before.

## TODO:

* make the gameplay more fun!
* detect progress in the level as particles are locked
* win animation -> next briefing -> next level
* lose screen -> retry
* save progress
* level select?

## Levels:

* cargo box of quadrotriticale (tutorial)
* one person
* several people
* falling person?
* person wearing an unauthorized weapon?
* reversing a transporter accident
* Tuvix??

We should see if we can incorporate some backstory for the characters
beaming in.

## Game mechanics options:

Falling particles come down and must be placed in order to fill a silhouette
of the character beaming in. As the particles fall, they phase in and out.
At any point when it's phased in, you can lock the particle in place, unlike
in classic tetris where blocks only stop falling when they land on another
block. You have a limited number of particles to place before you run out,
but you don't need to get it 100% perfect.

 OR:

sokoban-like arrangement of particles?

## Art needed

* [X] title screen
* [X] mission briefing (LCARS padd w/ commander portrait?)
* [X] transporter pad with control panel
* [ ] external shots between missions?
* [ ] various characters being beamed in

https://p.hagelb.org/galaxy-transporter.jpg

## credits

* [LÖVE](https://love2d.org) Copyright © 2006-2018 LOVE Development Team, distributed under the zlib license
* [Fennel](https://github.com/bakpakin/Fennel) Copyright © 2016-2018 Calvin Rose and contributors, distributed under the MIT/X11 License
* [lume](https://github.com/rxi/lume) Copyright © 2015-2018 rxi, distributed under the MIT/X11 License
* [polywell](https://git.sr.ht/~technomancy/polywell) Copyright © 2015-2019 Phil Hagelberg, distributed under LGPLv3
* [fonts](https://github.com/wrstone/fonts-startrek) distributed under GPLv3
