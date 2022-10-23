require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

root = File.expand_path("..", __FILE__)

get '/' do
  @files = Dir.glob("#{root}/data/*").map { |file| File.basename(file) }.sort
  erb :index
end

get '/:file' do
  file_name = params[:file]

  # #send_file automatically guesses value for Content-Type header, guessed
  # from the file extension of the file.
  send_file "#{root}/data/#{file_name}"
end
