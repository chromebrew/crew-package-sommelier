#!/usr/bin/env ruby
# dpi_checker.rb: Check system DPI and store it to #{CREW_PREFIX} automatically
require 'socket'

HELP = <<~'EOT'
  dpi_checker.rb: Check system DPI and store it to #{CREW_PREFIX} automatically

  Usage: dpi_checker.rb
EOT

def log (message)
  puts "[dpi_checker]: #{message}"
end

if ARGV[0] =~ /^(--help|-h)$/
  puts HELP
  exit
end

# expected location of this script: #{CREW_PREFIX}/lib/sommelier/dpi_checker/
CREW_PREFIX = File.expand_path('../../..', __dir__)

puts "\e[1;33m" + 'Detecting system DPI (a new tab will appear and close quickly)...' + "\e[0m"
puts

sleep 1

# start a web server, wait for dpi_checker.html to upload screen DPI
log 'Starting web server...'

# let ruby find an unused port automatically by setting the port to 0
server = TCPServer.new('127.0.0.1', 0)
# get address and port number
server_port, server_addr = server.addr[1..2]

# add REUSEADDR option to prevent kernel from keeping the port
server.setsockopt(:SOCKET, :REUSEADDR, true)

log "Server started at #{server_addr} port #{server_port}"

socket_thread = Thread.new do
  begin
    Socket.accept_loop(server) do |sock, _|
      begin
        header = sock.gets("\r\n\r\n")
        next unless header # undefined method `lines' for nil:NilClass

        method, path, _ = header.lines(chomp: true)[0].split(' ', 3)

        case path
        when '/upload_result'
          # this will execute when dpi_checker.html send the DPI back
          sock.print('HTTP/1.1 200 OK' + "\r\n\r\n")
          result = sock.read
          log "Received result sent from browser: #{result}"
          socket_thread[:dpi] = result.to_i
          break
        else
          # find requested file from the directory this script in,
          # send the file back to browser if it exists
          file = File.join(__dir__, File.basename(path))

          if File.exist?(file)
            sock.print('HTTP/1.1 200 OK' + "\r\n\r\n")
            sock.write( File.read(file) )
          else
            sock.print('HTTP/1.1 404 Not Found' + "\r\n\r\n")
          end
        end
      rescue Errno::EPIPE
      ensure
        sock.close
      end
    end
  ensure
    server.close
  end
end

# open dpi_checker.html in browser
system 'dbus-send', '--system',
       '--type=method_call', '--print-reply',
       '--dest=org.chromium.UrlHandlerService',
       '/org/chromium/UrlHandlerService',
       'org.chromium.UrlHandlerServiceInterface.OpenUrl',
       "string:http://#{server_addr}:#{server_port}/dpi_checker.html"

log "Opened URL http://#{server_addr}:#{server_port}/dpi_checker.html in browser"

# wait for dpi_checker.html
socket_thread.join

dpi = socket_thread[:dpi]

log "Current system DPI: #{dpi}"
log "Storing result to #{CREW_PREFIX}/etc/sommelier.dpi..."

# write result to file
File.write("#{CREW_PREFIX}/etc/sommelier.dpi", dpi)