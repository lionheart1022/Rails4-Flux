# Cargoflux

## Development

Required system dependencies:

- PostgreSQL (currently version 9.6 in production)
- [wkhtmltopdf](http://wkhtmltopdf.org/downloads.html) (currently version 0.12.5 in production)
- ImageMagick version 6.4.9+, <= 7
- Ghostscript

Optional system dependencies:

- [rbenv](https://github.com/rbenv/rbenv#homebrew-on-mac-os-x)
- [mailcatcher](https://mailcatcher.me/)

### Initial setup

- `gem install bundler # If you're using rbenv`
- `gem install foreman`
- `./bin/setup`

### Boot application

    bundle exec foreman start -e config/development.env

If you want to see the mails being sent from the application you should install mailcatcher and start it up:

    mailcatcher -fv

Now you will be able to see the sent emails at [http://127.0.0.1:1080](http://127.0.0.1:1080).

### API docs

Our APIs are documented in `api_v1_for_customers.md` and `api_v1_for_companies.md`. When changing these you must generate new PDF versions and place them in `public/documentation`.

Install [MacDown](https://macdown.uranusjr.com/), open the changed API doc file and export to PDF.

## Deployment

The staging and production environment are both running on Heroku - [install the Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli).

### Initial setup

Heroku application names:

- `cargoflux-staging`
- `cargoflux-production`

Setup Git remotes for staging and production:

- `alias oku=/usr/local/bin/heroku # alias because of possible clash with heroku gem`
- `oku git:remote -a cargoflux-staging -r heroku-staging`
- `oku git:remote -a cargoflux-production -r heroku-production`

### Workflow

- `git checkout -b feature/branch # Create a feature branch`
- `git push heroku-staging feature/branch:master # Deploy branch to staging`
- `oku run -a cargoflux-staging rake db:migrate # Run migrations if needed`
- `# Iterate and deploy to staging again`
- `git checkout master # Ready for production`
- `git merge --squash feature/branch # Keep master history clean`
- `git commit`
- `git push master`
- `git push heroku-production master`
- `oku run -a cargoflux-production rake db:migrate # Run migrations in production if needed`

For more details read `deploy_procedure.md`.

---

## Private API

The following endpoints are not documented in the public API documentation. This could change in the future.

### Import contacts

- `POST /api/v1/customers/address/import` imports contacts from the uploaded CSV file.

We have an endpoint which is not publicly documented in the regular (customer) API documentation.

**Required parameters:**

- `file` is the CSV file containing the contacts

The CSV file is expected to be delimited with `;` and contain the following columns

- `company`
- `attention`
- `address_1`
- `address_2`
- `address_3`
- `zip`
- `city`
- `country_iso`
- `state_code`
- `phone`
- `email`

**Request with cURL**

    curl -XPOST -F "access_token=xxx" -F "file=@/path/to/file.csv" "https://api.cargoflux.com/api/v1/customers/address/import"
