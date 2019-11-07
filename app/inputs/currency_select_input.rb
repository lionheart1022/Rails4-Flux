class CurrencySelectInput < SimpleForm::Inputs::CollectionSelectInput
  self.default_options = {
    collection: Money::Currency.table.map { |_, currency| ["#{currency[:name]} (#{currency[:iso_code]})", currency[:iso_code]] },
  }
end
