require 'tk'
require 'tkextlib/tile'
require 'mongo'

#setup the base window
root = TkRoot.new() {title "PlexPi"}
content = Tk::Tile::Frame.new(root) {padding "3 3 12 12"; height 600; width 960}
content.grid(:sticky => 'nsew')

$query = TkVariable.new
search = Tk::Tile::Entry.new(content) {textvariable $query;}

$list = TkVariable.new()
listbox = TkListbox.new(content) {listvariable $list}

content.grid(:column => 0, :row => 0)
search.grid(:column => 0, :row => 0)
listbox.grid(:column => 0, :row => 1)

$coll = Mongo::Connection.new.db("WoofTest").collection("dogs")

def dosearch
	$names = []
	$coll.find({'name' => /#{$query}/i}, :fields => ["name"]).each {|row| $names << row["name"]}
	$list.set_list($names)
	return 1
end

search.focus
search.bind("KeyRelease") {dosearch}

dosearch

Tk.mainloop