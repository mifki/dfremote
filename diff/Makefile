PKGS := Afro ASCII CLA CursesOfBalin GemSet Grim-Fortress Ironhand Jolly-Bastion Mayday Obsidian Phoebus SimpleMood Spacefox Taffer Tergel Wanderlust

Afro := tilesets/Afro
Afro_p = Afro_16x16.png

ASCII := tilesets/ASCII-Default tilesets/ASCII-Square
ASCII-Default_p := curses_800x600.png
ASCII-Square_p := curses_square_16x16.png

CLA := tilesets/CLA
CLA_p := CLA.png

CursesOfBalin := tilesets/CursesOfBalin tilesets/CursesOfBalin-Blue
CursesOfBalin_p := cob.png
CursesOfBalin-Blue_p := cob-blue.png

GemSet := tilesets/GemSet
GemSet_p := gemset_map.png

Grim-Fortress := tilesets/Grim-Fortress
Grim-Fortress_p := grim.png

Ironhand := tilesets/Ironhand
Ironhand_p := ironhand.png

Jolly-Bastion := tilesets/Jolly-Bastion
Jolly-Bastion_p := jolly12x12.png

Mayday := tilesets/Mayday
Mayday_p := mayday.png

Obsidian := tilesets/Obsidian
Obsidian_p := Obsidian_16x16_df40.png

Phoebus := tilesets/Phoebus
Phoebus_p := Phoebus_16x16.png

SimpleMood := tilesets/SimpleMood
SimpleMood_p := 16x16_sm.png

Spacefox := tilesets/Spacefox
Spacefox_p := Spacefox_16x16Dibujor02.png

Taffer := tilesets/Taffer tilesets/Taffer-Heretical tilesets/Taffer-Orthodox colors/Taffer
Taffer_p := taffer_20x20_serif_hollow_straight_walls.png
Taffer-Heretical_p := taffer.png
Taffer-Orthodox_p := taffer.png

Tergel := tilesets/Tergel
Tergel_p := 16x16_Tergel.png

Wanderlust := tilesets/Wanderlust
Wanderlust_p := wanderlust.png






all: out
	for dir in $(PKGS) ; do make out/$$dir ; done
	#cd colors ; for dir in * ; do zip -rq "../packages/colors-$$dir.zip" "$$dir" ; done

clean:
	rm -rf out
	rm -rf out-tilesets
	rm -rf packages

out: clean
	mkdir out
	mkdir packages

.SECONDEXPANSION:
out/%: $$($$*)
	echo $^
	rm -rf $@
	mkdir $@
	for dir in $^; do D=$@ make _work/$$dir ; done
	cd $@ ; zip -rq ../../packages/pkg-$*.zip *

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