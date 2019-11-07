Cargoflux API for Mobile App
============================

Authentication
--------------

The API requires the user to authenticate each request with a token.
To generate this token see _Endpoints / Create Session_.

When the user has successfully authenticated, a `(token_value, token_id)` pair will be returned.

To perform authentication you must set the `Authorization` header with the token data, as shown in the table below.

Header | Value
:----- | :---
`Authorization` | `Token token={{token_value}}, t_id={{token_id}}`

### General responses related to authentication

###### If token value/ID is invalid/missing `Status: 401 Unauthorized`

```json
{
  "message": "Invalid"
}
```

###### If session/token has expired `Status: 401 Unauthorized`

The session/token will expire when logging out. It could also be caused by an admin revoking the user's access.

```json
{
  "message": "Token is expired - generate a new one by re-authenticating"
}
```

Format
------

We use JSON for all API data. This means that you have to set the `Content-Type` header

Header | Value
:----- | :---
`Content-Type` | `application/json; charset=utf-8`

when you're POSTing or PUTing data.

Base URI
--------

Environment | Base URI
:---------- | :---
staging | `https://cargoflux-staging.herokuapp.com`
production | `https://api.cargoflux.com`

Endpoints
---------

### Create Session (aka. log in)

- `POST /api/app/session.json` performs email/password authentication and generates a new token on success.

###### Request


```json
{
  "email": "test@example.com",
  "password": "correct-password",
  "platform": "ios"
}
```

###### Response for successful authentication `Status: 201 Created`

```json
{
  "success": true,
  "token_id": 1,
  "token_value": "xxxxxxxxxxxxxxxxxxxxxx"
}
```

###### Response for failed authentication `Status: 200 OK`

```json
{
  "success": false
}
```

### Show Session

- `GET /api/app/session.json` returns metadata about the current session.

###### Response `Status: 200 OK`

```json
{
  "email": "test@example.com",
  "platform": "ios",
  "user_agent": "PostmanRuntime/7.1.1",
  "token_id": 1,
  "token_value": "xxxxxxxxxxxxxxxxxxxxxx",
  "created_at": "2018-01-11T15:47:48.215+01:00",
  "last_used_at": null
}
```

### Delete Session (aka. log out)

- `DELETE /api/app/session.json` expires the current session.

###### Response `Status: 202 Accepted`

```
<Empty body>
```

### Show Company Info

- `GET /api/app/company.json` returns metadata about the current company.

###### Response `Status: 200 OK`

```json
{
  "name": "Test Company",
  "phone_number": "+45 xxxxxxxx",
  "email": "info@example.com"
}
```
