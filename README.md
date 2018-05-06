## Proxy & protect the Admin API

Updated to Kong 0.13: apis endpoint is deprecated, replaced with routes and services.


Run Kong in the background of the one-off dyno:

```bash
heroku run bash
bin/background-start
```


Create a consumer with username and authentication credentials:

```bash
curl http://localhost:8001/consumers/ -i -X POST \
  --data 'username=admin-cli'
```

```bash
curl http://localhost:8001/consumers/admin-cli/acls -i -X POST \
  --data 'group=admins'
```

```bash
curl http://localhost:8001/consumers/admin-cli/key-auth -i -X POST -d ''
# Take note of the returned key.
```


Create the authenticated `/admin` service targeting the localhost port:

```bash
curl http://localhost:8001/services -i -X POST \
  --data 'name=admin' \
  --data 'url=http://localhost:8001'
# Take note of the returned id.
SERVICE_ID=THE_RETURNED_SERVICE_ID
```

```bash
curl http://localhost:8001/routes -i -X POST \
  --data 'protocols[]=https' \
  --data 'paths[]=/admin' \
  --data 'service.id=$SERVICE_ID'
# Take note of the returned id.
ROUTE_ID=THE_RETURNED_ROUTE_ID
```

```bash
curl http://localhost:8001/plugins/ -i -X POST \
  --data 'service_id=$SERVICE_ID' \
  --data 'route_id=$ROUTE_ID' \
  --data 'name=request-size-limiting' \
  --data 'config.allowed_payload_size=8'
```

```bash
curl http://localhost:8001/plugins/ -i -X POST \
  --data 'service_id=$SERVICE_ID' \
  --data 'route_id=$ROUTE_ID' \
  --data 'name=rate-limiting' \
  --data "config.second=5"
```

```bash
curl http://localhost:8001/plugins/ -i -X POST \
  --data 'service_id=$SERVICE_ID' \
  --data 'route_id=$ROUTE_ID' \
  --data 'name=key-auth' \
  --data "config.hide_credentials=true"
```

```bash
curl http://localhost:8001/plugins/ -i -X POST \
  --data 'service_id=$SERVICE_ID' \
  --data 'route_id=$ROUTE_ID' \
  --data 'name=acl' \
  --data "config.whitelist=admins"
```


## Test the custom plugins

### google-apps-script-plugin plugin:

```bash
curl -X POST \
  https://kong-dev-script-tools.herokuapp.com/admin/services/ \
  -H 'apikey: <YOUR_API_KEY>' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -d 'name=google-apps-script' \
  -d 'protocol=https' \
  -d 'host=script.googleapis.com' \
  -d 'path=/v1/script' \
  -d 'port=443'
  # Take note of the returned id (service id)
```

```bash
curl -X POST \
  https://kong-dev-script-tools.herokuapp.com/admin/routes/ \
  -H 'apikey: <YOUR_API_KEY>' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -d 'service.id=<THE_SERVICE_ID_RETURNED_BY_THE_PREVIOUS_CALL>' \
  -d 'protocols[]=https' \
  -d 'paths[]=/google-apps-script/(?<func>\S+)' \
  -d 'preserve_host=true' \
  -d 'strip_path=true'
  # Take note of the returned id (route id)
```

```bash
curl -X POST \
  https://kong-dev-script-tools.herokuapp.com/admin/plugins \
  -H 'apikey: <YOUR_API_KEY>' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -d 'route_id=<THE_ROUTE_ID_RETURNED_BY_THE_PREVIOUS_CALL>' \
  -d 'name=google-apps-script' \
  -d 'config.script_id=1hkrNVybpBVoNEdkscU4GuLspUftMns8luqe7xidQimoO1EmPk6XfSXBk' \
  -d 'config.get.function_name=paths.func' \
  -d 'config.get.function_arguments=method,querystring' \
  -d 'config.post.function_name=paths.func' \
  -d 'config.post.function_arguments=method,body' \
  -d 'config.function_name=fix.kongAny' \
  -d 'config.function_arguments=method,querystring,body,headers.Server'
```
