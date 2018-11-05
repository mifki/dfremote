function p {
	mkdir -p out/tileset-$1

	cp manifests/$1/manifest.json out/tileset-$1/
	cp colors/$1/* out/tileset-$1/

	if [ -d out-4305/tileset-$1 ] ; then
		mkdir -p out/tileset-$1/4305
	
		cp out-4305/tileset-$1/raw.json out/tileset-$1/4305/
		cp out-4305/tileset-$1/tileset.png out/tileset-$1/4305/
		cp -r out-4305/tileset-$1/graphics out/tileset-$1/4305/
		
		cp out-4305/tileset-$1/colors.txt out/tileset-$1/
	fi

	if [ -d out-4412/tileset-$1 ] ; then
		mkdir -p out/tileset-$1/4412
	
		cp out-4412/tileset-$1/raw.json out/tileset-$1/4412/
		cp out-4412/tileset-$1/tileset.png out/tileset-$1/4412/
		cp -r out-4412/tileset-$1/graphics out/tileset-$1/4412/
		
		cp out-4412/tileset-$1/colors.txt out/tileset-$1/
	fi

	cd out
	zip -rq ../packages/tileset-$1.zip tileset-$1
	cd ..
}

rm -rf out
mkdir -p packages
rm -rf packages/*

p Afro
p ASCII-Default
p ASCII-Square
p CLA
p CursesOfBalin
p CursesOfBalin-Blue
p Duerer
p GemSet
p Grim-Fortress
p Ironhand
p Jolly-Bastion
p Mayday
p MLC-ASCII
p Obsidian
p Phoebus
p Shizzle
p SimpleMood
p Spacefox
p Taffer
p Taffer-Heretical
p Taffer-Orthodox
p Tergel
p Vacuum-NoCells
p Wanderlust

rm -rf out