require 'dnssd'
require 'net/http'
require 'rexml/document'
require 'digest/sha1'

require './PlexRedis'

class PlexInterface

	SERVER_SERVICE = '_plexmediasvr._tcp.'

	def initialize
		@servers = nil
		@server = nil
		@pRedis = PlexRedis.new
		init_server
	end

	def search section_id, query
		ids = @pRedis.search @server['name'], section_id, query
		ids.each do |id|
			p plex_get 'library/metadata/'+id
		end
	end

	def init_server
		last_server = @pRedis.get_config 'last_server'
		pick_server last_server
		check_server
		if last_server == nil
			@pRedis.set_config 'last_server', @server['name']
		end
		check_indexes
	end

	def check_indexes
		get_sections().each do |section_id, section_type|
			search_key = nil
			REXML::Document.new(plex_get('library/sections/'+section_id)).elements.each('MediaContainer/Directory') do |element|
				if element.attributes.has_key? 'search'
					search_key = element.attributes['key']
				end
			end
			if search_key != nil
				xml = plex_get 'library/sections/'+section_id+'/'+search_key
				oldsha1sum = @pRedis.get_config(@server['name']+'_'+section_id+'_sha1sum')
				sha1sum = Digest::SHA1.base64digest(xml)
				if sha1sum != oldsha1sum
					STDERR.puts 'reindexing '+@server['name']+' : '+section_id
					@pRedis.reindex @server['name'], section_type, section_id, xml
				else
					STDERR.puts 'index up to date for '+@server['name']+' : '+section_id
				end
			end
		end
	end

	def get_sections
		xml = plex_get 'library/sections'
		doc = REXML::Document.new xml
		sections = {}
		doc.elements.each('MediaContainer/Directory') do |element|
			sections[element.attributes['key']]=element.attributes['type']
		end
		return sections
	end

	def check_server
		xml = plex_get ''
		doc = REXML::Document.new xml
		if doc.elements.empty?
			raise 'Unable to read data from server'
		end
	end

	def plex_get uri
		return Net::HTTP.get(URI('http://'+@server['host']+':'+@server['port']+'/'+uri))
	end

	def get_available_servers
		#because my mac sucks at dnssd (hillariously)
		if SKIP_DNSSD
			STDERR.puts 'Skip DNS-SD'
			@servers = {'main' => {'host' => 'localhost', 'port' => '32400', 'name' => 'main'}}
			return @servers
		end

		if @servers != nil
			return @servers
		end

		rawServers = {}
		DNSSD.browse '_plexmediasvr._tcp.', 'local' do |reply|
			rawServers[reply.name] ||= reply
		end
		
		STDERR.sync = true
		STDERR.print 'Looking for servers'
		1.times do
			STDERR.print '.'
			sleep 1
		end
		STDERR.puts 'Done'

		@servers = {}

		rawServers.each do |key, reply|
			DNSSD.resolve reply.name, reply.type, 'local' do |resolve_reply|
				@servers[resolve_reply.name] = {'host' => resolve_reply.target.chomp('.'), 'port' => resolve_reply.port, 'name' => resolve_reply.name}
			end
		end

		STDERR.print 'Resolving servers'
		1.times do
			STDERR.print '.'
			sleep 1
		end
		STDERR.puts 'Done'

		return @servers
	end

	def pick_server name=nil
		get_available_servers
		if @servers.empty?
			raise 'No servers available.'
		end
		if name == nil
			@server = @servers[@servers.keys[0]]
		else
			if @servers.has_key? name
				@server = @servers[name]
			else
				raise ArgumentError, '#{name} not found in server list'
			end
		end
		return @server
	end

end

