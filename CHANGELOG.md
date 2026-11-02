# Changelog

## [0.2.0] - 2026-11-02

* Minor. Boot now logs and raises when host YAML or `config.x.recording_studio_x` is broken. A missing `config/recording_studio_x.yml` is still ignored.
* Align the changelog with git tags through `v0.1.6`.
* Dummy install/config/methods copy names X. Pin non-matrix `ruby/setup-ruby` to Ruby 3.3.
* Token exchange does not persist records.

## [0.1.6] - 2026-10-14

* Dummy Accessible `v0.17.0` and Recording Studio `v4.6.0`.

## [0.1.5] - 2026-10-12

* Dummy Accessible `v0.15.0`.
* Recording Studio `v4.5.0`, Root Switchable `v0.8.0`, and related i18n gem bumps on the way to this tag.

## [0.1.4] - 2026-10-09

* Recording Studio `v4.4.0`.

## [0.1.3] - 2026-10-08

* Recording Studio `v4.3.0`.

## [0.1.2] - 2026-10-05

* Shared dummy-app credentials for RecordingStudio_X.

## [0.1.1] - 2026-10-05

* Recording Studio `v4.2.2`.

## [0.1.0] - 2026-09-24

* `RecordingStudio::X` reads recent search, one post, one user, and a page of user posts.
* Application bearer tokens come from `x_bearer_token` or from an OAuth 2 client-credentials exchange.
* OAuth 1.0a user context and OAuth 2.0 user context are separate from application credentials.
* Pages expose `next_cursor` and `more?`. Rate-limit headers are kept on the result and on API errors.
* Capabilities, four read-only AI tools, the OAuth 2 PKCE provider contract, and `Identity` are included.
* Writes, webhooks, and filtered stream are declared and not called.
* The dummy home search can limit results to a date range and order them by newest or best match. Dates inside the last 7 days use recent search. Older dates use full-archive search.
* The engine application controller lives at `app/controllers/recording_studio/x` so eager load matches `RecordingStudio::X`.

[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.2.0
[0.1.6]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.6
[0.1.5]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.5
[0.1.4]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.4
[0.1.3]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.3
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.0
