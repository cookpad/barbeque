## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/a0cb3899-f458-4389-bc45-f3e1380ebe94 HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 200
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 81
Content-Type: application/json; charset=utf-8
ETag: W/"fd6c1c7a7d062a6d47b978a65ced9d08"
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Request-Id: afbf03b0-450f-49d5-8741-14906ff4495e
X-Runtime: 0.011198
X-XSS-Protection: 1; mode=block

{
  "message_id": "a0cb3899-f458-4389-bc45-f3e1380ebe94",
  "status": "success",
  "id": 277
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/f3e3b7a2-3517-47d4-aa58-8e531c2bfa3b?fields=__default__,html_url HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 200
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 136
Content-Type: application/json; charset=utf-8
ETag: W/"4c1e26dbc5c441e68ced4559ae1ca13c"
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Request-Id: 9eef7915-4054-4494-8c2d-6f9312c208f6
X-Runtime: 0.005148
X-XSS-Protection: 1; mode=block

{
  "message_id": "f3e3b7a2-3517-47d4-aa58-8e531c2bfa3b",
  "status": "success",
  "id": 278,
  "html_url": "http://www.example.com/job_executions/278"
}
```

## POST /v2/job_executions
Enqueues a job execution.

### Parameters
* `application` string (required) - Application name of the job
* `job` string (required) - Class of Job to be enqueued
* `queue` string (required) - Queue name to enqueue a job
* `message` any (required) - Free-format JSON

### Example

#### Request
```
POST /v2/job_executions HTTP/1.1
Accept: application/json
Content-Length: 88
Content-Type: application/json
Host: www.example.com

{
  "application": "blog",
  "job": "NotifyAuthor",
  "queue": "queue-45",
  "message": {
    "recipe_id": 1
  }
}
```

#### Response
```
HTTP/1.1 201
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 82
Content-Type: application/json; charset=utf-8
ETag: W/"989676f33ea349525dc206be62f5fa74"
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Request-Id: fe0b4e31-3e13-40b8-a7bc-25c99a1bc912
X-Runtime: 0.005131
X-XSS-Protection: 1; mode=block

{
  "message_id": "ea17fa06-9581-4252-9f42-7474e16ab679",
  "status": "pending",
  "id": null
}
```
