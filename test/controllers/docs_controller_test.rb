# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require_relative "../test_helper"
require_relative "../dummy/config/environment"

require "devise/test/integration_helpers"
require "rails/test_help"

class DocsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TEST_PASSWORD = "DocsTestPassword!2026"

  setup do
    @user = User.find_or_create_by!(email: "docs-test@example.com") do |user|
      user.password = TEST_PASSWORD
      user.password_confirmation = TEST_PASSWORD
    end

    sign_in @user
    Current.actor = @user
  end

  teardown do
    Current.actor = nil
  end

  test "install page renders successfully" do
    get docs_install_path
    assert_response :success
    assert_select "h1", text: "Install"
    assert_select "h1", count: 1
    assert_includes response.body, "Step 1"
    assert_includes response.body, "Put the gem in the host bundle"
    assert_includes response.body, "bundle add recording_studio_x"
  end

  test "config page renders successfully" do
    get docs_config_path
    assert_response :success
    assert_select "h1", text: "Config"
    assert_select "h1", count: 1
    assert_includes response.body, "Bearer, OAuth 1, and OAuth 2 client settings for X."
    assert_includes response.body, "config.bearer_token"
  end

  test "recordable types page renders configured recordables dynamically" do
    summary_data = create_recordable_type_summary_data

    get docs_recordable_types_path
    response_text = response.body.gsub(/\s+/, " ").strip

    assert_response :success
    assert_select "h1", text: "Recordable types"
    assert_select "h1", count: 1
    assert_includes(
      response.body,
      "The list below comes from RecordingStudio.recordable_declarations and parent/root introspection."
    )
    assert_includes response.body, "Workspace"
    assert_includes response.body, "Folder"
    assert_includes response.body, "Page"
    assert_includes response_text, "Root recordable"
    assert_includes response_text, "Child recordable"
    assert_includes response_text, "Allowed parents: Workspace, Folder"
    assert_includes response_text, summary_data[:workspace]
    assert_includes response_text, summary_data[:folder]
  end

  test "recordable types page includes dummy app defaults" do
    get docs_recordable_types_path

    assert_response :success
    assert_includes response.body, "Workspace"
    assert_includes response.body, "Folder"
    assert_includes response.body, "Page"
  end

  test "recordings tree page renders successfully" do
    workspace = Workspace.create!(name: "Tree Workspace")
    root_recording = RecordingStudio.root_recording_for(workspace)
    bootstrap_owner!(root_recording)
    folder = Folder.create!(name: "Reference")
    folder_recording = record_child(folder, root_recording, root_recording)
    page = Page.create!(title: "API")
    record_child(page, root_recording, folder_recording)

    get docs_recordings_tree_path

    assert_response :success
    assert_select "h1", text: "Recordings tree"
    assert_select "h1", count: 1
    assert_includes response.body, "Workspace: Tree Workspace"
    assert_includes response.body, "Folder: Reference"
    assert_includes response.body, "Page: API"
    refute_includes response.body, "Access boundary"
    refute_includes response.body, "Access: Admin"
    assert_select "div[role='tree']", count: 1
    assert_select "[role='treeitem']", minimum: 3
    refute_includes response.body, "Current structure"
    refute_includes response.body, "This tree is generated from RecordingStudio::Recording records"
  end

  test "recordings tree hides recordings the actor cannot access" do
    visible = Workspace.create!(name: "Visible Tree Workspace")
    visible_root = RecordingStudio.root_recording_for(visible)
    bootstrap_owner!(visible_root)

    hidden = Workspace.create!(name: "Hidden Tree Workspace")
    RecordingStudio.root_recording_for(hidden)

    get docs_recordings_tree_path

    assert_response :success
    assert_includes response.body, "Workspace: Visible Tree Workspace"
    refute_includes response.body, "Workspace: Hidden Tree Workspace"
  end

  test "recordings tree is empty when the actor has no grants" do
    RecordingStudio.root_recording_for(Workspace.create!(name: "Orphan Tree Workspace"))

    get docs_recordings_tree_path

    assert_response :success
    assert_includes response.body, "No active recordings found."
    refute_includes response.body, "Workspace: Orphan Tree Workspace"
  end

  test "recordable types counts fail closed when the actor has no grants" do
    RecordingStudio.root_recording_for(Workspace.create!(name: "Orphan Count Workspace"))
    Folder.create!(name: "Orphan Count Folder")

    get docs_recordable_types_path

    assert_response :success
    assert_includes response.body, "Workspace"
    assert_includes response.body, "Folder"
    assert_includes response.body, "0 recordings point to this type"
    assert_includes response.body, "0 recordables in the database"
    refute_match(/[1-9]\d* recordings point to this type/, response.body)
  end

  test "gem_views page renders successfully" do
    get docs_gem_views_path
    assert_response :success
    assert_select "h1", text: "Gem Views"
    assert_select "h1", count: 1
    assert_select "table", minimum: 1
    legacy_view = %w[gem template].join("_")
    refute_includes response.body, "app/views/#{legacy_view}/home/index.html.erb"
  end

  test "methods page renders successfully" do
    get docs_methods_path
    assert_response :success
    assert_select "h1", text: "Methods"
    assert_select "h1", count: 1
    assert_includes response.body, "Read posts, people, and identity through RecordingStudio::X."
    assert_includes response.body, "RecordingStudio::X.search"
    assert_includes response.body, "page = RecordingStudio::X.search"
  end

  test "authenticated docs pages use the recording studio default layout" do
    get docs_install_path

    assert_response :success
    assert_select "h1", count: 1
    assert_select "body[data-recording-studio-default-layout='true']", count: 1
    assert_select "nav[aria-label='Page navigation']", count: 1
    refute_includes response.body, "flat-pack-sidebar-layout"
  end

  private

  def create_recordable_type_summary_data
    workspace_recordings_before = accessible_type_recordings("Workspace").count
    workspaces_before = accessible_type_recordings("Workspace").distinct.count(:recordable_id)
    folder_recordings_before = accessible_type_recordings("Folder").count
    folders_before = accessible_type_recordings("Folder").distinct.count(:recordable_id)

    workspace = Workspace.create!(name: "Counted Workspace")
    root_recording = RecordingStudio.root_recording_for(workspace)
    bootstrap_owner!(root_recording)
    folder = Folder.create!(name: "Counted Folder")
    record_child(folder, root_recording, root_recording)

    2.times do
      RecordingStudio.root_recording_for(Workspace.create!(name: "Counted Workspace #{SecureRandom.hex(4)}"))
    end

    {
      workspace: recordable_type_summary(
        workspace_recordings_before + 1,
        workspaces_before + 1
      ),
      folder: recordable_type_summary(
        folder_recordings_before + 1,
        folders_before + 1
      )
    }
  end

  def accessible_type_recordings(type_name)
    ids = RecordingStudioAccessible.root_recordings_for(actor: @user).flat_map do |root|
      descendant_ids = RecordingStudioAccessible.recordings_for(actor: @user, parent_recording: root)
                                                .where.not(recordable_type: "RecordingStudio::Access")
                                                .pluck(:id)
      [root.id, *descendant_ids]
    end

    RecordingStudio::Recording.where(id: ids, recordable_type: type_name)
  end

  def recordable_type_summary(recording_count, recordable_count)
    "#{ActionController::Base.helpers.pluralize(recording_count, 'recording')} point to this type " \
      "• #{ActionController::Base.helpers.pluralize(recordable_count, 'recordable')} in the database"
  end

  def record_child(recordable, root_recording, parent_recording)
    RecordingStudio.record!(
      action: "created",
      recordable: recordable,
      root_recording: root_recording,
      parent_recording: parent_recording,
      actor: @user
    ).recording
  end

  def bootstrap_owner!(recording, actor: @user)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    raise result.error if result.failure?
  end
end
