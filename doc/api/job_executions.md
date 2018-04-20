## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/71622470-942a-45c1-adbd-199c83685333 HTTP/1.1
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
ETag: W/"b7992954a605e364d55d46d2915afa4d"
X-Request-Id: 8602e1f1-f40d-4c4b-bf8c-7b7b1eee3d47
X-Runtime: 0.008705

{
  "message_id": "71622470-942a-45c1-adbd-199c83685333",
  "status": "success",
  "id": 773
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/bbbf6ae8-a0f6-4d87-9eef-005749b22d2e?fields=__default__,html_url HTTP/1.1
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
ETag: W/"2b34bdd76bb52134a2232b91c94749e9"
X-Request-Id: 2180413d-6aef-435c-94d6-7107189c669f
X-Runtime: 0.002495

{
  "message_id": "bbbf6ae8-a0f6-4d87-9eef-005749b22d2e",
  "status": "success",
  "id": 774,
  "html_url": "http://www.example.com/job_executions/bbbf6ae8-a0f6-4d87-9eef-005749b22d2e"
}
```

## GET /v1/job_executions/:message_id
Returns message of the job_execution.

### Example

#### Request
```
GET /v1/job_executions/2a258cee-6459-4cea-9dda-73b52c70d76e?fields=__default__,message HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 200
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 111
Content-Type: application/json; charset=utf-8
ETag: W/"ca08e470e43fabd91348308004d3864a"
X-Request-Id: 537a8605-bca0-4dd2-9be4-78b9bc5a478d
X-Runtime: 0.002163

{
  "message_id": "2a258cee-6459-4cea-9dda-73b52c70d76e",
  "status": "success",
  "id": 775,
  "message": {
    "recipe_id": 12345
  }
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
  "queue": "queue-102",
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
ETag: W/"9d45a3c5732258dd568f77952ea2bc80"
X-Request-Id: 8ca08e5a-1604-499f-8e10-72c4acbdfa3e
X-Runtime: 0.002180

{
  "message_id": "3385716b-9a26-4563-9e51-33fa7787a2c9",
  "status": "pending",
  "id": null
}
```
