# frozen_string_literal: true

require "test_helper"

class AuthorizeWriteTest < ActiveSupport::TestCase
  test "dummy authorize_write is configured and is not actor presence" do
    initializer = File.read(Rails.root.join("config/initializers/recording_studio.rb"))

    assert_includes initializer, "config.authorize_write"
    assert_includes initializer, "RecordingStudioAccessible.authorized?"
    assert_includes initializer, "AccessCreationContext.allowed?"
    assert_includes initializer, "recordable.is_a?(RecordingStudio::Access)"
    refute_match(/authorize_write\s*=\s*->\(actor:, \*\*\) \{ actor\.present\? \}/, initializer)
    refute_includes initializer, "allow_unauthorized_writes = true"
  end

  test "dummy authorize_write requires Accessible edit on the root for folders" do
    authorizer = RecordingStudio.configuration.authorize_write

    refute_nil authorizer

    actor = write_probe_user
    root_recording = RecordingStudio.root_recording_for(
      Workspace.create!(name: "Write policy #{SecureRandom.hex(4)}")
    )
    folder = Folder.new(name: "Write policy folder")

    refute authorizer.call(actor: nil, root_recording: root_recording, recordable: folder)
    refute authorizer.call(actor: actor, root_recording: root_recording, recordable: folder)

    RecordingStudioAccessible::AccessCreationContext.allow do
      refute authorizer.call(actor: actor, root_recording: root_recording, recordable: folder)
    end

    bootstrap_owner!(root_recording, actor)

    assert authorizer.call(actor: actor, root_recording: root_recording, recordable: folder)
  end

  test "AccessCreationContext does not let a no-grant actor record a Folder" do
    actor = write_probe_user
    root_recording = RecordingStudio.root_recording_for(
      Workspace.create!(name: "Probe workspace #{SecureRandom.hex(4)}")
    )
    folder = Folder.new(name: "Probe folder")

    assert_raises(RecordingStudio::AuthorizationError) do
      RecordingStudioAccessible::AccessCreationContext.allow do
        RecordingStudio.record!(
          action: "created",
          recordable: folder,
          root_recording: root_recording,
          parent_recording: root_recording,
          actor: actor
        )
      end
    end
  end

  test "bootstrap_owner_access still records Access through AccessCreationContext" do
    actor = write_probe_user
    root_recording = RecordingStudio.root_recording_for(
      Workspace.create!(name: "Bootstrap workspace #{SecureRandom.hex(4)}")
    )

    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root_recording, actor: actor)

    assert result.success?
    assert RecordingStudioAccessible.authorized?(actor: actor, recording: root_recording, role: :admin)
  end

  private

  def write_probe_user
    User.find_or_create_by!(email: "dummy-write-authorizer-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password"
      record.password_confirmation = "Password"
    end
  end

  def bootstrap_owner!(recording, actor)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    raise result.error if result.failure?
  end
end
