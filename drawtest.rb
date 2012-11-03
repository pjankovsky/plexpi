require 'tk'
require 'tkextlib/tile'

root = TkRoot.new()
button = Tk::Tile::TButton.new(root) {text "Hello Button"}.grid

Tk.mainloop
