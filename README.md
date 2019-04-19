Kong Plugin: upstream-by-header
====================

This is a Kong plugin that sends requests to different upstreams when the request headers match one of the configured headers.

## Usage

upstream-by-header sends a request to a different upstream if its headers match one of the configured rules headers. You can specify a list of rules, where each rule has the following structure:

| parameter | description |
| --- | --- |
| `headers` |  List of (name, value) pairs |
| `upstream_name` |  Upstream hostname where the request will be sent to if the request headers match one of the `headers` |

For each request coming into Kong, the plugin will try to find a rule where all the headers defined in the condition field have the same value as in the incoming request. The first such match dictates the upstream to which the request is forwarded to.

The first match between the headers of a request and the headers of a rule will make the plugin route the request to the `upstream_name` configured for this rule. The plugin considers a match to happen when all the headers for a configured rule are contained in the request headers.
