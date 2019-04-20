Kong Plugin: upstream-by-header
====================

[![Build Status](https://travis-ci.com/murillopaula/kong-upstream-by-header.svg?branch=master)](https://travis-ci.com/murillopaula/kong-upstream-by-header)

This is a Kong plugin that proxies requests to different upstreams when the request headers match one of the configured headers.

## Usage

upstream-by-header sends a request to a different upstream if its headers match one of the configured rules headers. You can specify a list of rules, where each rule has the following structure:

| parameter | description |
| --- | --- |
| `headers` |  List of (name, value) pairs |
| `upstream_name` |  Upstream hostname where the request will be sent to if the request headers match one of the `headers` |

The first match between the headers of a request and the headers of a rule will make the plugin route the request to the `upstream_name` configured for this rule. The plugin considers a match to happen when all the headers for a configured rule are contained in the request headers.

## Example

The following commands show examples of the plugin's functionality. All requests were made with [HTTPie](https://httpie.org).

Create a Service:

```bash
$ http :8001/services host=europe_cluster name=europe
```

Create a Route associated with the `europe` Service:

```bash
$ http :8001/services/europe/routes  paths:='["/local"]'
```

Create an Upstream with the same hostname as the Service `europe`:

```bash
$ http :8001/upstreams name=europe_cluster
```

Create a Target associated with the `europe_cluster` Upstream:

```bash
$ http :8001/upstreams/europe_cluster/targets target=mockbin.org:80
```

Create another Upstream to get requests different than requests made to `europe_cluster`:

```bash
$ http :8001/upstreams name=italy_cluster
```

Apply the plugin on the `europe` Service to send requests with the header `(X-Country, Italy)` to the Upstream `europe_cluster` and requests with the headers `(X-Country, Italy)` and `(X-Regione, Abruzzo)` to the Upstream `italy_cluster`:

```bash
$ http :8001/services/europe/plugins name=upstream-by-header config:='{"rules": [{"headers": {"X-Country":"Italy"}, "upstream_name": "europe_cluster"}, {"headers": {"X-Country": "Italy", "X-Regione": "Abruzzo"}, "upstream_name": "italy_cluster"}]}'
```

Requests that match route `/local` will be proxied to Upstream `europe_cluster`, except
requests that contain the header (X-Country, Italy) which should be proxied to Upstream
italy_cluster.

## TODO
- We're exposing the upstream name in `X-Upstream-Name` to make integration testing easier; ideally such information should not be exposed to clients.
- The time complexity for the header matching algorithm could potentially be optimzed with some hashing technique. Currently, it is O(r * h), where `r` is the number of rules and `h` is the number of headers for each rule.
- Fix the Travis CI build. It is failing because this [0] bash script file used for installing Kong and its dependencies is preventing the build from passing. See [1] for details.

[0] https://github.com/Kong/kong/blob/master/.ci/setup_env.sh
[1] https://travis-ci.com/murillopaula/kong-upstream-by-header/jobs/194360194/
