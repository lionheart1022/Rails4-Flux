Cargoflux Company v1 API
========================

Authentication
--------------

The Cargoflux API requires the user to authenticate each request with an API access token.
This token can be generated under the 'API Access' tab once logged into Cargoflux.

### Token in URL parameter

The token can be included as a URL parameter by setting the `access_token` parameter.

### Token in HTTP header

Another way to provide the token is via a HTTP header by setting the `Access-Token` header.

### Token in JSON body

As part of the JSON body (for non-GET requests) you can also provide the token by setting the `access_token` key in the root JSON-element.

Base URI
--------

Environment | Base URI
:---------- | :---
production | `https://api.cargoflux.com`

API endpoints
-------------

*Note*:

C: conditional, some carriers may require this field or it may depend on another field.

### Get Shipment

- `GET /api/v1/companies/shipments/:shipment_id` returns detailed shipment data.

###### Example response

```json
{
  "id": "3-1-1163",
  "state": "booked",
  "awb": "1ZA1R6477353",
  "awb_link": "https://cargoflux.s3.amazonaws.com/assets/000/001/040/f561f892-ee58-41f3-9977-05bdbe512441.pdf?1462359686",
  "shipping_date": "2016-05-16",
  "description": "some description",
  "reference": "some customer ref",
  "remarks": "",
  "carrier_product": "UPS Express",
  "dutiable": false,
  "cost_price_amount": "379.2048",
  "cost_price_currency": "DKK",
  "sales_price_amount": "417.12528",
  "sales_price_currency": "DKK",
  "price_lines": [
    {
      "line_description": "Shipment charge",
      "line_cost_price": "23.0",
      "line_sales_price": "23.0",
      "line_quantity": 1
    },
    {
      "line_description": "Fuel charge",
      "line_cost_price": "2.07",
      "line_sales_price": "2.07",
      "line_quantity": 1
    }
  ],
  "package_dimensions": [
    {
      "height": 10,
      "length": 10,
      "width": 10,
      "weight": 5,
      "volume_weight": 0.2,
      "amount": 2,
      "goods_identifier": "CLL"
    },
    {
      "height": 2,
      "length": 5,
      "width": 2,
      "weight": 2,
      "volume_weight": 0.004,
      "amount": 1,
      "goods_identifier": "CLL"
    }
  ],
  "sender": {
    "company_name": "some company",
    "address_line1": "some street",
    "address_line2": "",
    "address_line3": "",
    "city": "Copenhagen",
    "zip_code": "2300",
    "country_name": "Denmark",
    "country_code": "dk",
    "phone_number": "33333333",
    "email": "example@gmail.com",
    "attention": "Jack ads"
  },
  "recipient": {
    "company_name": "Some other company",
    "address_line1": "some other street",
    "address_line2": "",
    "address_line3": "",
    "city": "Berlin",
    "zip_code": "23001",
    "country_name": "Germany",
    "country_code": "de",
    "phone_number": "44444444",
    "email": "otherexample@gmail.com",
    "attention": "Georg asdae"
  }
}
```

### List Shipments

- `GET /api/v1/companies/shipments.xml` retrieves a paginated list of shipments.

#### Query parameters

Req?  | Field | Type   | Description
:---: | :---  | :---   | :---
|     | page  | String | Page offset to fetch shipments from (default 1)

###### Example

    https://api.cargoflux.com/api/v1/companies/shipments.xml?page=2

#### Response

Field | Description
:--- | :---
CustomerID | CargoFlux id of the customer who booked the shipment
CustomerExternalAccountingNumber | External accounting number of the customer who booked the shipment
ShipmentId | CargoFlux shipment id
State | CargoFlux shipment state
ShippingDate | Date of shipping (format: `YYYY-MM-DD`)
CustomsAmount | Customs amount
CustomsCurrency | Customs currency
Description | Description of shipment
AWB | AWB Number
NumberOfPackages | Number of packages sent with the shipment
TotalWeight | Total weight of the shipment (kg)
TotalVolumeWeight | Total volume weight of the shipment
CustomerReference | Customer reference field
Remarks | Customer remarks
DeliveryInstructions | delivery instructions
VATIncluded | The shipment includes VAT (`true` or `false`)
Carrier | The carrier the shipment was booked through
CarrierProduct | Name of the product the shipment was booked with
CarrierProductCode | Product code of the product the shipment was booked with
CarrierProductDetails/VolumeWeightType | Possible values: `volume_weight`, `loading_meter`
CarrierProductDetails/Basis | Possible values: `weight`, `distance`
ParcelshopId | The ID of the parcelshop if specified when booked

A pricing element is included if a price has been specified for the shipment. Returns the total cost and sales price for the shipment

Field | Description
:---  | :---
Pricing/CostPriceAmount | Original cost of shipment
Pricing/SalesPriceAmount | The sales price of the shipment
Pricing/CostPriceCurrency | Currency of original price
Pricing/SalesPriceCurrency | Currency of sales price

A pricing items element is included if a price has been specified for the shipment. Returns the individual pricing items

Field | Description
:---  | :---
PriceLines/PriceLine/LineDescription | Description of price item
PriceLines/PriceLine/LineCostPrice | The cost price of the price item
PriceLines/PriceLine/LineSalesPrice | The sales price of the price item
PriceLines/PriceLine/LineQuantity | How many times the price item is applied in the total calculation

The Sender and Recipient both conform to the format specified below

Field | Description
:---  | :---
Sender/CompanyName | Name of company
Sender/AddressLine1 |
Sender/AddressLine2 |
Sender/AddressLine3 |
Sender/City |
Sender/ZipCode |
Sender/StateCode | State code if country has different states
Sender/CountryName |
Sender/CountryCode |
Sender/Phone | Contact phone number
Sender/Email | Contact email
Sender/Attention | Name of contact person

Structure of PackageList is as described below

Field | Description
:---  | :---
PackageList/Package/Length | Length of package (cm)
PackageList/Package/Width | Width of package (cm)
PackageList/Package/Height | Height of package (cm)
PackageList/Package/Weight | Weight of package (kg)
PackageList/Package/VolumeWeight | Volumeweight of package
PackageList/Package/Quantity | Number of packages sent with specified dimensions
PackageList/Package/GoodsIdentifier | Identifies type/unit of package (possible values: `CLL`, `PLL`, `HPL`, `QPL`)

###### Example

```xml
<ShipmentList>
  <Shipment>
    <CustomerID>3</CustomerID>
    <CustomerExternalAccountingNumber>xxxxx</CustomerExternalAccountingNumber>
    <ShipmentId>3-1-1439</ShipmentId>
    <State>booked</State>
    <ShippingDate>2015-10-21</ShippingDate>
    <TotalWeight>10.0</TotalWeight>
    <TotalVolumeWeight>0.25</TotalVolumeWeight>
    <CustomsAmount>10.0</CustomsAmount>
    <CustomsCurrency>DKK</CustomsCurrency>
    <Description>some shipment description</Description>
    <AWB>YO9M9D</AWB>
    <NumberOfPackages>2</NumberOfPackages>
    <CustomerReference>Some customer reference</CustomerReference>
    <Remarks>some customer supplied remarks</Remarks>
    <DeliveryInstructions>delivery instructions</DeliveryInstructions>
    <VATIncluded>true</VATIncluded>
    <Carrier>UPS</Carrier>
    <CarrierProduct>UPS Standard</CarrierProduct>
    <Pricing>
      <CostPriceAmount>147.15</CostPriceAmount>
      <SalesPriceAmount>161.86</SalesPriceAmount>
      <CostPriceCurrency>DKK</CostPriceCurrency>
      <SalesPriceCurrency>DKK</SalesPriceCurrency>
    </Pricing>
    <PriceLines>
      <PriceLine>
        <LineDescription>Shipment charge</LineDescription>
        <LineCostPrice>23.0</LineCostPrice>
        <LineSalesPrice>23.0</LineSalesPrice>
        <LineQuantity>1</LineQuantity>
      </PriceLine>
      <PriceLine>
        <LineDescription>Fuel charge</LineDescription>
        <LineCostPrice>2.07</LineCostPrice>
        <LineSalesPrice>2.07</LineSalesPrice>
        <LineQuantity>1</LineQuantity>
      </PriceLine>
    </PriceLines>
    <Sender>
      <CompanyName>SomeCompanyNmae</CompanyName>
      <AddressLine1>Gothersgade 813</AddressLine1>
      <AddressLine2/>
      <AddressLine3/>
      <City>København</City>
      <ZipCode>1123</ZipCode>
      <CountryName>Denmark</CountryName>
      <CountryCode>dk</CountryCode>
      <Phone/>
      <Email>example@example.com</Email>
      <Attention>Karlmar</Attention>
    </Sender>
    <Recipient>
      <CompanyName>OnlineShop</CompanyName>
      <AddressLine1>Kongens Nytorv 242</AddressLine1>
      <AddressLine2/>
      <AddressLine3/>
      <City>København K</City>
      <ZipCode>1050</ZipCode>
      <CountryName>Denmark</CountryName>
      <CountryCode>dk</CountryCode>
      <Phone/>
      <Email/>
      <Attention>Mads</Attention>
    </Recipient>
    <PackageList>
      <Package>
        <Length>10</Length>
        <Width>10</Width>
        <Height>10</Height>
        <Weight>5.0</Weight>
        <VolumeWeight>0</VolumeWeight>
        <Quantity>1</Quantity>
        <GoodsIdentifier>CLL</GoodsIdentifier>
      </Package>
      <Package>
        <Length>10</Length>
        <Width>10</Width>
        <Height>10</Height>
        <Weight>5.0</Weight>
        <VolumeWeight>0</VolumeWeight>
        <Quantity>2</Quantity>
        <GoodsIdentifier>CLL</GoodsIdentifier>
      </Package>
    </PackageList>
  </Shipment>
  <!-- ... -->
</ShipmentList>
```

### Export Shipments

- `POST /api/v1/companies/shipment_exports.xml` retrieves a list of all shipments scheduled for export.

Calling this endpoint will label any shipment returned as `exported`. An exported shipment will no longer appear in subsequent responses, unless its data has changed since the initial export. If an exported shipment's data has changed, it will appear under the `UpdatedShipments` node in the next response.

In the CargoFlux admin interface under 'Export Settings', you can control which shipment state changes will schedule a shipment for export.

For example, you may create a setup in which a shipment will be scheduled for export as soon as its state changes to `booked`. This allows companies using third-party systems to maintain an always up-to-date list of shipments.

#### Response

Field | Description
:---  | :---
NewShipments | A list of shipments scheduled for export
UpdatedShipments | A list of shipments that has changed since their initial export.
Shipment | Same schema as in `List Shipments`

##### Example Response

```xml
<ShipmentList>
  <NewShipments>
    <Shipment><!-- ... --></Shipment>
    <Shipment><!-- ... --></Shipment>
    <!-- ... -->
  </NewShipments>
  <UpdatedShipments>
    <Shipment><!-- ... --></Shipment>
    <Shipment><!-- ... --></Shipment>
    <!-- ... -->
  </UpdatedShipments>
</ShipmentList>
```

### Export Shipments Archive

- `GET /api/v1/companies/shipment_exports.xml?since=:timestamp` returns previous shipment exports.

The response will consist of a series of `<ShipmentList></ShipmentList>`, similar to what is returned by `POST /api/v1/companies/shipment_exports.xml`.

At most 50 previous exports will be returned - you can retrieve more by making a new request with an updated `since` query-parameter.

#### Example request

    GET /api/v1/companies/shipment_exports.xml?since=2017-02-01+10%3A00%3A00+%2B0100 # 2017-02-01 10:00:00 +0100

#### Example response

```xml
<ShipmentLists>
  <ShipmentList timestamp="2017-02-02 09:00:00 UTC">
    <NewShipments>
      <Shipment><!-- ... --></Shipment>
      <Shipment><!-- ... --></Shipment>
      <!-- ... -->
    </NewShipments>
    <UpdatedShipments>
      <Shipment><!-- ... --></Shipment>
      <Shipment><!-- ... --></Shipment>
      <!-- ... -->
    </UpdatedShipments>
  </ShipmentList>

  <ShipmentList timestamp="2017-02-03 09:00:00 UTC">
    <NewShipments>
      <Shipment><!-- ... --></Shipment>
      <Shipment><!-- ... --></Shipment>
      <!-- ... -->
    </NewShipments>
    <UpdatedShipments>
      <Shipment><!-- ... --></Shipment>
      <Shipment><!-- ... --></Shipment>
      <!-- ... -->
    </UpdatedShipments>
  </ShipmentList>

  <!-- ... -->
</ShipmentLists>
```

### Update Shipments

- `POST /api/v1/companies/shipment_updates` updates shipments.

#### Request parameters

- `updates` - Array of updates. Max # of updates is 100.
    - `shipment_id` - **(required)** ID of shipment in the format `1-1-1`.
    - `state_change` - *(optional)* Set this object when you need to change the state of a shipment.
        - `new_state` - Set this to change the shipment to a new state. This field is **required** when you need to change the state.

          Allowed values are `booked`, `in_transit`, `delivered_at_destination`, `problem`, `cancelled`
        - `comment` - An optional, supplementary comment related to the state change.
        - `awb` - Sets the shipment AWB. This is only considered when `new_state` is set to `booked`.
    - `upload_label_from_url` - *(optional)* Upload label to CargoFlux from the given URL. This should preferably be a PDF.
    - `upload_invoice_from_url` - *(optional)* Upload invoice to CargoFlux from the given URL.
    - `upload_consignment_note_from_url` - *(optional)* Upload consignment note to CargoFlux from the given URL.

###### Example JSON request

```json
{
  "updates": [
    {
      "shipment_id": "1-1-1",
      "state_change": {
        "new_state": "booked",
        "comment": "",
        "awb": "XXX"
      },
      "upload_label_from_url": "https://www.example.com/label.pdf"
    },
    {
      "shipment_id": "1-1-2",
      "state_change": {
        "new_state": "in_transit",
        "comment": "Picked up by Bob the Driver"
      }
    },
    {
      "shipment_id": "1-1-3",
      "state_change": {
        "new_state": "problem",
        "comment": "Booking error: recipient zip code is invalid"
      }
    },
    {
      "shipment_id": "1-1-4",
      "upload_invoice_from_url": "https://www.example.com/invoice.pdf"
    }
  ]
}
```

#### Response

This endpoint will return `200 OK` with the following JSON response *if* the request is properly structured.

###### Example JSON response - `200 OK`

```json
{
  "shipments": [
    {
      "shipment_id": "1-1-1",
      "awb": "XXX",
      "state": "booked"
    },
    {
      "shipment_id": "1-1-2",
      "awb": "YYY",
      "state": "in_transit"
    },
    {
      "shipment_id": "1-1-3",
      "awb": null,
      "state": "problem"
    },
    {
      "shipment_id": "1-1-4",
      "awb": "ZZZ",
      "state": "booked"
    }
  ]
}
```

###### Example JSON response - `400 Bad Request`

If max number of updates is exceeded:

```json
{ "error" : "max number of updates (100) was exceeded (actual # of updates: 101)" }
```
