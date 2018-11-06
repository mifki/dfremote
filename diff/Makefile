all: out out/Taffer out/Spacefox out/ASCII

Taffer := tilesets/Taffer tilesets/Taffer-Heretical tilesets/Taffer-Orthodox colors/Taffer
Taffer_p := taffer_20x20_serif_hollow_straight_walls.png
Taffer-Heretical_p := taffer.png
Taffer-Orthodox_p := taffer.png

Spacefox := tilesets/Spacefox
Spacefox_p := Spacefox_16x16Dibujor02.png

ASCII := tilesets/ASCII-Default tilesets/ASCII-Square
ASCII-Default_p := curses_800x600.png
ASCII-Square_p := curses_square_16x16.png



clean:
	rm -rf out
	rm -rf out-tilesets

out: clean
	mkdir out

.SECONDEXPANSION:
out/%: $$($$*)
	echo $^
	rm -rf $@
	mkdir $@
	for dir in $^; do D=$@ make _work/$$dir ; done

_work/colors/%:
	cp -r colors/$* $D/colors-$*

_work/tilesets/%:
	if [ -e tilesets/$*/4305/data/init ] ; then V=4305 make __work/tilesets/$* ; fi
	if [ -e tilesets/$*/4412/data/init ] ; then V=4412 make __work/tilesets/$* ; fi

__work/tilesets/%:
	mkdir -p $D/tileset-$*/$V
	node diff.js raw_vanilla-$V tilesets/$*/$V/data/init > $D/tileset-$*/$V/raw.json
	cp tilesets/$*/$V/data/init/colors.txt $D/tileset-$*/colors.txt
	cp tilesets/$*/$V/data/art/$($*_p) $D/tileset-$*/$V/tileset.png

.PHONY: clean