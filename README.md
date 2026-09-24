# RecordingStudio::X

`RecordingStudio::X` is the X API client for Recording Studio. A host app uses it to read public posts and users with application credentials. Recording Studio OAuth and Recording Studio Users use the same gem later to authorize a connected X account and to read the X identity for Continue with X.

The gem owns X. It does not own OAuth account storage, user sessions, AI orchestration, or a database of posts.

## Install

Add the gem to the host `Gemfile`.

```ruby
gem "recording_studio_x", github: "bowerbird-app/RecordingStudio_X"
```

Mount the engine from the host app.

```bash
bin/rails generate recording_studio_x:install
```

The generator adds a route and `config/initializers/recording_studio_x.rb`. It does not copy migrations. This gem does not store posts or users.

## Configuration

`RecordingStudio::X::Configuration` reads these environment variables when the object is created.

| Variable | Use |
| --- | --- |
| `x_bearer_token` | Application bearer token, when you already have one |
| `x_consumer_key` | OAuth 1 consumer key, also used to mint an application bearer |
| `x_consumer_key_secret` | OAuth 1 consumer secret. `x_consumer_secret` is the fallback name |
| `x_access_token` | OAuth 1 user access token |
| `x_access_token_secret` | OAuth 1 user access token secret |
| `x_client_id` | OAuth 2 client id for authorization code and PKCE |
| `x_client_secret` | OAuth 2 client secret for a confidential client |

Assign the same names in a configure block when the process should not read the environment. Tests and hosts do this.

```ruby
RecordingStudio::X.configure do |config|
  config.bearer_token = ENV["x_bearer_token"]
  config.consumer_key = ENV["x_consumer_key"]
  config.consumer_secret = ENV["x_consumer_key_secret"]
  config.client_id = ENV["x_client_id"]
  config.client_secret = ENV["x_client_secret"]
end
```

A Rails host can also set `config/recording_studio_x.yml` or `config.x.recording_studio_x`. The engine loads YAML first, then `config.x`, then the initializer.

`configuration.to_h` and `configuration.inspect` report `configured` or `missing`. They do not print secret values.

```ruby
RecordingStudio::X.diagnose
```

Pass `probe: true` to call `GET /2/users/by/username/XDevelopers` with the default credentials. The probe result contains `ok`, the authentication mode, and on failure the error class and HTTP status. It does not contain the error text or any token.

## Application authentication and user authentication

Application authentication is the app itself. Use it for recent search, a public post, a public user, and that user's posts. If `x_bearer_token` is set, the client sends it. If it is missing and the consumer key and secret are set, the client calls `POST https://api.x.com/oauth2/token` with `grant_type=client_credentials` and caches the bearer. X returns the same bearer on later exchanges. Calling that endpoint too often returns HTTP 403 with code 99, so the cache stays until the consumer key, the consumer secret, or the bearer changes.

User authentication is one X account. Pass `credentials:` or `connection:` on the call. The gem does not read the process user token for a normal read while application credentials exist. `identity`, and every write, reject application credentials.

OAuth 1.0a user context uses the consumer pair plus the user access token and secret. The client signs each request with HMAC-SHA1. OAuth 2.0 user context sends the user access token as a bearer. X documents authorization code with PKCE for that token. The access token lasts about two hours. A refresh token requires the `offline.access` scope.

Never send application credentials for an action that must be one person. `Credentials.for_capability` raises `AuthenticationError` when the mode is not allowed.

## Search

Recent search is `GET /2/tweets/search/recent`. The query string is X search syntax. The gem does not rewrite it. Recent search covers about 7 days. `max_results` is 10 to 100. The default at X is 10.

```ruby
result = RecordingStudio::X.search(query: '"BowerBird"', max_results: 10)
result.items.each { |post| post.text }
result.more?
result.next_cursor
```

Optional arguments are `cursor`, `start_time`, `end_time`, and `sort_order`. `cursor` is sent as `next_token`. The call returns one page.

Full-archive search, `GET /2/tweets/search/all`, is pay-per-use and Enterprise. This gem does not call it.

## Posts

```ruby
post = RecordingStudio::X.post(id)
post.id
post.text
post.url
post.author
post.created_at
post.metrics
post.raw
```

The request asks for `created_at`, `public_metrics`, `author_id`, `conversation_id`, `lang`, and `entities`, and expands `author_id`. `post.url` is `https://x.com/{username}/status/{id}` when the author expansion is present. Otherwise it is `https://x.com/i/web/status/{id}`. `post.raw` is the post object from X. `post.to_h` leaves `raw` out.

## Users

```ruby
user = RecordingStudio::X.user(username: "XDevelopers")
user = RecordingStudio::X.user(id: "2244994945")
```

Pass a username or an id, not both. `user.url` is the X profile `https://x.com/{username}`. The website field from X stays on `user.raw["url"]`.

```ruby
page = RecordingStudio::X.user_posts(user.id, max_results: 5, exclude: %w[replies retweets])
```

`GET /2/users/:id/tweets` accepts `max_results` from 5 to 100. X returns at most 3200 posts. `cursor` is sent as `pagination_token`.

## Pagination

A page has `items`, `next_cursor`, `more?`, `rate_limit`, and `raw`. `more?` is true when `meta.next_token` is present. Pass that value as `cursor` on the next call. The gem does not walk every page.

## Rate limits

X sends `x-rate-limit-limit`, `x-rate-limit-remaining`, and `x-rate-limit-reset` on many responses. `RateLimit` keeps `limit`, `remaining`, and `reset_at`. The same object is attached to `RateLimitError`. V1 does not sleep, queue, or retry.

Published per-15-minute limits from the X docs on 24 Sep 2026:

| Endpoint | App | User |
| --- | --- | --- |
| `GET /2/tweets/search/recent` | 450 | 300 |
| `GET /2/tweets/:id` | 450 | 900 |
| `GET /2/users/:id` and by username | 300 | 900 |
| `GET /2/users/:id/tweets` | 10000 | 900 |
| `GET /2/users/me` | user only | 75 |
| `POST /2/tweets` | 10000 per 24 hours | 100 per 15 minutes |

A live response is the limit that applies to the credential in use. The table is the documented ceiling, not a measurement from this environment.

## Errors

| Class | When |
| --- | --- |
| `ConfigurationError` | A required setting is missing |
| `AuthenticationError` | HTTP 401, a rejected token exchange, or a mode the operation does not allow |
| `AuthorizationError` | HTTP 403 |
| `NotFoundError` | HTTP 404, or a 200 body with no record |
| `InvalidRequestError` | HTTP 400, or a blank query, or both user identifiers |
| `InvalidResponseError` | The body is not a JSON object |
| `RateLimitError` | HTTP 429 |
| `ApiError` | Any other HTTP error |
| `NetworkError` | Timeout, socket, or TLS failure. The message is the exception class name |

`status`, `code`, and `rate_limit` are present on the API errors when X sent them. Messages come from the X error object. Tokens are not added to the message.

## Instrumentation

Each request emits `request.recording_studio_x` through `ActiveSupport::Notifications` when `instrumentation_enabled` is true. The payload has `operation`, `endpoint`, `authentication`, `request_count`, `duration_ms`, `result_count`, `error`, and `rate_limit`. `error` is a class name. The payload does not include tokens or secrets.

## Capabilities

`RecordingStudio::X.capabilities` lists operations. Each entry has `operation`, `access` (`read` or `write`), `authentication` (`application`, `user`, or both), `scopes`, `endpoint`, `implemented`, and `side_effects?`.

Implemented reads are `search`, `get_post`, `get_user`, `get_user_posts`, and `identity`. `identity` is user authentication only.

Declared writes are `create_post`, `reply`, `delete_post`, `repost`, `undo_repost`, `like`, `unlike`, `follow`, and `unfollow`. `implemented` is false. There is no method that calls those endpoints. Writes require user authentication. `create_post` and `reply` are `POST /2/tweets` and need `tweet.read`, `users.read`, and `tweet.write`.

## AI tools

If `RecordingStudioAI` is loaded, the engine registers four tools on `to_prepare`. The gem does not depend on `recording_studio_ai`. Call `RecordingStudio::X::AiTools.register!` from a host that boots the registry itself.

| Tool | Operation | Access | Authentication |
| --- | --- | --- | --- |
| `x_search` | `search` | read | application or user |
| `x_get_post` | `get_post` | read | application or user |
| `x_get_user` | `get_user` | read | application or user |
| `x_get_user_posts` | `get_user_posts` | read | application or user |

Each registration sets `read_only` true, `destructive` false, `requires_confirmation` false, and `idempotent` true. The catalog entry also exposes `access`, `authentication`, `scopes`, and `side_effects`. Executors return JSON-ready hashes. Search and user posts return one page, including `next_cursor`.

`RecordingStudioAI` denies a custom tool until the host sets an auth handler. This gem does not change that handler. A write tool is not registered.

## OAuth for a connected account

`RecordingStudio_Oauth` is the authorization server for third parties that call Recording Studio. It does not register external providers and it does not store X tokens. This gem does not add a second OAuth framework.

`RecordingStudio::X::Oauth.provider` is the X-specific contract.

| Key | Value |
| --- | --- |
| `authorize_url` | `https://x.com/i/oauth2/authorize` |
| `token_url` | `https://api.x.com/2/oauth2/token` |
| `identity_endpoint` | `GET /2/users/me` |
| `pkce` | `S256` |
| `sign_in_scopes` | `tweet.read`, `users.read`, `offline.access` |
| `connect_scopes` | sign-in scopes plus `tweet.write`, `like.read`, `like.write`, `follows.read`, `follows.write` |

The host owns redirects, `state`, the callback session, encrypted storage, and which Recording Studio user owns the connection. This gem builds the authorize URL, exchanges the code, and refreshes the token.

```ruby
pkce = RecordingStudio::X::Oauth.pkce
url = RecordingStudio::X.authorize_url(
  redirect_uri: redirect_uri,
  state: state,
  code_challenge: pkce[:challenge]
)
tokens = RecordingStudio::X.exchange_code(
  code: code,
  redirect_uri: redirect_uri,
  code_verifier: pkce[:verifier]
)
tokens = RecordingStudio::X.refresh(refresh_token: tokens.refresh_token)
```

`TokenSet#inspect` and `TokenSet#to_h` omit the access token and the refresh token. `to_h` includes `refresh_token_present`. A confidential client sends HTTP Basic `client_id:client_secret`. A public client sends no client secret. The authorization code expires in about 30 seconds, so the host should exchange it immediately. The gem does not persist the `TokenSet`.

## Continue with X

`RecordingStudio::X.identity` calls `GET /2/users/me` with user credentials and returns an `Identity`.

```ruby
identity.provider    # :x
identity.uid
identity.username
identity.name
identity.image_url
identity.email       # confirmed_email, then email, when X sent one
identity.raw
```

Recording Studio Users signs people in through OmniAuth. It has no provider registry. The host lists `:x` in `omniauth_providers`. If `OmniAuth::Strategies::OAuth2` is defined, the engine loads `OmniAuth::Strategies::X` with name `:x`, PKCE, and the sign-in scopes. Add `omniauth-oauth2` in the host. It is not a dependency of this gem.

Users creates an account from a verified email. X omits email unless the authorization includes `users.email` and the person has a confirmed address. This gem returns `email` when X sends `confirmed_email` or `email`. It does not invent an email and it does not create a Recording Studio user. The Users gem still decides whether a missing email can sign in.

## Connected account calls

Pass the stored connection into a read or, later, a write.

```ruby
RecordingStudio::X.user(username: "ada", connection: connection)
```

`connection` may be a `Credentials` object, an object that responds to `to_x_credentials`, or a hash. A hash with `bearer_token` is application authentication. A hash with `access_token_secret` or `oauth_token_secret` is OAuth 1.0a. Any other user token (`token`, `access_token`, or `oauth2_access_token`) is OAuth 2.0. Missing consumer or client fields are filled from configuration. The hash is not stored.

X owns how those tokens are sent. The OAuth gem owns how they were saved and refreshed.

## Read and write safety

`access` and `side_effects?` are data on every capability and every AI tool. V1 methods only call read endpoints. Declared writes stay `implemented: false` until a host needs them and the developer plan allows the endpoint.

## Limits from the X docs

Checked against docs.x.com on 24 Sep 2026.

* The API origin is `https://api.x.com`.
* Recent search is available to all developers. Full-archive search is not.
* OAuth 2.0 user tokens use authorization code and PKCE. OAuth 1.0a user tokens still work for user context.
* Home timeline is user context only. This gem does not call it.
* Webhooks exist for account activity, X activity, and filtered-stream delivery. They need a CRC check and HTTPS. Filtered stream is also a long-lived `GET /2/tweets/search/stream`. None of that is implemented. `RecordingStudio::X::DEFERRED` lists those products so a later version can add them beside the client instead of inside it.

The live plan attached to a credential can still reject an endpoint that the docs list. On 24 Sep 2026 the consumer key and secret in this environment minted an application bearer, and the OAuth 1.0a user token signed a request. Both calls to `GET /2/users/by/username/XDevelopers` returned HTTP 403, code `https://api.x.com/2/problems/client-forbidden`. X said the developer app must be attached to a Project in the developer portal. Search, post lookup, and user posts were not called after that rejection. The mocked suite does not call X.

```bash
RECORDING_STUDIO_X_LIVE=1 bundle exec ruby -Itest test/live_smoke_test.rb
```

That file reads the public `XDevelopers` user, one page of posts, one post, and a 10-result search. It does not create, like, follow, reply, repost, or delete.
