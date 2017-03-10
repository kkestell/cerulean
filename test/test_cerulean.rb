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

  def test_valid_integer_param
    assert_equal 1, @controller.validate_param_type('1', Integer)
  end

  def test_invalid_integer_param
    assert_equal nil, @controller.validate_param_type('xxx', Integer)
  end

  def test_valid_float_param
    assert_equal 3.14, @controller.validate_param_type('3.14', Float)
  end

  def test_invalid_float_param
    assert_equal nil, @controller.validate_param_type('xxx', Float)
  end

  def test_valid_boolean_param
    assert_equal true, @controller.validate_param_type('true', Boolean)
  end

  def test_invalid_boolean_param
    assert_equal nil, @controller.validate_param_type('xxx', Float)
  end

  def test_valid_date_param
    assert_equal true, @controller.validate_param_type('2017-01-01', Date)
  end

  def test_invalid_date_param
    assert_equal nil, @controller.validate_param_type('xxx', Date)
  end

  def test_valid_datetime_param
    assert_equal true, @controller.validate_param_type('2017-01-01 12:00:00', DateTime)
  end

  def test_invalid_datetime_param
    assert_equal nil, @controller.validate_param_type('xxx', DateTime)
  end

  def test_parse_valid_array_of_integers
    assert_equal [1, 2, 3], @controller.validate_param_type(['1', '2', '3'], Array[Integer])
  end

  def test_parse_invalid_array_of_integers
    assert_equal nil, @controller.validate_param_type(['1', 'xxx', '3'], Array[Integer])
  end

  def test_parse_valid_array_of_floats
    assert_equal [1.0, 2.0, 3.0], @controller.validate_param_type(['1.0', '2.0', '3.0'], Array[Float])
  end

  def test_parse_invalid_array_of_integers
    assert_equal nil, @controller.validate_param_type(['1.0', 'xxx', '3.0'], Array[Float])
  end

  def test_parse_valid_array_of_booleans
    assert_equal [true, false, true], @controller.validate_param_type(['true', 'false', 'true'], Array[Boolean])
  end

  def test_parse_invalid_array_of_booleans
    assert_equal nil, @controller.validate_param_type(['true', 'xxx', 'true'], Array[Boolean])
  end
end