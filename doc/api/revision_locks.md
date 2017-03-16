## POST /v1/apps/:app_id/revision_lock
Updates a tag of docker_image.

### Parameters
* `revision` string (required) - Docker image revision to lock

### Example

#### Request
```
POST /v1/apps/app-52/revision_lock HTTP/1.1
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
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Request-Id: 82f9d82a-d887-4ebe-b784-bd3865b057ae
X-Runtime: 0.011747
X-XSS-Protection: 1; mode=block

{
  "revision": "798926db1e623cd51245b70b1f1acb40d780ddc1"
}
```

## DELETE /v1/apps/:app_id/revision_lock
Updates a tag of docker_image.

### Example

#### Request
```
DELETE /v1/apps/app-54/revision_lock HTTP/1.1
Accept: application/json
Content-Length: 0
Content-Type: application/json
Host: www.example.com
```

#### Response
```
HTTP/1.1 204
Cache-Control: no-cache
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-Request-Id: 68cbf752-1e39-4a2d-b26a-3ea65694f5bb
X-Runtime: 0.008371
X-XSS-Protection: 1; mode=block
```
