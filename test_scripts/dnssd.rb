require 'dnssd'
puts "Browsing Started"
service = DNSSD.browse('_plexmediasvr._tcp.') do |reply|
	if (reply.flags.to_i & DNSSD::Flags::Add) != 0
		puts "Add : #{reply.inspect}"
	else
		puts "Rm  :  #{reply.inspect}"
	end
end
sleep 1
service.stop
puts "Browsing Stopped"
