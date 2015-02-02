require 'test_helper'

class RootTest < AppTest
  def test_get_root
    get '/'
    assert_equal 200, last_response.status
  end
end
