VERSION=0.1.0
NAME=energize
ITCH_ACCOUNT=technomancy
URL=https://git.sr.ht/~technomancy/energize
AUTHOR="Justin Smith and Phil Hagelberg"
DESCRIPTION="A game where you're the transporter operator on a starship"

LIBS := $(wildcard polywell/lib/*.lua) $(wildcard lib/*)
LUA := $(wildcard *.lua) polywell/old.lua polywell/frontend/love.lua polywell/frontend/init.lua
SRC := $(wildcard *.fnl) $(wildcard polywell/*fnl) $(wildcard polywell/lib/*fnl) $(wildcard config/*fnl)
OUT := $(patsubst %.fnl,%.lua,$(SRC))

run: ; love .

count: ; cloc *.fnl
clean: ; rm -rf releases/* $(OUT)
cleansrc: ; rm -rf $(OUT)

%.lua: %.fnl; lua polywell/lib/fennel --compile --metadata --correlate $< > $@

LOVEFILE=releases/$(NAME)-$(VERSION).love

$(LOVEFILE): $(LUA) $(OUT) $(LIBS) assets text
	mkdir -p releases/
	find $^ -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X $@ -@

love: $(LOVEFILE)

# platform-specific distributables

REL=$(PWD)/love-release.sh # https://p.hagelb.org/love-release.sh
FLAGS=-a "$(AUTHOR)" --description $(DESCRIPTION) \
	--love 11.2 --url $(URL) --version $(VERSION) --lovefile $(LOVEFILE)

releases/$(NAME)-$(VERSION)-x86_64.AppImage: $(LOVEFILE)
	cd appimage && ./build.sh 11.2 $(PWD)/$(LOVEFILE)
	mv appimage/game-x86_64.AppImage $@

releases/$(NAME)-$(VERSION)-macos.zip: $(LOVEFILE)
	$(REL) $(FLAGS) -M
	mv releases/$(NAME)-macos.zip $@

releases/$(NAME)-$(VERSION)-win.zip: $(LOVEFILE)
	$(REL) $(FLAGS) -W32
	mv releases/$(NAME)-win32.zip $@

linux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
mac: releases/$(NAME)-$(VERSION)-macos.zip
windows: releases/$(NAME)-$(VERSION)-win.zip

# If you release on itch.io, you should install butler:
# https://itch.io/docs/butler/installing.html

uploadlinux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):linux --userversion $(VERSION)
uploadmac: releases/$(NAME)-$(VERSION)-macos.zip
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):mac --userversion $(VERSION)
uploadwindows: releases/$(NAME)-$(VERSION)-win.zip
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):windows --userversion $(VERSION)

upload: uploadlinux uploadmac uploadwindows

release: linux mac windows upload cleansrc

gif: ; byzanz-record -w 640 -h 400 -d 3 out.gif
