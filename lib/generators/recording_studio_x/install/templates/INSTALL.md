# Install RecordingStudio::X

Mount the engine and configure X credentials in the host app.

```bash
bin/rails generate recording_studio_x:install
```

Set the `x_` environment variables, or assign them in `config/initializers/recording_studio_x.rb`.

This gem does not store posts or users. It does not run database migrations.
