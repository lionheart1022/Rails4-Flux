const { json, send } = require('micro')
const request = require('request')
const { URL } = require('url')

var callbackURL
if (process.env.CALLBACK_URL) {
  callbackURL = new URL(process.env.CALLBACK_URL)
} else if (process.env.NOW && process.env.CALLBACK_PATH) {
  callbackURL = new URL(process.env.CALLBACK_PATH, process.env.NOW_URL)
} else {
  throw "Could not determine callback URL"
}

const bookingURL = new URL(process.env.BOOKING_URL)
const callbackIntervalInMs = 1000
const maxCallbackWaitingTimeInSec = 60 * 30 // 30 minutes
var shipmentCallbackResponses = {}
var nBookingCalls = 0

module.exports = async (req, res) => {
  if (req.method === 'POST' && req.url === bookingURL.pathname) {
    let bookingBody = await json(req)
    bookingBody['callback_url'] = callbackURL.href

    let bookingHeaders = {}
    if (req.headers['access-token']) {
      bookingHeaders['Access-Token'] = req.headers['access-token']
    }
    if (process.env.NOW) {
      bookingHeaders['X-Now-URL'] = process.env.NOW_URL
    }

    const bookingRequestOptions = {
      url: bookingURL.href,
      json: bookingBody,
      headers: bookingHeaders
    }

    var interval

    request.post(bookingRequestOptions, (error, bookingResponse, bookingResponseBody) => {
      // TODO: Error handling. Not sure actually when error could be set?
      if (error) {
        send(res, 500, 'Internal Server Error')
        console.error('Booking request failed', error)
        return
      }

      nBookingCalls++
      console.log(`Number of bookings so far: ${nBookingCalls}`)

      // Scenario 1) Booking failed to begin with - there will never be a callback.
      if (bookingResponse.statusCode !== 200) {
        send(res, bookingResponse.statusCode, bookingResponseBody)
        console.log(`Returned non-successful booking response with status ${bookingResponse.statusCode}`)
        return
      }

      var uniqueShipmentID = bookingResponseBody.unique_shipment_id

      // Scenario 2) Booking was created with state/status `created`, meaning it is with a custom product
      //             And this in turn means no callback will actually be called.
      if (bookingResponseBody.status === 'created') {
        res.setHeader('X-Callback-Response', 'false')
        send(res, bookingResponse.statusCode, bookingResponseBody)
        console.log(`Returned response for #${uniqueShipmentID} (custom product, meaning no callback will actually be called)`)
        return
      }

      shipmentCallbackResponses[uniqueShipmentID] = {
        initiatedAt: new Date(),
        body: null,
      }

      // Scenario 3) We'll need to wait for the callback response.
      interval = setInterval(() => {
        const callbackResponse = shipmentCallbackResponses[uniqueShipmentID]
        const durationInSec = callbackResponse ? (new Date() - callbackResponse.initiatedAt)/1000 : null

        if (callbackResponse && callbackResponse.body !== null) {
          clearInterval(interval)
          res.setHeader('X-Callback-Response', 'true')
          send(res, 200, callbackResponse.body)
          console.log(`Returned callback response for #${uniqueShipmentID} after ${durationInSec} seconds`)

          // Clean up
          delete shipmentCallbackResponses[uniqueShipmentID]
        } else if (durationInSec > maxCallbackWaitingTimeInSec) {
          clearInterval(interval)
          send(res, 504, { status: 'callback_timeout_error' })
          console.log(`Callback for #${uniqueShipmentID} has timed out after ${durationInSec} seconds`)
        } else {
          console.log(`Waiting for callback for #${uniqueShipmentID} (${durationInSec} seconds)`)
        }
      }, callbackIntervalInMs)
    })
  } else if (req.method === 'POST' && req.url === callbackURL.pathname) {
    const callbackBody = await json(req)
    const uniqueShipmentID = callbackBody.unique_shipment_id

    if (uniqueShipmentID && shipmentCallbackResponses[uniqueShipmentID] && shipmentCallbackResponses[uniqueShipmentID].body === null) {
      shipmentCallbackResponses[uniqueShipmentID].body = callbackBody
      send(res, 200, `Callback was received for #${uniqueShipmentID}\n`)
    } else {
      send(res, 400, `Callback was rejected\n`)
    }
  } else if (req.method === 'GET' && req.url === callbackURL.pathname) {
    send(res, 200, `This is the callback endpoint: ${callbackURL.href}\n`)
  } else if (req.method === 'GET' && req.url === '/ping') {
    send(res, 200, `pong`)
  } else {
    send(res, 404, `Route is unsupported: ${req.url}\n`)
  }
}
