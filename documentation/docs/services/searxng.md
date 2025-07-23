# SearXNG

SearXNG is a privacy-respecting, hackable metasearch engine. It provides search results from multiple sources without tracking or profiling the user.

## Key Features

- **Privacy-Respecting**: Does not track or store user data.
- **Metasearch**: Aggregates results from multiple search engines.
- **Highly Customizable**: Can be configured to use a wide variety of search engines and plugins.

## Service Configuration

- **Build Context**: `services/searxng`
- **Port**: `8888`

## Environment Variables

- `SEARXNG_SECRET`: A secret key for the SearXNG instance.
- `SEARXNG_REDIS_URL`: The URL of the Redis instance for caching.
