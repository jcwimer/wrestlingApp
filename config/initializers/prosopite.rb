# frozen_string_literal: true

if Rails.env.local?
  # Like Prosopite's built-in relation preloading exclusion, allow explicit batched
  # preloading: SQLite fingerprints normalize both w1 and w2 to the same identifier.
  Prosopite.allow_stack_paths = [%r{active_record/associations/preloader\.rb.*\bcall\b}]
end
