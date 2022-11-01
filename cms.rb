require "bcrypt"
require "redcarpet"
require "securerandom"
require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "yaml"

ALLOWED_FILE_EXTENSIONS = [".txt", ".md"]
SECRET = SecureRandom.hex(32)

configure do
  enable :sessions
  set :session_secret, SECRET
end

# rubocop:disable Style/ExpandPathArguments
def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def image_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path('../test/public/images', __FILE__)
  else
    File.expand_path('../public/images', __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
                       File.expand_path("../test/users.yml", __FILE__)
                     else
                       File.expand_path("../users.yml", __FILE__)
                     end
  if File.exist?(credentials_path)
    YAML.load_file(credentials_path)
  else
    {}
  end
end

def write_user_credentials(username, password)
  credentials_path = if ENV["RACK_ENV"] == "test"
                       File.expand_path("../test/users.yml", __FILE__)
                     else
                       File.expand_path("../users.yml", __FILE__)
                     end
  File.write(credentials_path,
             "#{username}: #{BCrypt::Password.create(password)}\n", mode: 'a+')
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

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  return if user_signed_in?

  session[:error] = "You must be signed in to do that"
  redirect '/'
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def create_file_list
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
end

def create_image_list
  pattern = File.join(image_path, "*")
  @image_files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
end

def file_is_multiple_copy?(filename)
  # file is a copy if base file name ends in "copy" and any number of digits
  File.basename(filename, ".*").match?(/copy[0-9]+$/)
end

def file_is_single_copy?(filename)
  # file is a single copy if base file name ends in "copy"
  File.basename(filename, ".*").match?(/copy+$/)
end

def update_name_copy(filename)
  ext = File.extname(filename)
  base_name = File.basename(filename, '.*')

  if file_is_multiple_copy?(filename)
    copy_id = base_name.scan(/[0-9]+$/)[0].to_i + 1
    "#{base_name.split(/_copy[0-9]+$/)[0]}_copy#{copy_id}#{ext}"
  elsif file_is_single_copy?(filename)
    "#{base_name}2#{ext}"
  else
    "#{base_name}_copy#{ext}"
  end
end

def username_available?(username)
  load_user_credentials == false ||
    !load_user_credentials.keys.include?(username)
end

def username_taken?(username)
  !(load_user_credentials == false) &&
    load_user_credentials.keys.include?(username)
end

get '/' do
  create_file_list
  create_image_list
  erb :index
end

get '/new' do
  require_signed_in_user

  erb :new
end

post '/create' do
  require_signed_in_user

  if params[:file_name].empty?
    session[:error] = "A name is required."
    status 422
    erb :new
  elsif !ALLOWED_FILE_EXTENSIONS.include?(File.extname(params[:file_name]))
    session[:error] = "The only valid filetypes are #{ALLOWED_FILE_EXTENSIONS}"
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
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:success] = "Welcome!"
    redirect '/'
  else
    session[:error] = "Invalid credentials."
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:username)
  session[:success] = "You have been signed out."
  redirect '/'
end

get '/users/signup' do
  erb :signup
end

post '/users/signup' do
  if params[:username].empty?
    session[:error] = "A name is required."
    status 422
    erb :signup
  elsif params[:password].empty?
    session[:error] = "A password is required."
    status 422
    erb :signup
  elsif username_available?(params[:username])
    write_user_credentials(params[:username], params[:password])
    session[:success] = "User #{params[:username]} created."
    redirect '/'
  elsif username_taken?(params[:username])
    session[:error] = "That username is taken."
    status 422
    erb :signup
  end
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

get '/image/:image_name' do
  file_path = File.join(image_path, params[:image_name])

  if File.exist?(file_path)
    redirect "/images/#{params[:image_name]}"
  else
    session[:error] = "#{params[:image_name]} does not exist."
    redirect '/'
  end
end

post '/image/:image_name/delete' do
  require_signed_in_user

  file_path = File.join(image_path, params[:image_name])

  File.delete(file_path)

  session[:success] = "Image #{params[:image_name]} has been deleted."
  redirect '/'
end

post '/image/upload' do
  require_signed_in_user

  @filename = params[:image_name][:filename]
  file = params[:image_name][:tempfile]

  File.binwrite("#{image_path}/#{@filename}", file.read)
  redirect '/'
end

get '/:file_name/edit' do
  require_signed_in_user
  create_image_list

  file_path = File.join(data_path, params[:file_name])

  @file_name = params[:file_name]
  @content = File.read(file_path)

  erb :edit
end

post '/:file_name' do
  require_signed_in_user

  file_path = File.join(data_path, params[:file_name])

  File.write(file_path, params[:file_content])

  session[:success] = "#{params[:file_name]} has been updated."
  redirect '/'
end

post '/:file_name/delete' do
  require_signed_in_user

  file_path = File.join(data_path, params[:file_name])

  File.delete(file_path)

  session[:success] = "Document #{params[:file_name]} has been deleted."
  redirect '/'
end

post '/:file_name/duplicate' do
  require_signed_in_user

  create_file_list
  file_path = File.join(data_path, update_name_copy(params[:file_name]))
  File.write(file_path, params[:file_content])

  session[:success] = "#{params[:file_name]} has been duplicated."
  redirect '/'
end
