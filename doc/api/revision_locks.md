## POST /v1/apps/:app_id/revision_lock
Updates a tag of docker_image.

### Parameters
* `revision` string (required) - Docker image revision to lock

### Example

#### Request
```
POST /v1/apps/app-49/revision_lock HTTP/1.1
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
X-Request-Id: f903289a-c963-4e6c-ad00-4a03b3062306
X-Runtime: 0.015287
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
DELETE /v1/apps/app-51/revision_lock HTTP/1.1
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
X-Request-Id: 73ac851c-ec74-4dc5-8ce8-1917cb0c8a8f
X-Runtime: 0.007907
X-XSS-Protection: 1; mode=block
```
