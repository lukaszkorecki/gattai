require 'eventmachine'
require 'em-proxy'


# hard coded for now

INCOMING = 3000

WORKERS = [3001, 3002]

t1 = Thread.new do
  Proxy.start(host: "127.0.0.1", port: INCOMING) do |conn|
    WORKERS.each_with_index do |port, idx|
      conn.server "worker_#{idx}".to_sym, host: "127.0.0.1", port:  port
    end


    conn.on_data { |data| p [:on_data, data] ;  data }
    conn.on_response { |server, resp| p [ :on_response, server, resp ] ;  resp }
  end

end

t2 = Thread.new do
  Proxy.start(host: "127.0.0.1", port: INCOMING-1) do |conn|
    WORKERS.each_with_index do |port, idx|
      conn.server "worker_#{idx}".to_sym, host: "127.0.0.1", port:  port
    end


    conn.on_data { |data| p [:on_data, data] ;  data }
    conn.on_response { |server, resp| p [ :on_response, server, resp ] ;  resp }
  end
end
[t1, t2].map(&:join)
