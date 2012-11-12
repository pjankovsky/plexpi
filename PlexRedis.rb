require 'redis'
require 'text/double_metaphone'

class PlexRedis

	CLEAN = /[^A-Za-z0-9_]/

	def initialize
		if REDIS_NAME.to_s == ''
			raise ArgumentError, 'REDIS_NAME is not valid. Must be a string.'
		elsif REDIS_NAME =~ CLEAN
			raise ArgumentError, 'REDIS_NAME should only have alphanumberic characters and underscores ("_").'
		end
		connect
	end

	def search server_name, section_id, query
		words = query.upcase.strip.gsub(/\s+/, ' ').gsub(/[^A-Z0-9 ]/, '').split(' ').uniq
		meta_words = []
		words.each do |word|
			meta_words += Text::Metaphone.double_metaphone(word)
		end
		base_key = real_key 'index_'+server_name, section_id
		keys = []
		meta_words.uniq.each do |meta_word|
			if meta_word != nil && meta_word != ''
				keys << base_key+':'+meta_word
			end
		end
		return @redis.sunion keys
	end

	# Search Indexing

	INDEX_KEYS = ['title', 'parentTitle', 'grandparentTitle', 'summary', 'originalTitle', 'titleSort']

	def reindex server_name, section_type, section_id, xml
		if section_type == 'show' || section_type == 'movie'
			search = 'MediaContainer/Video'
		elsif section_type == 'artist'
			search = 'MediaContainer/Track'
		end

		REXML::Document.new(xml).elements.each(search) do |element|
			string = ''
			INDEX_KEYS.each do |key|
				if element.attributes.has_key? key
					string += ' ' + element.attributes[key]
				end
			end
			words = string.upcase.strip.gsub(/\s+/, ' ').gsub(/[^A-Z0-9 ]/, '').split(' ').uniq
			meta_words = []
			words.each do |word|
				meta_words += Text::Metaphone.double_metaphone(word)
			end
			id = element.attributes['key'].sub('/library/metadata/','').to_i
			base_key = real_key 'index_'+server_name, section_id
			meta_words.uniq.each do |meta_word|
				if meta_word != nil && meta_word != ''
					@redis.sadd base_key+':'+meta_word, id
				end
			end
		end

		set_config server_name+'_'+section_id+'_sha1sum', Digest::SHA1.base64digest(xml)
	end

	# Config

	def set_config key, value
		return @redis.set real_key('config', key), value
	end

	def get_config key
		return @redis.get real_key('config', key)
	end

	#cleaners

	RKS = ':'

	def real_key realm, key
		return REDIS_NAME + RKS + clean_string(realm) + RKS + clean_string(key)
	end

	def clean_string string
		return string.to_s.gsub(CLEAN, '')
	end

	# setup connection

	def connect
		if REDIS_SOCK != false
			@redis = Redis.new(:path => REDIS_SOCK)
		elsif REDIS_HOST == false && REDIS_PORT == false
			@redis = Redis.new
		elsif REDIS_HOST == false
			@redis = Redis.new(:port => REDIS_PORT)
		elsif REDIS_PORT == false
			@redis = Redis.new(:host => REDIS_HOST)
		else
			@redis = Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
		end
	end

end