require 'tk'
require 'tkextlib/tile'
require 'mongo'
require 'net/http'
require 'rexml/document'
require 'digest/sha1'

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

$conn = Mongo::Connection.new
$coll_config = $conn.db("PlexPi").collection("config")

musiclistsha1 = $coll_config.find_one({'key'=>'musiclistsha1'})
if musiclistsha1 == nil
	$coll_config.insert({'key'=>'musiclistsha1', 'value'=>''})
	musiclistsha1 = $coll_config.find_one({'key'=>'musiclistsha1'})
end

xml = Net::HTTP.get(URI("http://10.0.89.13:32400/library/sections/5/search?type=10"))
sha1sum = Digest::SHA1.base64digest xml

$coll_music = $conn.db("PlexPi").collection("musiclist")

if sha1sum != musiclistsha1['value']
	$coll_music.remove
	doc = REXML::Document.new(xml)
	doc.elements.each('MediaContainer/Track') do |element|
		if element.attributes["title"] != ""
			$coll_music.insert({"title"=>element.attributes["title"]})
		end
	end
	musiclistsha1['value'] = sha1sum
	$coll_config.update({"_id" => musiclistsha1['_id']}, musiclistsha1)
end

def dosearch
	$titles = []
	$coll_music.find({'title' => /#{$query}/i}, :fields => ["title"]).sort(:title).each {|row| $titles << row["title"]}
	$list.set_list($titles)
	return 1
end

search.focus
search.bind("KeyRelease") {dosearch}

dosearch

Tk.mainloop