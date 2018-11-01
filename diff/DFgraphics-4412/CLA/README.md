# CLA Graphic Set #
This is a Graphic set for Dwarf Fortress, intended to be used with ASCII-like tilesets with a tile size of 18x18px such as Haowan or Myne. It contains three tilesets, creature graphics, a color scheme and a TTF Font 

## Installation ##
### Preinstalled (Windows only) ###
- download CLA preinstalled from [github](https://github.com/DFgraphics/CLA/releases) or [dffd](http://dffd.bay12games.com/file.php?id=5947) and extract into _new_ folder. **NEVER** overwrite an existing DF installation.
- to migrate existing saves, copy your save folder (`data/saves/region#`) to the new DF installation; then delete the contents of `data/saves/region#/raw/graphics` and replace it with the contents of `raw/graphics`

### Standalone ###
- download newest DF version and extract in _new_ folder
- download CLA preinstalled from [github](https://github.com/DFgraphics/CLA/releases) or [dffd](http://dffd.bay12games.com/file.php?id=5945) and extract into DF folder; overwrite files when prompted
- to migrate existing saves, copy your save folder (`data/saves/region#`) to the new DF installation; then delete the contents of `data/saves/region#/raw/graphics` and replace it with the contents of `raw/graphics`


##### Installation of only creature graphics ####
- delete or move all files in `raw/graphics` (other graphic sets, example graphics).
- put graphic set files (the folder 'CLA' and the textfiles within `raw/graphics/`) into `raw/graphics`.
- for existing saves delete the contents of `data/saves/region#/raw/graphics` and replace it with the contents of `raw/graphics` too
- Open `data/init.txt` with a text editor and change [GRAPHICS:NO] to [GRAPHICS:YES].
- generate new world and embark!

#### Change the tileset only ####
- Open up init.txt (in `data/init/`) with a text editor
- change the entries `FONT`, `FULLFONT`, `GRAPHICS_FONT`, and `GRAPHICS_FULLFONT` to the filename of your new tileset.

To update, just download the newest STANDALONE pack and repeat the steps above.
For more information and download links, visit the [bay12forum thread] (http://www.bay12forums.com/smf/index.php?topic=105376.0).
