# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
  inflect.acronym 'EU'
  inflect.acronym 'USA'
  inflect.acronym 'UPS'
  inflect.acronym 'HTTP'
  inflect.acronym 'FTP'
  inflect.acronym 'CF'
  inflect.acronym 'EOD'
  inflect.acronym 'GLS'
  inflect.acronym 'DSV'
  inflect.acronym 'GS1'
  inflect.acronym 'KHT'
  # inflect.plural /^(ox)$/i, '\1en'
  # inflect.singular /^(ox)en/i, '\1'
  # inflect.irregular 'person', 'people'
  # inflect.uncountable %w( fish sheep )
end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
