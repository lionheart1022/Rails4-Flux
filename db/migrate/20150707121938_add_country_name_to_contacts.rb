class AddCountryNameToContacts < ActiveRecord::Migration
  def up
    add_column :contacts, :country_name, :string

    Contact.all.each do |contact|
      next if contact.country_code.blank?

      country = Country.find_country_by_alpha2(contact.country_code)
      raise StandardError.new("Country code not recognized: #{contact.country_code}") if country.nil?

      contact.country_name = country.name
      contact.save!
    end
  end

  def down
    remove_column :contacts, :country_name
  end
end
