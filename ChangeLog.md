### 0.1.2 / 2023-12-18

* Fix namespace conflict between `FileUtils` and `CommandKit::FileUtils`.

### 0.1.1 / 2023-12-18

* Ensure that the parent directory of the output file exists before writing to
  the output file.

### 0.1.0 / 2023-12-18

* Initial release:
  * Supports automatically generating completion rules from a [command_kit] CLI
    class's options and sub-commands.
  * Supports loading additional completion rules from a YAML file.

[command_kit]: https://github.com/postmodern/command_kit.rb#readme
