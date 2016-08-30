require 'minitest/autorun'
require 'cerulean'

class Controller
  include Cerulean

  def self.before_action; end

  get :index do
  end
end

class CeruleanTest < Minitest::Test
  def setup
    @controller = Controller.new
  end

  def test_parse_valid_integer
    assert_equal 1, @controller.parse_integer('1')
  end

  def test_parse_invalid_integer
    assert_equal nil, @controller.parse_integer('xxx')
  end

  def test_parse_valid_float
    assert_equal 3.14, @controller.parse_float('3.14')
  end

  def test_parse_invalid_float
    assert_equal nil, @controller.parse_float('xxx')
  end

  def test_parse_valid_boolean
    assert_equal true, @controller.parse_boolean('true')
  end

  def test_parse_invalid_boolean
    assert_equal nil, @controller.parse_boolean('xxx')
  end

  def test_valid_integer_param
    assert_equal 1, @controller.validate_param_type('1', Integer)
  end

  def test_invalid_integer_param
    assert_equal nil, @controller.validate_param_type('xxx', Integer)
  end

  def test_parse_valid_array_of_integers
    assert_equal [1, 2, 3], @controller.validate_param_type(['1', '2', '3'], Array[Integer])
  end

  def test_parse_valid_array_of_integers
    assert_equal nil, @controller.validate_param_type(['1', 'xxx', '3'], Array[Integer])
  end

  #def test_validate_valid_integer_param
  #  assert_equal 1, Controller.new.validate_param_type('1', Integer)
  #end

  #def test_validate_invalid_integer_param
  #  assert_equal false, Controller.new.validate_param_type('xxx', Integer)
  #end
end