module CarrierSeeds
  def self.create_all_for_cf!
    create_all_for!(company: CargofluxCompany.find!)
  end

  def self.create_all_for!(company:)
    DAOSeeds.create_for!(company: company)
    TNTSeeds.create_for!(company: company)
    DHLSeeds.create_for!(company: company)
    GLSSeeds.create_for!(company: company)
    UPSSeeds.create_for!(company: company)
    UnifaunSeeds.create_for!(company: company)
    UnifaunNorwaySeeds.create_for!(company: company)
    FedExSeeds.create_for!(company: company)
    DSVSeeds.create_for!(company: company)
    KHTSeeds.create_for!(company: company)
    BringSeeds.create_for!(company: company)
  end

  class BaseCarrierSeeds
    attr_reader :company

    class << self
      def create_for!(company:)
        new(company: company).create!
      end
    end

    def initialize(company:)
      @company = company
    end

    def create!
      ActiveRecord::Base.transaction { create_without_transaction! }
    end

    def create_without_transaction
      raise "define in subclass"
    end
  end

  class DAOSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = DAOCarrier.create_with(name: "DAO").find_or_create_by!(company: company)

      DAODirektCarrierProduct.create_with(product_code: "daodc", product_type: "", is_enabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "DAO Direkt")
      DAOPakkeshopCarrierProduct.create_with(product_code: "daopc", product_type: "", is_enabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "DAO Pakkeshop")
    end
  end

  class TNTSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = TNTCarrier.create_with(name: "TNT").find_or_create_by!(company: company)

      TNTDomesticCarrierProduct         .create_with(product_code: "tntdo",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "TNT Domestic")
      TNTEconomyCarrierProduct          .create_with(product_code: "tntec",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "TNT Economy")
      TNTEconomyImportCarrierProduct    .create_with(product_code: "tntecoi", product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "TNT Economy Import")
      TNTExpressCarrierProduct          .create_with(product_code: "tntex",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "TNT Express")
      TNTExpressDocumentCarrierProduct  .create_with(product_code: "tntexd",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-2 days").find_or_create_by!(company: company, carrier: carrier, name: "TNT Express Document")
      TNTExpressImportCarrierProduct    .create_with(product_code: "tntexi",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "TNT Express Import")
    end
  end

  class DHLSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = DHLCarrier.create_with(name: "DHL").find_or_create_by!(company: company)

      DHLEconomyCarrierProduct                .create_with(product_code: "dhlec",    product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL Economy")
      DHLEconomyDocumentCarrierProduct        .create_with(product_code: "dhlecd",   product_type: "courier_express", is_disabled: true,  state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL Economy Document")
      DHLEconomyDocumentImportCarrierProduct  .create_with(product_code: "dhlecdi",  product_type: "courier_express", is_disabled: true,  state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL Economy Document Import")
      DHLEconomyImportCarrierProduct          .create_with(product_code: "dhleci",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Economy Import")
      DHLExpressCarrierProduct                .create_with(product_code: "dhlex",    product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL Express")
      DHLExpressBefore9CarrierProduct         .create_with(product_code: "dhlex-9",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express 9:00")
      DHLExpressBefore12CarrierProduct        .create_with(product_code: "dhlex-12", product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express 12:00")
      DHLExpressDocumentCarrierProduct        .create_with(product_code: "dhlexd",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Document")
      DHLExpressDocumentImportCarrierProduct  .create_with(product_code: "dhlexdi",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Document Import")
      DHLExpressDomesticCarrierProduct        .create_with(product_code: "dhlexdom", product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Domestic")
      DHLExpressEnvelopeCarrierProduct        .create_with(product_code: "dhlexe",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Envelope")
      DHLExpressEnvelopeImportCarrierProduct  .create_with(product_code: "dhlexei",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Envelope Import")
      DHLExpressCarrierProduct                .create_with(product_code: nil,        product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL 3. part")
      DHLExpressImportCarrierProduct          .create_with(product_code: "dhlexi",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "DHL Express Import")
    end
  end

  class GLSSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = GLSCarrier.create_with(name: "GLS").find_or_create_by!(company: company)

      GLSBusinessCarrierProduct    .create_with(product_code: "glsb",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "GLS Business")
      GLSPakkeshopCarrierProduct   .create_with(product_code: "glsp",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "GLS Pakkeshop")
      GLSPrivateCarrierProduct     .create_with(product_code: "glspri", product_type: nil,               is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-2 days").find_or_create_by!(company: company, carrier: carrier, name: "GLS Private")
      GLSShopReturnCarrierProduct  .create_with(product_code: nil,      product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "GLS ShopReturn")
    end
  end

  class UPSSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = UPSCarrier.create_with(name: "UPS").find_or_create_by!(company: company)

      UPSExpressCarrierProduct               .create_with(product_code: "upsex",    product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express")
      UPSSaverCarrierProduct                 .create_with(product_code: "upssr",    product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver")
      UPSSaverDocumentCarrierProduct         .create_with(product_code: nil,        product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Document")
      UPSExpeditedImportCarrierProduct       .create_with(product_code: "upsexdi",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "4-6 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Expedited Import")
      UPSSaverImportCarrierProduct           .create_with(product_code: "upssri",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Import")
      UPSStandardSingleCarrierProduct        .create_with(product_code: "upsstsp",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Standard (Single Package)")
      UPSExpeditedCarrierProduct             .create_with(product_code: "upsexd",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "4-6 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Expedited")
      UPSStandardImportCarrierProduct        .create_with(product_code: "upssti",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Standard Import")
      UPSStandardCarrierProduct              .create_with(product_code: "upsst",    product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Standard")
      UPSStandardImportSingleCarrierProduct  .create_with(product_code: "upsstspi", product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Standard Import (Single Package)")
      UPSExpressImportCarrierProduct         .create_with(product_code: "upsexi",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Import")
      UPSSaverDomesticCarrierProduct         .create_with(product_code: "upssr_d",  product_type: "courier_express", is_disabled: true,  state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Domestic")
      UPSSaverEnvelopeCarrierProduct         .create_with(product_code: nil,        product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Envelope")
      UPSSaverReturnService1CarrierProduct   .create_with(product_code: nil,        product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Import 1-Pickup-Attempt")
      UPSSaverReturnService3CarrierProduct   .create_with(product_code: nil,        product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "UPS Express Saver Import 3-Pickup-Attempt")
    end
  end

  class UnifaunSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = UnifaunCarrier.create_with(name: "PostNord").find_or_create_by!(company: company)

      UnifaunDPDClassicCarrierProduct                   .create_with(product_code: "pndpdc",   is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-5 days").find_or_create_by!(company: company, carrier: carrier, name: "PostNord DPD Classic")
      UnifaunCustomerReturnOutsideNordicCarrierProduct  .create_with(product_code: "pncronc",  is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Customer Return (Outside Nordic Countries)")
      UnifaunGroupageCarrierProduct                     .create_with(product_code: "pdk83",    is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord DK Groupage")
      UnifaunMypackCollectNorwayCarrierProduct          .create_with(product_code: "pnmcnor",  is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord MyPack Collect (Norway)")
      UnifaunBusinessPackageCarrierProduct              .create_with(product_code: "pne",      is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Erhvervspakke")
      UnifaunPrivatePriorityCarrierProduct              .create_with(product_code: "pnpp",     is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Private Priority")
      UnifaunMypackCollectCarrierProduct                .create_with(product_code: "pnmc",     is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord MyPack Collect")
      UnifaunMypackHomeCarrierProduct                   .create_with(product_code: "pnmh",     is_disabled: false, state: "unlocked_for_configuring", transit_time: "1 day"   ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord MyPack Home")
      UnifaunBusinessPrioritySingleCarrierProduct       .create_with(product_code: "pnbps",    is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Business Priority (Single)")
      UnifaunParcelEconomyCarrierProduct                .create_with(product_code: "pnpe",     is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Parcel Economy")
      UnifaunCustomerReturnPickupCarrierProduct         .create_with(product_code: "pncrp",    is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Customer Return Pickup")
      UnifaunCustomerReturnCarrierProduct               .create_with(product_code: "pncr",     is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Customer Return")
      UnifaunMypackCollectOutsideNordicCarrierProduct   .create_with(product_code: "pnmconc",  is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord MyPack Collect (Outside Nordic Countries)")
      UnifaunPalletCarrierProduct                       .create_with(product_code: nil,        is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "PostNord DK Pallet")
    end
  end

  class UnifaunNorwaySeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = UnifaunNorwayCarrier.create_with(name: "PostNord NO").find_or_create_by!(company: company)

      UnifaunPalletNorwayCarrierProduct.create_with(product_code: nil, is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Pallet NO")
      UnifaunGroupageNorwayCarrierProduct.create_with(product_code: nil, is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "PostNord Groupage NO")
    end
  end

  class FedExSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = FedExCarrier.create_with(name: "FedEx").find_or_create_by!(company: company)

      FedExInternationalPriorityFreightCarrierProduct  .create_with(product_code: "fdxprifre",  is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "FedEx International Priority Freight")
      FedExInternationalPriorityCarrierProduct         .create_with(product_code: "fdxprio",    is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "FedEx International Priority")
      FedExInternationalPriorityDocumentCarrierProduct .create_with(product_code: "fdxprio-d",  is_disabled: false, state: "unlocked_for_configuring", transit_time: "1-3 days").find_or_create_by!(company: company, carrier: carrier, name: "FedEx International Priority Document")
      FedExInternationalEconomyCarrierProduct          .create_with(product_code: "fdxeco",     is_disabled: false, state: "unlocked_for_configuring", transit_time: "2-6 days").find_or_create_by!(company: company, carrier: carrier, name: "FedEx International Economy")
      FedExPriorityOvernightUSACarrierProduct          .create_with(product_code: "fdxpo-us",   is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "FedEx Priority Overnight US")
      FedExStandardOvernightUSACarrierProduct          .create_with(product_code: "fdxso-us",   is_disabled: false, state: "unlocked_for_configuring", transit_time: nil       ).find_or_create_by!(company: company, carrier: carrier, name: "FedEx Standard Overnight US")
    end
  end

  class BringSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = BringCarrier.create_with(name: "Bring").find_or_create_by!(company: company)

      BringBpakkeCarrierProduct              .create_with(product_code: "bbp",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring BPakkke")
      BringExpressCarrierProduct             .create_with(product_code: "be09",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Express 09")
      BringCarryonHomeBulkHomeCarrierProduct .create_with(product_code: "bchbh", product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Carryon Home BulkHome")
      BringCarryonBusinessCarrierProduct     .create_with(product_code: "bcb",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Carryon Business")
      BringCarryonHomeCarrierProduct         .create_with(product_code: "bch",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Carryon Home")
      BringServicePackageCarrierProduct      .create_with(product_code: "bsp",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Servicepakke")
      BringCarryonHomeBulkCarrierProduct     .create_with(product_code: "bchb",  product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Carryon Home Bulk")
      BringPickupParcelCarrierProduct        .create_with(product_code: "bpp",   product_type: "courier_express", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "Bring Pickup Parcel")
    end
  end

  class DSVSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = DSVCarrier.create_with(name: "DSV").find_or_create_by!(company: company)

      DSVRoadGroupageCarrierProduct.create_with(product_code: "dsv-r-g", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "DSV Road Groupage")
      DSVDanpackCarrierProduct.create_with(product_code: "dsv-dp", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "DSV Danpack")
      DSVXpressCarrierProduct.create_with(product_code: "dsv-x", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "DSV Xpress")
    end
  end

  class KHTSeeds < BaseCarrierSeeds
    def create_without_transaction!
      carrier = KHTCarrier.create_with(name: "KHT").find_or_create_by!(company: company)

      KHTDefaultCarrierProduct.create_with(product_code: "kht-pd", is_disabled: false, state: "unlocked_for_configuring", transit_time: nil).find_or_create_by!(company: company, carrier: carrier, name: "KHT PD")
    end
  end
end
