V=$1

function p {
	if [ ! -d DFgraphics-$V/$1 ] ; then
		return
	fi

	mkdir -p out-$V/tileset-$1
	rm -rf raw
	cp -r raw_vanilla-$V raw
	cp -r DFgraphics-$V/$1/raw/* raw/
	cp -r DFgraphics-$V/$1/raw/graphics out-$V/tileset-$1/
	node diff.js raw DFgraphics-$V/$1/data/init > out-$V/tileset-$1/raw.json
	cp DFgraphics-$V/$1/data/init/colors.txt out-$V/tileset-$1/
	cp "DFgraphics-$V/$1/data/art/$2" out-$V/tileset-$1/tileset.png
	cp DFgraphics-$V/$1/manifest.json out-$V/tileset-$1/
	cp manifests/$1/manifest.json out-$V/tileset-$1/
}

rm -rf raw

p Afro Afro_16x16.png
p ASCII-Default curses_800x600.png
p ASCII-Square curses_square_16x16.png
p CLA CLA.png
p CursesOfBalin cob.png
p CursesOfBalin-Blue cob-blue.png
p Duerer duerer_map_15x15.png
p GemSet gemset_map.png
p Grim-Fortress grim.png
p Ironhand ironhand.png
p Jolly-Bastion jolly12x12.png
p Mayday mayday.png
p MLC-ASCII "MLC 16x16 - Graphics.png"
p Obsidian Obsidian_16x16_df40.png
p Phoebus Phoebus_16x16.png
p Shizzle curses_1280x500.png
p SimpleMood 16x16_sm.png
p Spacefox Spacefox_16x16Dibujor02.png
p Taffer taffer_20x20_serif_hollow_straight_walls.png
p Taffer-Heretical taffer.png
p Taffer-Orthodox taffer.png
p Tergel 16x16_Tergel.png
p Vacuum-NoCells-CoQ VFDTilesNoCells.png
p Wanderlust wanderlust.png

rm -rf raw
