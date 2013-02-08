require 'eventmachine'
require 'em-proxy'


class ProxyFactory # ugh
  LOCALHOST="127.0.0.1"
  def initialize bind_to={ host: LOCALHOST, port: 3000} , workers=[ { name: "worker_1", host: LOCALHOST, port: 3001}]
    @host = bind_to.fetch :host
    @port = bind_to.fetch :port
    @wokers = workers
    @logger = ::Logger.new STDOUT # TODO configurable?
  end

  def start
    Proxy.start(host: @host, port: @port) do |conn|
      @workers.each_with_index do |worker|
        conn.server worker[:name].to_sym, host: worker[:host], port: worker[:port]
      end


      conn.on_data { |data| @logger.info [:on_data, data] ;  data }
      conn.on_response { |server, resp| @logger.info [ :on_response, server, resp ] ;  resp }
    end
  end
end

# not sure about :symbols here
workers = [
  { name: 'worker_1', port: 3001, host: '127.0.0.1' },
  { name: 'worker_2', port: 3002, host: '127.0.0.1' }
]

t1 = Thread.new do
  ProxyFactory.new({host: '127.0.0.1', port: 3000}, workers).start

end
[t1].map(&:join)
