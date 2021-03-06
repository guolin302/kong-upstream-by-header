Kong Plugin: upstream-by-header
====================

[![Build Status](https://travis-ci.com/murillopaula/kong-upstream-by-header.svg?branch=master)](https://travis-ci.com/murillopaula/kong-upstream-by-header)

This is a Kong plugin that proxies requests to different upstreams when the request headers match one of the configured headers.

## Usage

upstream-by-header sends a request to a different upstream if its headers match one of the configured rules headers. You can specify a list of rules, where each rule has the following structure:

| parameter | description |
| --- | --- |
| `headers` |  List of (name, value) pairs |
| `upstream_name` |  Upstream hostname where the request will be sent to if the request headers match one of the configured `headers` |

The first match between the headers of a request and the headers of a rule will make the plugin route the request to the `upstream_name` configured for this rule. The plugin considers a match to happen when all the headers for a configured rule are contained in the request headers.

## Example

All of the following requests use [HTTPie](https://httpie.org) to submit HTTP client requests to the Kong Admin API.

We'll illustrate the plugin's functionality by creating four different upstreams. Each upstream will have one associated target with it.

- The `default_cluster` upstream will route requests to its target if the request headers do not contain any particular relevant header (or if they are empty).
- The `europe_cluster` upstream will route requests to its target if the request headers contain the `(X-Country, Italy)` header.
- The `italy_cluster` upstream will route requests to its target if the request headers contain the `(X-Country, Italy)` _and_ the `(X-Regione, Abruzzo)` headers.
- The `rome_cluster` upstream will route requests to its target if the request headers contain the `(X-Country, Italy)` _and_ the `(X-Regione, Rome)` headers.

Let's create the four upstreams and their associated targets. We'll use [Mockbin](http://mockbin.org/) as mock HTTP servers to provide upstream responses.

`default_cluster` upstream:

```bash
$ http :8001/upstreams name=default_cluster
```

`default_cluster` upstream target:

```bash
$ http :8001/upstreams/default_cluster/targets target=mockbin.org:80
```

`europe_cluster` upstream:

```bash
$ http :8001/upstreams name=europe_cluster
```

`europe_cluster` upstream target:

```bash
$ http :8001/upstreams/europe_cluster/targets target=mockbin.org:80
```

`italy_cluster` upstream:

```bash
$ http :8001/upstreams name=italy_cluster
```

`italy_cluster` upstream target:

```bash
$ http :8001/upstreams/italy_cluster/targets target=mockbin.org:80
```

`rome_cluster` upstream:

```bash
$ http :8001/upstreams name=rome_cluster
```

`rome_cluster` upstream target:

```bash
$ http :8001/upstreams/rome_cluster/targets target=mockbin.org:80
```

Now let's create a service to sit behind the Kong API middleware using the `default_cluster`:

```bash
$ http :8001/services host=default_cluster name=default
```

Create a Route associated with `default` service:

```bash
$ http :8001/services/default/routes paths:='["/local"]'
```

By associating the `default` service to the `default_cluster` upstream, all requests that match the `/local` route will be proxied to the `default_cluster` upstream.

Now apply the plugin to the `default` service to send requests with the header `(X-Country, Italy)` to the Upstream `europe_cluster`, requests with the headers `(X-Country, Italy)` and `(X-Regione, Abruzzo)` to the Upstream `italy_cluster` and requests with the headers `(X-Country, Italy)` and `(X-Regione, Rome)` to the Upstream `rome_cluster`:

```bash
$ http :8001/services/default/plugins name=upstream-by-header config:='{"rules": [{"headers": {"X-Country":"Italy"}, "upstream_name": "europe_cluster"}, {"headers": {"X-Country": "Italy", "X-Regione": "Abruzzo"}, "upstream_name": "italy_cluster"}, {"headers": {"X-Country": "Italy", "X-Regione": "Rome"}, "upstream_name": "rome_cluster"}]}'
```

This type of customized routing based on requests headers is what makes the plugin useful. From now on, requests that match the route `/local` will be proxied to the upstream `default_cluster`, with the following exceptions:

- Requests that contain the header `(X-Country, Italy)` should be proxied to the upstream `europe_cluster`.
- Requests that contain the headers `(X-Country, Italy)` _and_ `(X-Regione, Abruzzo)` should be proxied to the upstream `italy_cluster`.
- Requests that contain the headers `(X-Country, Italy)` _and_ `(X-Regione, rome)` should be proxied to the upstream `rome_cluster`.

Which is exactly what we wanted to do!

## TODO
- We're exposing the upstream name in `X-Upstream-Name` to make integration testing easier; ideally such information should not be exposed to clients.
- Currently, the worst-case running time complexity of the header matching algorithm is O(R * H), where `R` is the number of configured rules and `H` is the number of headers for each rule. One improvement would be to research and implement some hash matching algorithm, which could improve the worst-case running time of the header matching algorithm.
- We are hooking up Travis CI to run the plugin's unit and integration tests with the help of the `setup_env.sh` shell script, which is used in the 0.15.0 version of Kong [0]. This script allows us to set up our Kong development environment, but ideally it should not reside in this repository.
- In the future, we should be able to find an easier way to install the Kong development environment to develop our plugin. One idea is to use `kong-build-tools`, which uses Docker and docker-compose [1].

[0] https://github.com/Kong/kong/blob/0.15.0/.ci/setup_env.sh
[1] https://github.com/Kong/kong-build-tools#developing-kong
