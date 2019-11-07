class AddTypeToCarriers < ActiveRecord::Migration
  def up
    add_column :carriers, :type, :string

    Carrier.all.each do |carrier|
      name = carrier.name
      case name
      when 'DHL'
        carrier.type = DHLCarrier
      when 'TNT'
        carrier.type = TNTCarrier
      when 'Pacsoft'
        carrier.type = PacsoftCarrier
      when 'UPS'
        carrier.type = UPSCarrier
      when 'DAO'
        carrier.type = DAOCarrier
      when 'GLS'
        carrier.type = GLSCarrier
      when 'Bring'
        carrier.type = BringCarrier
      end

      carrier.save!
    end
  end

  def down
    remove_column :carriers, :type
  end
end
