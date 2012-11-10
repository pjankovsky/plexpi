require 'tk'
require 'tkextlib/tile'
require 'mongo'
require 'net/http'
require 'rexml/document'

#setup the base window
root = TkRoot.new() {title "PlexPi"}
content = Tk::Tile::Frame.new(root) {padding "3 3 12 12"}
content.grid(:sticky => 'nsew')

$query = TkVariable.new
search = Tk::Tile::Entry.new(content) {textvariable $query;}

$list = TkVariable.new()
listbox = TkListbox.new(content) {listvariable $list; width 50}

content.grid(:column => 0, :row => 0)
search.grid(:column => 0, :row => 0)
listbox.grid(:column => 0, :row => 1)

$coll = Mongo::Connection.new.db("PlexPi").collection("musiclist")
$coll.remove

xml = Net::HTTP.get(URI("http://10.0.89.13:32400/library/sections/5/search?type=10"))
doc = REXML::Document.new(xml)
doc.elements.each('MediaContainer/Track') do |element|
	$coll.insert({"title"=>element.attributes["title"]})
end

def dosearch
	$titles = []
	$coll.find({'title' => /#{$query}/i}, :fields => ["title"]).each {|row| $titles << row["title"]}
	$list.set_list($titles)
	return 1
end

search.focus
search.bind("KeyRelease") {dosearch}

dosearch

Tk.mainloop