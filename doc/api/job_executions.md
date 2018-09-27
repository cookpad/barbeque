## GET /v1/job_executions/:message_id
Shows a status of a job_execution.

### Example

#### Request
```
GET /v1/job_executions/a05ba839-aaab-4aeb-9bb6-fa7af3d870a9 HTTP/1.1
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
ETag: W/"a6c4db4cdaf2feeb7f02f7842c36a2e2"
X-Request-Id: a120cc28-4dbd-408a-872c-e6a4b6a8b7b9
X-Runtime: 0.011375

{
  "message_id": "a05ba839-aaab-4aeb-9bb6-fa7af3d870a9",
  "status": "success",
  "id": 305
}
```

## GET /v1/job_executions/:message_id
Shows url to job_execution.

### Example

#### Request
```
GET /v1/job_executions/d8f3aca9-eb94-42f1-88be-c5c1372c98f1?fields=__default__,html_url HTTP/1.1
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
ETag: W/"ed43007e8be846b3ae14a156b436f74c"
X-Request-Id: f14551e7-dda9-48e0-8273-b8b95c64437b
X-Runtime: 0.002641

{
  "message_id": "d8f3aca9-eb94-42f1-88be-c5c1372c98f1",
  "status": "success",
  "id": 306,
  "html_url": "http://www.example.com/job_executions/d8f3aca9-eb94-42f1-88be-c5c1372c98f1"
}
```

## GET /v1/job_executions/:message_id
Returns message of the job_execution.

### Example

#### Request
```
GET /v1/job_executions/d369e2ab-7795-4583-b395-9b1011ba92eb?fields=__default__,message HTTP/1.1
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
ETag: W/"a7ab894eb65c3315a838124226eb3975"
X-Request-Id: e95da0fb-ef37-4ea9-9d08-3e512d47e482
X-Runtime: 0.002996

{
  "message_id": "d369e2ab-7795-4583-b395-9b1011ba92eb",
  "status": "success",
  "id": 307,
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
GET /v1/job_executions/b46e9fd7-e2dd-461b-9476-1bb37e643644 HTTP/1.1
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
X-Request-Id: 05c0ece4-ea68-4489-a0f5-18d63049418b
X-Runtime: 0.001956

{
  "message": "Mysql2::Error::ConnectionError: Can't connect to MySQL server: SELECT  `barbeque_job_executions`.* FROM `barbeque_job_executions` WHERE `barbeque_job_executions`.`message_id` = 'b46e9fd7-e2dd-461b-9476-1bb37e643644' LIMIT 1"
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
ETag: W/"35bd09a003bb4f7fb8b0e2b755fb76b0"
X-Request-Id: d01d9be1-de8f-4818-aa86-f6bd8e7da8c7
X-Runtime: 0.001690

{
  "message_id": "ac34af9b-f26a-4674-983d-69ddb29451e6",
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
ETag: W/"b369de6c5fcf19825ef21650cc312f49"
X-Request-Id: 4840803e-2cce-4818-a9b3-a6c97a469b8e
X-Runtime: 0.001685

{
  "message_id": "44ac17fa-6df7-4af9-9e1b-670b1d585b0e",
  "status": "pending",
  "id": null
}
```
