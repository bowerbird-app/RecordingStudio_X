# Changelog

## [0.1.0] - 2026-09-24

* `RecordingStudio::X` reads recent search, one post, one user, and a page of user posts.
* Application bearer tokens come from `x_bearer_token` or from an OAuth 2 client-credentials exchange.
* OAuth 1.0a user context and OAuth 2.0 user context are separate from application credentials.
* Pages expose `next_cursor` and `more?`. Rate-limit headers are kept on the result and on API errors.
* Capabilities, four read-only AI tools, the OAuth 2 PKCE provider contract, and `Identity` are included.
* Writes, webhooks, filtered stream, and full-archive search are declared and not called.

[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.0
