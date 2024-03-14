# VerNest

## Web Application to centraly store version strings of arbitrary things.

### Endpoints

#### /

This page.

#### "[/programs/new](/programs/new)"

Form to add a new record

#### "[/programs](/programs)"

Index of all records

#### "[/programs/:id/edit](/programs/:id/edit)"

Form to edit an existing record

#### "[/programs/version&name=Foo Bar](/programs/version&name=Foo Bar)"

Returns json string with the currently recorded version string of "Foo Bar"

```json
[{"version":"1.0"}]
```

### cURL examples

>NB basic auth has to be implemented via reverse proxy or similar.

#### Call to add a new record

```sh
curl -u admin:secret -d '{"name":"Example Program", "version":"1.0", "program_type":"Utility"}' -H "Content-Type: application/json" -X POST http://localhost:4567/programs
```

#### Call to receive version string by providing the program name, and optionally the program type

```sh
curl -u admin:secret -G http://localhost:4567/programs/version --data-urlencode "name=Example Program"
```

#### Call to receive all entries

```sh
curl -u admin:secret -G http://localhost:4567/programs --data-urlencode "format=json"
```
