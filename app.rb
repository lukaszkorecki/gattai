require 'sinatra'

get '/' do
  "Worker #{ENV['WORKER_ID']}"
end
