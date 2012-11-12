require './bootstrap'
SKIP_DNSSD = true
require './PlexInterface'

pi = PlexInterface.new

pi.search 5, ARGV.shift