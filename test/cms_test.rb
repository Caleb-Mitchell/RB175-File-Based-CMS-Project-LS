ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMStest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_file_name
    get "/about.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "ruby history and changes."
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
end
