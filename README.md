# command_kit-completion

[![CI](https://github.com/postmodern/command_kit-completion/actions/workflows/ruby.yml/badge.svg)](https://github.com/postmodern/command_kit-completion/actions/workflows/ruby.yml)
[![Code Climate](https://codeclimate.com/github/postmodern/command_kit-completion.svg)](https://codeclimate.com/github/postmodern/command_kit-completion)
[![Gem Version](https://badge.fury.io/rb/wordlist.svg)](https://badge.fury.io/rb/wordlist)

* [Source](https://github.com/postmodern/command_kit-completion#readme)
* [Issues](https://github.com/postmodern/command_kit-completion/issues)
* [Documentation](https://rubydoc.info/gems/command_kit-complete)

## Description

Adds a rake task that generates shell completion rules for a [command_kit] CLI.
The rake task loads the CLI class and uses the [completely] library to generate
the shell completion rules.

## Features

* Supports automatically generating completion rules from a [command_kit] CLI
  class's options and sub-commands.
* Supports loading additional completion rules from a YAML file.

## Examples

```ruby
require 'command_kit/completion/task'
CommandKit::Completion::Task.new(
  class_file:  './examples/cli',
  class_name:  'Foo::CLI',
  output_file: 'completion.sh'
)
```

## Synopsis

```shell
rake command_kit:completion
```

## Requirements

* [Ruby] >= 3.0.0
* [command_kit] ~> 0.1
* [completely] ~> 0.6

## License

Copyright (c) 2023-2024 Hal Brodigan

See {file:LICENSE.txt} for details.

[Ruby]: https://www.ruby-lang.org/
[command_kit]: https://github.com/postmodern/command_kit.rb#readme
[completely]: https://rubygems.org/gems/completely
