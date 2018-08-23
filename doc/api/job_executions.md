## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/44b34792-99c2-4165-b0a7-97ba8cb67701 HTTP/1.1
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
ETag: W/"162d4526406d7cc92778f7c9a77770b5"
X-Request-Id: 752ecffe-9fa0-471b-9c18-9da21f689b28
X-Runtime: 0.012975

{
  "message_id": "44b34792-99c2-4165-b0a7-97ba8cb67701",
  "status": "success",
  "id": 683
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/d54860cb-f374-4ef2-b19e-1662ce714c61?fields=__default__,html_url HTTP/1.1
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
ETag: W/"83d62488e2a41e9531c68de74c956ab0"
X-Request-Id: 2edf1ac6-cea2-42b7-a47a-b033c9981ff2
X-Runtime: 0.002832

{
  "message_id": "d54860cb-f374-4ef2-b19e-1662ce714c61",
  "status": "success",
  "id": 684,
  "html_url": "http://www.example.com/job_executions/d54860cb-f374-4ef2-b19e-1662ce714c61"
}
```

## GET /v1/job_executions/:message_id
Returns message of the job_execution.

### Example

#### Request
```
GET /v1/job_executions/ece0e578-a9ac-4eb5-ac8d-5a02270629c1?fields=__default__,message HTTP/1.1
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
ETag: W/"03c274fb6c9afa0dc90cd8eec1e77dcf"
X-Request-Id: fd15b690-9a0d-457c-b672-9721b28d5bca
X-Runtime: 0.005220

{
  "message_id": "ece0e578-a9ac-4eb5-ac8d-5a02270629c1",
  "status": "success",
  "id": 685,
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
* `delay_seconds` integer - Set message timer of SQS

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
ETag: W/"413ca32999e1a97bebde87741a53d078"
X-Request-Id: 8bc996f6-2b20-4bf6-a7f7-0980f796f0aa
X-Runtime: 0.002134

{
  "message_id": "e91b56d8-30a9-4331-93f6-1296216c7407",
  "status": "pending",
  "id": null
}
```

## POST /v2/job_executions
Enqueues a job execution with delay_seconds.

### Parameters
* `application` string (required) - Application name of the job
* `job` string (required) - Class of Job to be enqueued
* `queue` string (required) - Queue name to enqueue a job
* `message` any (required) - Free-format JSON
* `delay_seconds` integer - Set message timer of SQS

### Example

#### Request
```
POST /v2/job_executions HTTP/1.1
Accept: application/json
Content-Length: 109
Content-Type: application/json
Host: www.example.com

{
  "application": "blog",
  "job": "NotifyAuthor",
  "queue": "queue-105",
  "message": {
    "recipe_id": 1
  },
  "delay_seconds": 300
}
```

#### Response
```
HTTP/1.1 201
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 82
Content-Type: application/json; charset=utf-8
ETag: W/"dabbb98b9040a53f74a93682f6a83ccd"
X-Request-Id: b58503df-873d-4544-868a-021ffdcde58a
X-Runtime: 0.004408

{
  "message_id": "8f5cbe66-8dee-433e-ba90-30cbf36eddfe",
  "status": "pending",
  "id": null
}
```
