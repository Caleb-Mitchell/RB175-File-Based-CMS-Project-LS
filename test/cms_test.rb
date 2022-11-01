ENV["RACK_ENV"] = "test"

require "fileutils"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMStest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  # rubocop:disable Style/ExpandPathArguments
  def teardown
    FileUtils.rm_rf(data_path)

    file_path = File.join(File.expand_path("../users.yml", __FILE__))
    FileUtils.rm_rf(file_path)
  end
  # rubocop:enable Style/ExpandPathArguments

  # rubocop:disable Style/FileWrite
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  # rubocop:enable Style/FileWrite

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_file_name
    create_document "changes.txt"

    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
  end

  def test_document_not_found
    get "/does_not_exist.txt"

    assert_equal 302, last_response.status
    assert_equal "does_not_exist.txt does not exist.", session[:error]
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..."

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_editing_document
    create_document "changes.txt"

    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<input type="submit"'
  end

  def test_updating_document
    post "/changes.txt", { file_content: "new content" }, admin_session

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:success]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action='/create' method='post'>"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "<input type='submit'"
  end

  def test_create_new_document
    post "/create", { file_name: "test.txt" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "test.txt was created.", session[:success]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    # create document without a name
    post "/create", { file_name: "" }, admin_session

    assert_equal 422, last_response.status

    assert_includes last_response.body, "A name is required."

    get "/" # Reload the page
    # Assert that our message has been removed
    refute_includes last_response.body, "A name is required."
  end

  def test_delete_document
    create_document "file.txt"

    post "/file.txt/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "Document file.txt has been deleted.", session[:success]

    get "/"
    refute_includes last_response.body, 'href="file.txt"'
  end

  def test_view_sign_in
    get "/users/signin"

    assert_equal 200, last_response.status

    assert_includes last_response.body, "<form action='/users/signin'"
    assert_includes last_response.body, "<input type='text'"
    assert_includes last_response.body, "<input type='password'"
    assert_includes last_response.body, "<input type='submit' value='Sign In'>"
  end

  def test_sign_in_success
    post "/users/signup", username: "admin", password: "admin"
    post "/users/signin", username: "admin", password: "admin"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:success]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_sign_in_failure
    post "/users/signin", username: "admin", password: "wrong_password"
    assert_equal 422, last_response.status

    assert_nil session[:signed_in]
    assert_includes last_response.body, "Invalid credentials."
  end

  def test_sign_out
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in as admin"

    post "/users/signout"
    assert_includes "You have been signed out.", session[:success]

    get last_response["Location"]
    assert_nil session[:signed_in]
    assert_includes last_response.body, "Sign In"
  end

  def test_validate_file_extension
    post "/create", { file_name: "test.txt" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "test.txt was created.", session[:success]
  end

  def test_validate_file_extension_failure
    post "/create", { file_name: "test.sh" }, admin_session
    assert_equal 422, last_response.status
    assert_includes last_response.body,
                    "The only valid filetypes are", session[:error]
  end

  def test_duplicate_file
    post "/test.txt/duplicate", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "test.txt has been duplicated.", session[:success]

    get last_response["Location"]
    assert_includes last_response.body, "test_copy.txt"
  end

  def test_duplicating_a_duplicate
    post "/test_copy.txt/duplicate", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "test_copy.txt has been duplicated.", session[:success]

    get last_response["Location"]
    assert_includes last_response.body, "test_copy2.txt"
  end

  def test_duplicating_a_multiple_duplicate
    post "/test_copy54.txt/duplicate", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "test_copy54.txt has been duplicated.", session[:success]

    get last_response["Location"]
    assert_includes last_response.body, "test_copy55.txt"
  end

  def test_view_sign_up_page
    get "/users/signup"
    assert_equal 200, last_response.status
    assert_includes last_response.body,
                    "<form action='/users/signup' method='post'>"
    assert_includes last_response.body, "<input type='submit' value='Sign Up'>"
  end

  def test_create_new_user_success
    post "/users/signup", username: "test", password: "test"
    assert_equal 302, last_response.status
    assert_equal "User test created.", session[:success]
  end

  def test_create_new_user_failure_missing_data
    post "/users/signup", username: "", password: "test"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required."

    post "/users/signup", username: "test", password: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A password is required."
  end

  def test_create_new_user_failure_name_taken
    post "/users/signup", username: "test", password: "test"
    assert_equal 302, last_response.status
    assert_equal "User test created.", session[:success]

    post "/users/signup", username: "test", password: "test"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "That username is taken."
  end
end
