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

* [ ] make the gameplay more fun!
* [X] detect progress in the level as particles are locked
* [X] win animation -> next briefing -> next level
* [X] lose screen -> retry
* [ ] save progress
* [ ] level select?

## Story

The Lakota is assigned to investigate a disturbance in the Malcor
system, which has been home to a pre-warp-capable civilization. They
have been acting aggressively towards nearby systems. An investigation
reveals that they have been provided with advanced technology in
violation of the prime directive by a rogue starfleet captain; you
must go apprehend them.

### Cargo box of quadrotriticale

This is just a tutorial; you can't lose. The box gets beamed up.

### Lt. Darael (Betazoid disguized as Malcoran)

Lt. Darael has been a cultural observer in disguise on Malcor III; she
has requested evacuation as her team has split up, and she believes her
cover is compromised.

Once she beams up, Benteen (or T'Ral) debriefs her; she says that she
has noticed that the Malcorans have access to a higher level of
technology than they should, achieving warp travel in the past two
years. They have been acting aggressively towards neighboring systems.

### Cmdr Juran (Andorian) and Lt. Kolimet (Klingon)

Juran and Kolimet were Darael's teammates on the Malcor assignment;
they have left Malcor in the runabout USS Serayu to pursue a lead
they suspect will be able to explain where the technology is coming
from. Their ship is disabled and adrift; you need to beam them back
together.

Once they are on board, they tell the Captain that the ship they were
chasing met up with the USS Chandrasekhar under Captain
Cunningham. The Chandrasekhar disabled the Serayu when they
interrupted a transfer of cargo.

### Lt. Cmdr Atanyo (Falling humanoid) (Grazerite?)

Benteen receives a coded subspace message from Lt. Cmdr Atanyo of the
Chandrasekhar; he is worried about the behavior of his captain and
understands that he has gone rogue. He gives you their coordinates so
you can rendezvous with them.

Captain Cunningham discovers the message and goes to apprehend Atanyo,
who flees thru the ship and is almost apprehended, but he topples over
a railing in engineering and manages to disable the shields long
enough for you to beam him over and save him. He is in mid-air when
he's beamed out.

While this goes on, the Chandrasekhar attacks, and your screen shakes
as the Lakota takes damage. Once the transporter sequence is complete,
the Lakota counterattacks and takes down the Chandrasekhar's shields
and weapons.

### Captain Cunningham (rogue captain)

Once the Chandrasekhar's shields are down, you can beam Captain
Cunningham aboard the Lakota, but the biofilters detect that he is
armed, so it's your job to filter out the weapon and ensure that it is
not materialized with the captain.

Once he materializes he gives a rant about how the Prime Directive is
holding back progress and how he's the only visionary who can see it.
T'Ral arrives and escorts him to the brig.

You win!

## Game mechanics

Falling particles come down and must be placed in order to fill a silhouette
of the character beaming in. As the particles fall, they phase in and out.
At any point when it's phased in, you can lock the particle in place, unlike
in classic tetris where blocks only stop falling when they land on another
block. You have a limited number of particles to place before you run out,
but you don't need to get it 100% perfect.

## Art needed

* [X] title screen
* [X] mission briefing (LCARS padd w/ commander portrait?)
* [X] transporter pad with control panel
* [X] external shots between missions?
* [ ] various characters being beamed in

https://p.hagelb.org/galaxy-transporter.jpg

## credits

* [LÖVE](https://love2d.org) Copyright © 2006-2018 LOVE Development Team, distributed under the zlib license
* [Fennel](https://github.com/bakpakin/Fennel) Copyright © 2016-2018 Calvin Rose and contributors, distributed under the MIT/X11 License
* [lume](https://github.com/rxi/lume) Copyright © 2015-2018 rxi, distributed under the MIT/X11 License
* [polywell](https://git.sr.ht/~technomancy/polywell) Copyright © 2015-2019 Phil Hagelberg, distributed under LGPLv3
* [fonts](https://github.com/wrstone/fonts-startrek) by William Stone, distributed under GPLv3
* [beam sound](https://opengameart.org/content/60-cc0-sci-fi-sfx) by rubberduck, distributed under CC0
* [phaser sound](https://opengameart.org/content/laser-shot) by Gumichan01, distributed under CC-BY-SA 3.0

## license

Copyright © 2019 [Justin Smith](https://noisesmith.org) and
[Phil Hagelberg](https://technomancy.us) and [Emma Bukacek](https://emmabukacek.com)

Code distributed under the GNU General Public License version 3 or
later; see file license.txt; art and music using Creative Commons
Attribution ShareAlike 4.0; see cc-license.txt.
