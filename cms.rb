require "redcarpet"
require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

ADMIN_USER = "admin"
ADMIN_PASSWORD = "secret"

before do
  session[:users] ||= { ADMIN_USER => ADMIN_PASSWORD }
end

# rubocop:disable Style/ExpandPathArguments
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end
# rubocop:enable Style/ExpandPathArguments

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

def valid_user?
  session[:users].keys.include?(params[:username]) &&
    session[:users][params[:username]] == params[:password]
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

post '/create' do
  if params[:file_name].empty?
    session[:error] = "A name is required."
    status 422
    erb :new
  else
    file_path = File.join(data_path, params[:file_name])
    File.write(file_path, "")

    session[:success] = "#{params[:file_name]} was created."
    redirect '/'
  end
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if valid_user?
    session[:signed_in] =
      { current_user: params[:username], current_pass: params[:password] }
    session[:success] = "Welcome!"
    redirect '/'
  else
    session[:error] = "Invalid credentials."
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:signed_in)
  session[:success] = "You have been signed out."
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

post '/:file_name/delete' do
  file_path = File.join(data_path, params[:file_name])

  File.delete(file_path)

  session[:success] = "#{params[:file_name]} has been deleted."
  redirect '/'
end
