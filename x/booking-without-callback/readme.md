# booking-without-callback

`booking-without-callback` is a small service that lets CargoFlux customers make bookings without callbacks.
We do this by forwarding the booking request to the CargoFlux API and waiting with the HTTP response until we have received the callback.

This service could run anywhere but for now it is running with the help of Zeit Now. To be able to deploy you would need to [install their CLI](https://zeit.co/download#now-cli).
An important aspect of the service is that it **must** only run with 1 instance because the in-process memory is being used for storing relevant data.

## Develop

    $ BOOKING_URL=http://cargoflux.test/api/v1/customers/shipments CALLBACK_URL=http://localhost:4004/callback/seKreT npm run dev -- -p 4004

## Deploy

**Staging**

    $ now -A now.staging.json --public --team cargoflux
    $ now alias -A now.staging.json --team cargoflux
    $ now rm cf-sync-api-staging --safe --yes --team cargoflux

**Production**

    $ now -A now.production.json --public --team cargoflux
    $ now alias -A now.production.json --team cargoflux
    $ now rm cf-sync-api-production --safe --yes --team cargoflux
