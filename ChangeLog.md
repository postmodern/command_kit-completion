### 0.2.0 / 2024-04-26

* Also generate completion rules for option's short flags.
* Also generate `<file>`, `<directory>`, `<hostname>`, and `<user>` completion 
  rules for options who's value is named `FILE`, `DIR`, `HOST`, `USER`
  (or ends in `_FILE`, `_DIR`, `_HOST`, `_USER`), respectively.
* Also generate `<file>`, `<directory>`, `<hostname>`, and `<user>` completion 
  rules for the command's first argument if it's named `FILE`, `DIR`, `HOST`,
  `USER` (or ends in `_FILE`, `_DIR`, `_HOST`, `_USER`), respectively.

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
