
# IconPicker
#
# Encapsule la récupération d'icônes depuis l'image source unique.
# IconPicker ne comporte qu'une seule méthode qui renvoie toujours sans exception une icône valide.
# La classe ne référence aucune icône.
#
#
# ** MÉTHODES *****************************************
#
# get_icon ............	Génére et récupére une nouvelle icône
#
#.............................................................................................................

const _ICON_SIZE = 16
const _MAX_COLUMNS = 7
const _MAX_ROWS = 4

var _image # Image

#.............................................................................................................

func get_icon(column, row, width = 1, height = 1): # int, int, int, int : ImageTexture

	column = clamp(column, 0, _MAX_COLUMNS - 1)
	row = clamp(row, 0, _MAX_ROWS - 1)
	width = clamp(width, 1, _MAX_COLUMNS - column) * _ICON_SIZE
	height = clamp(height, 1, _MAX_ROWS - row) * _ICON_SIZE

	var i = Image(width, height, false, Image.FORMAT_RGBA)
	i.blit_rect(_image, Rect2(_ICON_SIZE * column, row * _ICON_SIZE, width, height), Vector2(0, 0))
	var t = ImageTexture.new()
	t.create_from_image(i)
	return t

#.............................................................................................................

func _init():

	var p = get_script().get_path().get_base_dir() + "/icons.png"

	if File.new().file_exists(p):

		var t = load(p)

		if t != null:

			t.set_size_override(Vector2(_MAX_COLUMNS * _ICON_SIZE, _MAX_ROWS * _ICON_SIZE))
			_image = t.get_data()

	if _image == null:

		_image = Image(1, 1, false,Image.FORMAT_RGB)
		_image.put_pixel(0, 0, Color(1, 0, 1))
		_image = _image.resized(_MAX_COLUMNS * _ICON_SIZE, _MAX_ROWS * _ICON_SIZE)