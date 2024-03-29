# docker-flexo
dockerized flexo: https://github.com/nroi/flexo

The settings can be modified with environment variables. Each environment variable corresponds to a setting in [flexo.toml](https://github.com/nroi/flexo/blob/master/flexo/conf/flexo.toml). Environment variables are always prefixed with `FLEXO_`, for example, `listen_ip_address` corresponds to the `FLEXO_LISTEN_IP_ADDRESS` environment variable.

The following environment variables are currently supported:

```
FLEXO_CACHE_DIRECTORY
FLEXO_CONNECT_TIMEOUT
FLEXO_CUSTOM_REPO
FLEXO_LISTEN_IP_ADDRESS
FLEXO_LOW_SPEED_LIMIT
FLEXO_LOW_SPEED_LIMIT_FORMATTED
FLEXO_LOW_SPEED_TIME_SECS
FLEXO_MAX_SPEED_LIMIT
FLEXO_MIRRORLIST_FALLBACK_FILE
FLEXO_MIRRORLIST_LATENCY_TEST_RESULTS_FILE
FLEXO_MIRRORS_AUTO_ALLOWED_COUNTRIES
FLEXO_MIRRORS_AUTO_HTTPS_REQUIRED
FLEXO_MIRRORS_AUTO_IPV4
FLEXO_MIRRORS_AUTO_IPV6
FLEXO_MIRRORS_AUTO_MAX_SCORE
FLEXO_MIRRORS_AUTO_MIRRORS_BLACKLIST
FLEXO_MIRRORS_AUTO_MIRRORS_RANDOM_OR_SORT
FLEXO_MIRRORS_AUTO_MIRRORS_STATUS_JSON_ENDPOINT
FLEXO_MIRRORS_AUTO_MIRRORS_STATUS_JSON_ENDPOINT_FALLBACKS
FLEXO_MIRRORS_AUTO_NUM_MIRRORS
FLEXO_MIRRORS_AUTO_TIMEOUT
FLEXO_MIRROR_SELECTION_METHOD
FLEXO_MIRRORS_PREDEFINED
FLEXO_NUM_VERSIONS_RETAIN
FLEXO_PORT
FLEXO_REFRESH_LATENCY_TESTS_AFTER
```

If you want to open an issue, please use the Flexo repository (link above) instead of this repository.


## Pushing a new release

the following section is not relevant for end users: It's intended for the maintainer as a reference to describe
the steps for pushing a new release to Docker Hub.

1. Update `Dockerfile`: Bump the `FLEXO_VERSION` (most recent version is [here](https://github.com/nroi/flexo/tags))
   and also consider bumping the Rust version, if a new version is available.
2. Tag the current commit with the given version (e.g. `1.6.9`)
3. Tag the current commit as `latest`: This is important to make sure users who do a simple
   `docker pull nroi/flexo:latest` get the most recent version.
4. Remove the `latest` tag from the remote:
    ```
    git push origin --delete latest
    ```
5. Push both tags to the remote:
    ```
   git push origin latest
   git push origin <most-recent-tag>
   ```
6. Visit https://hub.docker.com/r/nroi/flexo/tags and make sure that both the versioned tag and the `latest` tag
   have been updated.
