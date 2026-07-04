- when bazel needs to be invoked, use system's bzl wrapper instead of bazel directly, e.g., bzl run //... instead of bazel run //...
- when writing tests using mockery-generated mocks, prefer using the mock's expector over the "On" function directly
- when writing git commit messages, be clear and concise with the description of changes.  Do not include an itemized list of changes,
  and do not include special decorators on the subject line.  The subject line should fit a 72 character limit, and any necessary
  elaboration must be added as a paragraph in the body of the commit message.
- never include error message assertions in tests.  To validate error types, use paradigms appropriate to the specific apis being tested.
- you don't have to keep telling me that I'm absolutely right.  I already know that.
