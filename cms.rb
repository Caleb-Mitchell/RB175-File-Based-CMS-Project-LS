require "redcarpet"
require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path('test/data', __dir__)
  else
    File.expand_path('data', __dir__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

get '/' do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get '/new' do
  erb :new
end

post '/new' do
  # create file
  file_path = File.join(data_path, params[:file_name])
  File.write(file_path, params[:file_name])

  session[:success] = "#{params[:file_name]} was created."
  redirect '/'
end

get '/:file_name' do
  file_path = File.join(data_path, params[:file_name])

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:error] = "#{params[:file_name]} does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  file_path = File.join(data_path, params[:file_name])

  @file_name = params[:file_name]
  @content = File.read(file_path)

  erb :edit
end

post '/:file_name' do
  file_path = File.join(data_path, params[:file_name])

  File.write(file_path, params[:file_content])

  session[:success] = "#{params[:file_name]} has been updated."
  redirect '/'
end
