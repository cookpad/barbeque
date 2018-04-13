## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/15aca944-317a-41e0-b516-11b521b112bc HTTP/1.1
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
ETag: W/"acc93d8f520e4573bb3d45e21e012e61"
X-Request-Id: 61b69fa5-8c82-4a61-b724-87ebc017860b
X-Runtime: 0.008871

{
  "message_id": "15aca944-317a-41e0-b516-11b521b112bc",
  "status": "success",
  "id": 676
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/2dd71a56-4739-4fcc-9e0b-84ff54aca52a?fields=__default__,html_url HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 200
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 169
Content-Type: application/json; charset=utf-8
ETag: W/"974f9e490c2546d3eae7c2a472c9a807"
X-Request-Id: bc484f21-85a4-414e-aca0-ecac8e088858
X-Runtime: 0.003213

{
  "message_id": "2dd71a56-4739-4fcc-9e0b-84ff54aca52a",
  "status": "success",
  "id": 677,
  "html_url": "http://www.example.com/job_executions/2dd71a56-4739-4fcc-9e0b-84ff54aca52a"
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
Content-Length: 89
Content-Type: application/json
Host: www.example.com

{
  "application": "blog",
  "job": "NotifyAuthor",
  "queue": "queue-101",
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
ETag: W/"f0b0641b47334a8d8a7aca05c315bc9f"
X-Request-Id: 6f7344d8-c99e-48f3-a573-ce6a4e74eb76
X-Runtime: 0.002492

{
  "message_id": "7a21b14d-64d2-42ad-a482-00088f48aa47",
  "status": "pending",
  "id": null
}
```
