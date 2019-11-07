Cargoflux Customer v1 API
=========================

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

JSON
----

We use JSON for all API data. This means that you have to send the `Content-Type` header `Content-Type: application/json; charset=utf-8` when you're POSTing or PUTing data into Cargoflux.

API endpoints
-------------

### Get Shipment

- `GET /api/v1/customers/shipment/:shipment_id` returns detailed shipment data.

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
  "product_code": "upsex",
  "dutiable": false,
  "price": "417.12528",
  "currency": "DKK",
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

### Book Shipment

- `POST /api/v1/customers/shipments` books shipments through the Cargoflux platform.

To request a shipment booking, the following steps must be taken

1. The user sends an initial request with an `access_token` and a `callback_url` along with the additional parameters as described below.
2. Cargoflux performs initial validations and sends a response with the state of the booking request.
3. Once the booking request has been processed, Cargoflux will send a new request to the `callback_url` specified in (1). This request documents the final status of the booking. Further, if the booking failed, a list of errors will be attached.

#### Request parameters

###### Notes

A "C" in the "Req?" column indicates that the parameter is *conditional* - some carriers may require this field or it may depend on another field.

###### Meta parameters

Req?  | Field | Type | Description
:---: | :--- | :--- | :---
\*    | access_token | String | API access token
\*    | callback_url | String | URL to which Cargoflux will send a `POST` request to upon booking completion or errors . The URL must be reachable from the web.
|     | default_sender | Boolean | If true, the company address associated with the API token will be used as Sender. If this flag is set, the Sender should not be sent in the API request.

###### Shipment parameters

Req?  | Field | Type | Description
:---: | :--- | :--- | :---
\*    | shipping_date | String | Date of shipping (format: `YYYY-MM-DD`)
\*    | product_code | String | Cargoflux product code. These will be supplied by your CargoFlux contact.
|     | parcelshop_id | String | If specified and possible, the shipment will be sent to the the selected parcelshop. If not specified, the system will attempt to determine the closest parcelshop based off the recipient's address and use this instead.
|     | return_label | Boolean | If true, a return shipment will be booked instead
\*    | package_dimensions | Array | Array of dimension objects for each package being shipped. Each object must specify `width`, `height`, `length`, `weight` and `amount`
\*    | package_dimensions/width | String | Width of package (kg)
\*    | package_dimensions/height | String | Height of package (cm)
\*    | package_dimensions/length | String | Length of package (cm)
\*    | package_dimensions/weight | String | Weight of package (cm)
\*    | package_dimensions/amount | String | The number of packages being sent in the shipment of the specified dimensions
|     | package_dimensions/goods\_identifier | String | Identifies type/unit of package (possible values: `CLL` (default), `PLL`, `HPL`, `QPL`)
|     | number\_of\_pallets | Integer | The number of pallets needed for the shipment
\*    | dutiable | Boolean | Whether the shipment is dutiable
C     | customs_amount | String | Customs amount. This field is required if the shipment is dutiable
C     | customs_currency | String | ISO-4217 compliant currency code. This field is required if the shipment is dutiable
C     | customs_code | String | The customs code. This field is required if the shipment is dutiable
\*    | description | String | Description of the shipment
|     | reference | String | Customer specified reference
|     | remarks | String | Customer specified remarks
|     | delivery_instructions | String | Customer specified delivery instructions
|     | dgr | Object | Dangerous goods
|     | dgr/enabled | Boolean | Indicates that the shipment contains dangerous goods
|     | dgr/identifier | String | See supported values in the last part of the documentation in the "DGR" section
|     | pickup | Object | Pickup
|     | pickup/enabled | Boolean | Indicates that a pickup for the shipment should be booked
|     | pickup/from_time | String | The from-time the shipment can be picked up at. Formatted as "HH:MM" (e.g. "08:00", "13:00")
|     | pickup/to_time | String | The to-time the shipment can be picked up at. Formatted as "HH:MM" (e.g. "08:00", "13:00")
|     | pickup/description | String | This field is mandatory for DHL shipments (e.g. "Warehouse")
|     | pickup/company_name | String | Defaults to the contact info of the customer creating the request
|     | pickup/attention | String | Defaults to the contact info of the customer creating the request
|     | pickup/address_line1 | String | Defaults to the contact info of the customer creating the request
|     | pickup/address_line2 | String | Defaults to the contact info of the customer creating the request
|     | pickup/address_line3 | String | Defaults to the contact info of the customer creating the request
|     | pickup/country_code | String | ISO-3166 compliant country code
|     | pickup/city | String | Defaults to the contact info of the customer creating the request
|     | pickup/zip_code | String | Defaults to the contact info of the customer creating the request

###### Sender/recipient parameters

Both the sender and recipient object must be specified in the request, see example below.

Req?  | Field | Type | Description
:---: | :--- | :--- | :---
\*    | company_name | String | Name of company
\*    | attention | String | Name of contact person
\*    | address_line1 | String |
|     | address_line2 | String |
|     | address_line3 | String |
\*    | country_code | String | ISO-3166 compliant country code
\*    | city |String |
\*    | zip_code | String |
|     | state_code | String |
C     | phone_number | String | Contact phone number. Required by some carriers
C     | email | String | Contact email. Required by some carriers

###### Example request

```json
{
  "access_token": "5cb0e7db6cf8d2e46cbcf58010252b78465c151",
  "callback_url": "http://somedomain.com/bookings/callback",
  "return_label": false,
  "shipment": {
    "product_code": "upsx",
    "dutiable": false,
    "package_dimensions": [{
      "amount": "1",
      "height": "10",
      "length": "10",
      "weight": "5",
      "width": "10"
    }],
    "description": "some customer description",
    "reference": "some customer reference",
    "shipping_date": "2015-08-03"
  },
  "sender": {
    "address_line1": "some street",
    "address_line2": "",
    "address_line3": "",
    "attention": "Jack",
    "city": "Copenhagen",
    "company_name": "Some company",
    "country_code": "DK",
    "email": "example@gmail.com",
    "phone_number": "33333333",
    "state_code": "",
    "zip_code": "2300"
  },
  "recipient": {
    "address_line1": "some other street",
    "address_line2": "",
    "address_line3": "",
    "attention": "George",
    "city": "Copenhagen",
    "company_name": "Some other company",
    "country_code": "DK",
    "email": "otherexample@gmail.com",
    "phone_number": "44444444",
    "state_code": "",
    "zip_code": "2300"
  }
}
```

#### Initial response

An initial response to a booking request will return `200 OK` and the following parameters:

Field | Description
:--- | :---
unique\_shipment\_id | Unique identifier for the created shipment
request_id | Unique identifier for the API request
status | Status on the created shipment (`failed`, `booked` or `waiting_for_booking`)
callback_url | Echoing the `callback_url` specified in the user request;

###### Example

```json
{
  "unique_shipment_id": "3-1-1134",
  "request_id": "5839db1b-1c52-42ad-ad07-438c6b2c8425",
  "status": "waiting_for_booking",
  "callback_url": "http://somedomain.com/bookings/callback"
}
```

#### Final response

This is the second response that Cargoflux will `POST` to the specified `callback_url` once the booking process has completed.

Field | Description
:---: | ---
awb | AWB number
awb\_asset\_url | Downloadable URL for the returned awb document

###### Example

```json
{
  "unique_shipment_id": "3-1-1294",
  "status": "booked",
  "awb": "0005712696000001230015",
  "awb_asset_url": "https://cargoflux-development.s3.amazonaws.com/assets/000/000/974/296b809b-6e81-49b-80f8-3012313232c088ccb.pdf?1439291475"
}
```

#### Failed shipments

If a shipment was created in Cargoflux (the initial response was a succesful one), but the booking process failed, the user should save the `unique_shipment_id` and refer to the **Retry Shipment** endpoint. The user should *NOT* book new shipments using the **Book Shipment** endpoint.

By doing this, the user can correct encountered errors by tweaking the request, thus updating the existing shipment, instead of creating a new shipment for each request.

#### Error response

Cargoflux will perform initial data validations on shipment requests, and such errors will always have a CF-prefixed error code.

If no initial errors are found, the request will be forwarded to the end carrier (TNT, UPS etc.). Each carrier perform their own unique data validations and may return additional errors. These errors will be transfered back to Cargoflux, who will then forward these back to the user, unmodified, as part of the error response.

If problems are encountered, with errors not originating from Cargoflux, the user can refer to the carriers own API documentation for further assistance.

###### Example

Errors are returned with status `500 Internal Server Error` and a JSON response:

```json
{
  "status": "failed",
  "errors": [
    {
      "code": "CF-API-003",
      "message": "invalid product_code"
    }
  ]
}
```

### Retry shipment

- `PUT /api/v1/customers/shipments` retries booking the shipment.

#### Request parameters

###### Meta parameters

Req?  | Field | Description
:---: | :--- | :---
\*    | access_token | API access token
\*    | callback_url | URL to which Cargoflux will send a `POST` request upon booking completion or errors . The URL must be reachable from the web.
\*    | unique\_shipment\_id | The unique shipment id returned in the initial response and can also be viewed when logged into Cargoflux.

###### Other parameters

The Shipment and Sender/Recipient parameters are required under the same specifications as described under the **Book Shipment** endpoint.

###### Example request

```json
{
  "access_token": "5cb0e7db6cf8d2e46cbcf58010252b78465c151",
  "callback_url": "http://somedomain.com/bookings/callback",
  "unique_shipment_id": "12-3-213",
  "shipment": {
    "product_code": "upsx",
    "dutiable": false,
    "package_dimensions": [{
      "amount": "1",
      "height": "10",
      "length": "10",
      "weight": "5",
      "width": "10"
    }],
    "description": "some customer description",
    "reference": "some customer reference",
    "shipping_date": "2015-08-03"
  },
  "sender": {
    "address_line1": "some street",
    "address_line2": "",
    "address_line3": "",
    "attention": "",
    "city": "Copenhagen",
    "company_name": "Some company",
    "country_code": "DK",
    "email": "example@gmail.com",
    "phone_number": "33333333",
    "state_code": "",
    "zip_code": "2300"
  },
  "recipient": {
    "address_line1": "some other street",
    "address_line2": "",
    "address_line3": "",
    "attention": "George",
    "city": "Copenhagen",
    "company_name": "Some other company",
    "country_code": "DK",
    "email": "otherexample@gmail.com",
    "phone_number": "44444444",
    "state_code": "",
    "zip_code": "2300"
  }
}
```

#### Response

Same response format as the **Book Shipment** endpoint.

#### Error response

Same error response format as the **Book Shipment** endpoint.

### Shipment prices

- `POST /api/v1/customers/shipments/prices.json` calculates prices per available carrier according to the given parameters.

**Required parameters:**

- `sender` is a JSON object with the following keys
  - `address_line1`
  - `address_line2` (optional)
  - `address_line3` (optional)
  - `zip_code`
  - `city`
  - `country_code`
  - `state_code`
- `recipient` is a JSON object with the following keys
  - `address_line1`
  - `address_line2` (optional)
  - `address_line3` (optional)
  - `zip_code`
  - `city`
  - `country_code`
  - `state_code`
- `package_dimensions` is a JSON array consisting of JSON objects with the following keys
  - `amount`
  - `height` (cm)
  - `length` (cm)
  - `width` (cm)
  - `weight` (kg)

**Optional parameters:**

- `default_sender` can be set to `true` to use the default location information of the customer; in that case `sender` will not be a required parameter.
- `shipment_type` can be set to `Export` (default) or `Import` for import shipments.

###### Example JSON request

```json
{
  "default_sender": true,
  "recipient": {
    "address_line1": "Njalsgade 17A",
    "address_line2": null,
    "address_line3": null,
    "zip_code": "2300",
    "city": "København S",
    "country_code": "DK",
    "state_code": null
  },
  "package_dimensions": [
    {
      "amount": 1,
      "height": 25,
      "length": 30,
      "width": 20,
      "weight": 1.5
    }
  ]
}
```

###### Example JSON response

If you have provided the required parameters we will return `200 OK` and a response body like the following:

```json
[
  {
    "name": "DAO Direkte",
    "product_code": "daod",
    "transit_time": null,
    "price_amount": null,
    "price_currency": null
  },
  {
    "name": "DAO Pakkeshop",
    "product_code": "daop",
    "transit_time": null,
    "price_amount": null,
    "price_currency": null
  },
  {
    "name": "GLS Business",
    "product_code": "glsb",
    "transit_time": null,
    "price_amount": "40.00",
    "price_currency": "DKK"
  },
  {
    "name": "GLS Pakkeshop",
    "product_code": "glsp",
    "transit_time": null,
    "price_amount": "56.12",
    "price_currency": "DKK"
  },
  {
    "name": "Post Danmark Erhvervspakke (Pacsoft)",
    "product_code": "pde",
    "transit_time": null,
    "price_amount": "25.07",
    "price_currency": "DKK"
  }
]
```

---

Country code
------------

Country codes should be alpha-2 codes following the ISO-3166 standard. [See here for more documentation](https://www.iso.org/iso-3166-country-codes.html).

Examples:

- `DK` for Denmark
- `GB` for United Kingdom of Great Britain and Northern Ireland
- `US` for United States of America

State code
----------

State codes are exclusively used for US and Canadian addresses.

DGR
---

Currently the following DGR options are supported (for DHL shipments):

Identifier | Description
:--------- | :---
`dry_ice` | Dry Ice UN1845
`lithium_ion_UN3481_PI966` | Ion PI966 Section I (LiBa with equipment)
`lithium_ion_UN3481_PI967` | Ion PI967 Section I (LiBa in equipment)
`lithium_metal_UN3091_PI969` | Metal PI969 Section I (LiBa with equipment)
`lithium_metal_UN3091_PI970` | Metal PI970 Section I (LiBa in equipment)
