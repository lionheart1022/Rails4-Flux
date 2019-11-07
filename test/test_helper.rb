ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/rails'
require "support/test_price_documents"

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  #
  #
  # Price calculation
  ERROR_MARGIN = 0.01

  def parser
    ExcelToPriceDocumentParser.new
  end

  def assert_in_error_margin_delta(exp, act, delta = ERROR_MARGIN)
    assert_in_delta exp, act, delta
  end

  def select_fatal_errors(parsing_errors: nil)
    parsing_errors.select {|pe| pe.severity ==  PriceDocumentV1::ParseError::Severity::FATAL }
  end

end
