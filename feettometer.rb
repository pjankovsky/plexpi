require 'tk'
require 'tkextlib/tile'

root = TkRoot.new {title "Feet to Meters"}
content = Tk::Tile::Frame.new(root) {padding "3 3 12 12"}.grid( :sticky => 'nsew')
TkGrid.columnconfigure root, 0, :weight => 1
TkGrid.rowconfigure root, 0, :weight => 1

$feet = TkVariable.new
$meters = TkVariable.new

f = Tk::Tile::Entry.new(content) {width 7; textvariable $feet}.grid( :column => 2, :row => 1, :sticky => 'we')
Tk::Tile::Label.new(content) {textvariable $meters}.grid(:column => 2, :row => 2, :sticky => 'we')
Tk::Tile::Button.new(content) {text "Calculate"; command {calculate} }.grid(:column => 3, :row => 3, :sticky => 'w')

Tk::Tile::Label.new(content) {text "feet"}.grid(:column => 3, :row => 1, :sticky => 'w')
Tk::Tile::Label.new(content) {text "is equivalent to"}.grid(:column => 1, :row => 2, :sticky => 'e')
Tk::Tile::Label.new(content) {text "meters"}.grid(:column => 3, :row => 2, :sticky => 'w')

TkWinfo.children(content).each {|w| TkGrid.configure w, :padx => 5, :pady => 5}

f.focus
root.bind("Return") {calculate}
root.bind("Enter") {calculate}

def calculate
	begin
		$meters.value = (0.3048*$feet*10000.0).round()/10000.0
	rescue
		$meters.value = ''
	end
end

Tk.mainloop
