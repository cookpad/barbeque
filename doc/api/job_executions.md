## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/147e070d-41a9-4ace-a122-2aa579e18f08 HTTP/1.1
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
ETag: W/"7e91b6b9d378eb1b93717767ccdccc68"
X-Request-Id: 19b16855-477c-4f8a-99a6-db203a472bfe
X-Runtime: 0.008698

{
  "message_id": "147e070d-41a9-4ace-a122-2aa579e18f08",
  "status": "success",
  "id": 257
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/060a38f2-97a8-42ea-8250-b0c66b8dad77?fields=__default__,html_url HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 200
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 163
Content-Type: application/json; charset=utf-8
ETag: W/"dfeb94a1453a12315b86db92ddf3fe01"
X-Request-Id: 8a7713b2-305f-4daf-b877-dc288147915c
X-Runtime: 0.002219

{
  "message_id": "060a38f2-97a8-42ea-8250-b0c66b8dad77",
  "status": "success",
  "id": 258,
  "html_url": "https://barbeque/job_executions/060a38f2-97a8-42ea-8250-b0c66b8dad77"
}
```

## GET /v1/job_executions/:message_id
Returns message of the job_execution.

### Example

#### Request
```
GET /v1/job_executions/d3052505-355f-44aa-9565-9ac325960f6b?fields=__default__,message HTTP/1.1
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
ETag: W/"06553c660e7287f2b1e5d29f01b494f7"
X-Request-Id: e8c5596a-ec4a-407c-9a8d-864d23a32044
X-Runtime: 0.001963

{
  "message_id": "d3052505-355f-44aa-9565-9ac325960f6b",
  "status": "success",
  "id": 259,
  "message": {
    "recipe_id": 12345
  }
}
```

## GET /v1/job_executions/:message_id
Returns error message.

### Example

#### Request
```
GET /v1/job_executions/4df2cbf1-bfb6-46f8-9412-e6adc2349bbe HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 503
Cache-Control: no-cache
Content-Length: 237
Content-Type: application/json; charset=utf-8
X-Request-Id: 78d64fec-e4b5-4a93-8a00-e7201ba7b3ce
X-Runtime: 0.002017

{
  "message": "Mysql2::Error::ConnectionError: Can't connect to MySQL server: SELECT  `barbeque_job_executions`.* FROM `barbeque_job_executions` WHERE `barbeque_job_executions`.`message_id` = '4df2cbf1-bfb6-46f8-9412-e6adc2349bbe' LIMIT 1"
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
  "queue": "queue-104",
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
ETag: W/"906cbe627aa59752a3654cdc059b930a"
X-Request-Id: ece6706b-cd9b-4d24-9093-7d5bb248bd35
X-Runtime: 0.001741

{
  "message_id": "6dc3cbba-77fe-4922-bd9f-273def490f72",
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
  "queue": "queue-107",
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
ETag: W/"2584b3edd06144ea19b89616b028d0e0"
X-Request-Id: 1f9c99b9-8540-4897-9bfc-fc1f6dec2260
X-Runtime: 0.005125

{
  "message_id": "b1413290-1b07-4e0d-b3df-817204c14daa",
  "status": "pending",
  "id": null
}
```
