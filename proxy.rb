require 'eventmachine'
require 'em-proxy'
require 'logger'


class Gattai
  LOCALHOST="127.0.0.1"
  def initialize name, config
    @name = name
    @workers = []

    create_logger

    set_main_proxy config['proxy']
    config['workers'].each {|worker_name, worker_conf| add_worker worker_name, worker_conf }
    @log.warn "Creating proxy: #{@name} with #{@workers.count} workers"
  end

  def start
    @log.warn "Starting #@name proxy"
    log = @log

    this = self
    ::Proxy.start(host: @host, port: @port) do |conn|
      puts this.log
      puts this.workers
      this.workers.each do |worker|
        conn.server worker['name'].to_sym, host: worker['host'], port: worker['port']
      end

      conn.on_data { |data| data }
      conn.on_response { |server, resp| this.log.info  server ;  resp }
    end
  end

  def workers
    @workers
  end

  def log
    @log
  end
  private

  def create_logger
    @log = ::Logger.new STDOUT
    @log.formatter = proc do |severity, datetime, progname, msg|
      "|| #{@name} #{severity} #{datetime}: #{msg}\n"
    end
  end

  def set_main_proxy conf
    @host = conf['host'] || LOCALHOST
    @port = conf.fetch 'port'
  end

  def add_worker name, conf
    @workers << {
      'name' =>  name.to_sym,
      'host' => conf['host'] || LOCALHOST,
      'port' => conf.fetch('port')
    }
  end
end

# ok!
puts "Loading config from #{ARGV[0]}"
config = YAML::load_file(ARGV[0])
thread_pool = []

config.each do |name, proxy_config|
  thread_pool << Thread.new do
    proxy = Gattai.new(name, proxy_config)
    proxy.start
  end
end

thread_pool.map(&:join)
