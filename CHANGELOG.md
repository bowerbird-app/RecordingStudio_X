# Changelog

## [Unreleased]

## [0.5.1] - 2026-11-18

### Changed
- Root and dummy bundles pin Recording Studio tag `v7.7.1` and FlatPack tag `v0.1.378`.
- Dummy companion pins: Accessible `v0.54.0`, Trashable `v1.2.0`, Metrics `v0.9.1`, Cache `v0.7.0`, Root Switchable `v0.16.0`. Development and test pin API `v1.15.0`, Logs `v0.8.1`, Moveable `v6.0.1`, Icons `v0.4.1`, and Admin `v2.19.0`.
- The dummy adds `config/recording_studio_api.yml` with `shared: {}`. Recording Studio API 1.12 and newer raises at boot when that file is missing.
- The dummy Recording Studio initializer no longer adds `RecordingStudioApi::AdminApi` to `recordable_types`. API 1.1.1 declares that type only when an admin root exists.
- The dummy copies API `v1.15.0` migration `20261117000024_add_owner_to_recording_studio_api_api_clients`. Hosts still run the Recording Studio 7.5 and 7.7 root-index migrations. This dummy does not copy those.

### Upgrade notes
- The gemspec stays `recording_studio` `>= 7.0`, `< 8.0`. Update the host dependency to `recording_studio_x` `~> 0.5.1`. API `v1.15.0` and Accessible `v0.54.0` need Recording Studio `>= 7.7.0`. See `UPGRADING.md`.

## [0.5.0] - 2026-11-15

### Changed
- Require `recording_studio` `>= 7.0`, `< 8.0`. The root and dummy bundles pin Recording Studio tag `v7.0.0` and FlatPack tag `v0.1.376`.
- Dummy companion pins: Accessible `v0.44.0`, Trashable `v0.17.0`, Metrics `v0.9.0`, Cache `v0.6.3`, Root Switchable `v0.16.0`. Development and test pin API `v0.24.0`, Logs `v0.8.0`, Moveable `v5.0.0`, Icons `v0.2.1`, and Admin `v2.16.0`.
- Puma is `8.1.0`. The dummy pins `msgpack` `>= 1.8.7`.
- Seeds and tests that created a root call `create_root_recording!(recordable, actor:)`. Lookups stay on `root_recording_for`.
- The dummy `authorize_write` still requires Accessible `:edit` on the root (or `:admin` for Access rows). A persisted User or API client may create a root, where `root_recording` is nil.
- Dummy seeds use `Recording.kept`. Trashable 0.17 removed `kept_sql`.
- The dummy copies core migration `20261114090000_add_root_recording_id_to_recording_studio_events`.

### Upgrade notes
- See `UPGRADING.md`. Hosts must run Recording Studio `>= 7.0`, `< 8.0`. Create roots with `create_root_recording!`. `root_recording_for` only finds an existing root.

## [0.4.0] - 2026-11-12

### Added
- Register four Recording Studio API read endpoints when `RecordingStudioApi` is loaded:
  `x_search`, `x_get_post`, `x_get_user`, and `x_get_user_posts`. They wrap
  `RecordingStudio::X.search`, `.post`, `.user`, and `.user_posts`. MCP advertises
  registered endpoints on its own; this gem does not add MCP tools. A second
  register of the same handler is skipped. A foreign handler is left for
  Recording Studio API to reject. OpenAPI summaries are type-first
  (`X - Search posts`).
- Dummy host mounts Recording Studio API `v0.21.3` in development and test, with the
  companion pins that API needs to boot.

### Upgrade notes
- See `UPGRADING.md`. Hosts that already mount Recording Studio API get the four
  X reads on each named API. Callers need `:view` on the access grant's root.

## [0.3.0] - 2026-11-06

### Changed
- Require `recording_studio` `>= 6.5.0`. The root and dummy bundles pin Recording Studio tag `v6.5.0` and FlatPack tag `v0.1.341`.
- Dummy companion pins: Accessible `v0.24.2`, Trashable `v0.12.3`, Metrics `v0.7.3`, Cache `v0.6.2`, Root Switchable `v0.11.5`.
- Dummy `/docs/recordings_tree` and `/docs/recordable_types` list and count only recordings the signed-in actor can reach through Accessible (`root_recordings_for` / `recordings_for`). Missing actor or Accessible yields an empty tree and zero counts.
- Dummy `authorize_write` calls Accessible `:edit` on the root for ordinary writes. Access grant/bootstrap writes use `AccessCreationContext` only when the recordable is `RecordingStudio::Access`. Seeds bootstrap the admin user on the three workspace roots.

### Upgrade notes
- See `UPGRADING.md`. Hosts must run Recording Studio `>= 6.5.0`. Dummy docs no longer show every recording in the database.

## [0.2.0] - 2026-11-05

### Changed
- Require `recording_studio` `>= 6.3.0`. The root and dummy bundles pin Recording Studio tag `v6.3.0` and FlatPack tag `v0.1.341`.
- Dummy companion pins: Accessible `v0.24.1`, Trashable `v0.12.2`, Metrics `v0.7.2`, Cache `v0.6.2`, Root Switchable `v0.11.5`.
- Engine controllers call `recording_studio_layout`. `RecordingStudio::X.configuration.layout` defaults to `nil` (core `DEFAULT_LAYOUT`) and is validated by `RecordingStudio::Layout.accept`.
- Dummy Sign-in and home cards no longer pass FlatPack Card `style:`.
- Dummy Sign out uses FlatPack Button `href:` so the link is an `<a>` instead of a dead `<button url>`.
- Root and dummy lockfiles refresh Rails `8.1.4.1`, Rack `>= 3.2.8`, Nokogiri `>= 1.19.5`, Loofah `>= 2.25.3`, and `rails-html-sanitizer` `>= 1.7.2`.
- Remove template leftovers `UPDATE_SUMMARY.md`, `MIGRATION_NOTES.md`, and `docs/gem_template/`.

### Upgrade notes
- See `UPGRADING.md`. Hosts must run Recording Studio `>= 6.3.0`. Call `recording_studio_layout` on engine and host controllers. Do not include `RecordingStudio::UsesDefaultLayout`.

## [0.1.7] - 2026-11-02

* Align `VERSION` and this changelog with git tag `v0.1.6`, then bump the patch.
* Dummy install/config/methods copy names X. Pin non-matrix `ruby/setup-ruby` to Ruby 3.3.
* Token exchange does not persist records. Untrack SimpleCov output.

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_X/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/bowerbird-app/RecordingStudio_X/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.2.0
[0.1.7]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.7
[0.1.6]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.6
[0.1.5]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.5
[0.1.4]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.4
[0.1.3]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.3
[0.1.2]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.2
[0.1.1]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.1
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_X/releases/tag/v0.1.0
