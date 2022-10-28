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

  def teardown
    FileUtils.rm_rf(data_path)
  end

  # rubocop:disable Style/FileWrite
  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end
  # rubocop:enable Style/FileWrite

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
    create_document "/changes.txt"

    get "/changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
  end

  def test_document_does_not_exist
    get "/does_not_exist.txt"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "does_not_exist.txt does not exist"

    get "/" # Reload the page
    # Assert that our message has been removed
    refute_includes last_response.body, "does_not_exist.txt does not exist"
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..."

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_editing_document
    create_document "/changes.txt"

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<input type="submit"'
  end

  def test_updating_document
    post "/changes.txt", file_content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<form action='/create' method='post'>"
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, "<input type='submit'"
  end

  def test_create_new_document
    post "/create", file_name: "file.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "file.txt was created."

    get "/" # Reload the page
    # Assert that our message has been removed
    refute_includes last_response.body, "file.txt was created."
  end

  def test_create_new_document_without_filename
    # create document without a name
    post "/create", file_name: ""

    assert_equal 422, last_response.status

    assert_includes last_response.body, "A name is required."

    get "/" # Reload the page
    # Assert that our message has been removed
    refute_includes last_response.body, "A name is required."
  end

  def test_delete_document
    create_document "file.txt"
    post "/file.txt/delete"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "file.txt has been deleted."

    get "/" # Reload the page
    # Assert that our file has been deleted
    refute_includes last_response.body, "file.txt"
  end
end
