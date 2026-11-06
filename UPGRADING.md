# Upgrading RecordingStudio::X

## Upgrading to 0.3.0

`0.3.0` requires Recording Studio `>= 6.5.0`. Update the host dependency to
`recording_studio_x` `~> 0.3.0`.

1. No migrations in this gem. X read, OAuth, identity, and AI tool contracts stay the same.
2. Recording Studio `6.5.0` fails closed on `record!` unless the host sets
   `config.authorize_write` (or opts out with `allow_unauthorized_writes`).
   This repository’s dummy authorizer asks Accessible for `:edit` on the root.
3. Dummy `/docs/recordings_tree` and `/docs/recordable_types` counts only
   recordings the current actor can reach through Accessible. Grant access
   (for example `bootstrap_owner_access!`) before you expect those pages to
   show a workspace.
4. This repository’s dummy host pins Recording Studio `v6.5.0`, FlatPack
   `v0.1.341`, Accessible `v0.24.2`, Trashable `v0.12.3`, Metrics `v0.7.3`,
   Cache `v0.6.2`, and Root Switchable `v0.11.5`.

If you are still on `0.2.0` or older, complete that release's notes first.

## Upgrading to 0.2.0

`0.2.0` requires Recording Studio `>= 6.3.0`. Update the host dependency to
`recording_studio_x` `~> 0.2.0`.

1. No migrations in this gem.
2. Read, OAuth, identity, and AI tool contracts stay the same.
3. `RecordingStudio::X.configuration.layout` defaults to `nil`. `nil` uses
   `RecordingStudio.configuration.layout`, then `recording_studio/default_layout`.
   Assign a layout name, `false`, or a callable that accepts `controller:`.
   `RecordingStudio::Layout.accept` validates the value.
4. Call `recording_studio_layout` on engine and host controllers. Do not include
   `RecordingStudio::UsesDefaultLayout` and do not hard-code
   `layout "recording_studio/default_layout"`.
5. This repository’s dummy host pins Recording Studio `v6.3.0`, FlatPack
   `v0.1.341`, Accessible `v0.24.1`, Trashable `v0.12.2`, Metrics `v0.7.2`,
   Cache `v0.6.2`, and Root Switchable `v0.11.5`. Match those tags if you want
   the dummy companion set.
6. Root Switchable `0.11+` accepts `nil`, `false`, a layout name String, or
   `call(controller:)`. The dummy no longer sets `config.layout = :application_layout`.
7. `FlatPack::Card::Component` no longer accepts `style:`. Pass `border:` and
   `variant:`.
8. Use Ruby `3.3.6` or a later 3.3 patch locally. Rails `8.1.4.1` does not parse
   on Ruby `3.3.0`.

If you are still on `0.1.7` or older, complete that release's notes first. The
only extra host step in this release is the Recording Studio 6.x layout change.
