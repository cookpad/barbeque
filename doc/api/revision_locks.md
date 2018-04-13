## POST /v1/apps/:app_id/revision_lock
Updates a tag of docker_image.

### Parameters
* `revision` string (required) - Docker image revision to lock

### Example

#### Request
```
POST /v1/apps/app-104/revision_lock HTTP/1.1
Accept: application/json
Content-Length: 55
Content-Type: application/json
Host: www.example.com

{
  "revision": "798926db1e623cd51245b70b1f1acb40d780ddc1"
}
```

#### Response
```
HTTP/1.1 201
Cache-Control: max-age=0, private, must-revalidate
Content-Length: 55
Content-Type: application/json; charset=utf-8
ETag: W/"a3f0b3d8c32ee1e318357b5276e50a3c"
X-Request-Id: 3173b89d-b5ce-4464-af51-6d17684cf3de
X-Runtime: 0.008263

{
  "revision": "798926db1e623cd51245b70b1f1acb40d780ddc1"
}
```

## DELETE /v1/apps/:app_id/revision_lock
Updates a tag of docker_image.

### Example

#### Request
```
DELETE /v1/apps/app-106/revision_lock HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 204
Cache-Control: no-cache
X-Request-Id: b968f324-529b-4b79-a3e7-70f0f6b01e48
X-Runtime: 0.003531
```
