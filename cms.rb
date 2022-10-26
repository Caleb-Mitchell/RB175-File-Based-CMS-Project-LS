require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

root = File.expand_path(__dir__)

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @files = Dir.glob("#{root}/data/*").map { |file| File.basename(file) }.sort
end

get '/' do
  erb :index
end

get '/:file_name' do
  file_name = params[:file_name]

  # #send_file automatically guesses value for Content-Type header, guessed
  # from the file extension of the file.
  if @files.include?(file_name)
    send_file "#{root}/data/#{file_name}"
  else
    session[:error] = "#{file_name} does not exist."
    redirect '/'
  end
end
