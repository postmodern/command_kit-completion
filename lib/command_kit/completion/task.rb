# frozen_string_literal: true

require 'rake/tasklib'

require 'command_kit/options'
require 'command_kit/commands'
require 'completely'
require 'yaml'

module CommandKit
  module Completion
    class Task < Rake::TaskLib

      # The file that the command_kit CLI is defined in.
      #
      # @return [String]
      attr_reader :file

      # The class name of the command_kit CLI.
      #
      # @return [String]
      attr_reader :class_name

      # The output file to write the shell completions to.
      #
      # @return [String]
      attr_reader :output_file

      # Optional input YAML file to read additional shell completions from.
      #
      # @return [String, nil]
      attr_reader :input_file

      # Optional function name to wrap the shell completions within.
      #
      # @return [String, nil]
      attr_reader :function_name

      #
      # Initializes the `command_kit:completion` task.
      #
      # @param [String] file
      #   The file that contains the comand_kit CLI.
      #
      # @param [String] class_name
      #   The class name of the command_kit CLI.
      #
      # @param [String] output_file
      #   The output file to write the completions to.
      #
      # @param [String, nil] input_file
      #   The optional YAML input file of additional completion rules.
      #   See [completely examples] for YAML syntax.
      #
      #   [completely examples]: https://github.com/DannyBen/completely?tab=readme-ov-file#using-the-completely-command-line
      #
      # @param [String] output
      #   The output file to write the completion rules to.
      #
      def initialize(file: ,
                     class_name: ,
                     output_file: ,
                     input_file:    nil,
                     wrap_function: false,
                     function_name: nil)
        @file        = file
        @class_name  = class_name
        @output_file = output_file

        @input_file    = input_file
        @wrap_function = wrap_function
        @function_name = function_name

        define
      end

      #
      # Specifies whether the shell completion logic should be wrapped in a
      # function.
      #
      # @return [Boolean]
      #
      def wrap_function?
        @wrap_function
      end

      #
      # Defines the `command_kit:completion` task.
      #
      def define
        namespace :command_kit do
          task :completion do
            completions  = Completely::Completions.new(completion_rules)
            shell_script = if @wrap_function
                             completions.wrap_function(*@function_name)
                           else
                             completions.script
                           end

            File.write(@output_file,shell_script)
          end
        end
      end

      #
      # Loads the {#class_name} from the {#file}.
      #
      # @return [Class]
      #
      def load_class
        require(@file)
        Object.const_get(@class_name)
      end

      #
      # Generates the completion rules for the given [command_kit] command
      # class.
      #
      # [command_kit]: https://github.com/postmodern/command_kit.rb#readme
      #
      # @param [Class] command_class
      #   The command class.
      #
      # @return [Hash{String => Array<String>}]
      #   The completion rules for the command class and any sub-commands.
      #
      def completion_rules_for(command_class)
        command_name = command_class.command_name
        completions  = {command_name => []}

        if command_class.include?(CommandKit::Options)
          # add all long option flags
          command_class.options.each_value do |option|
            completions[command_name] << option.long
          end
        end

        if command_class.include?(CommandKit::Commands)
          command_class.commands.each do |subcommand_name,subcommand|
            # add all sub-command names
            completions[command_name] << subcommand_name

            # generate completions for the sub-command and merge them in
            completion_rules_for(subcommand.command).each do |subcommand_string,subcommand_completions|
              completions["#{command_name} #{subcommand_string}"] = subcommand_completions
            end
          end

          completions[command_name].concat(command_class.command_aliases.keys)
        end

        # filter out any command's that have no options/sub-commands
        completions.reject! do |command_string,command_completions|
          command_completions.empty?
        end

        return completions
      end

      #
      # Builds the completion rules for the command_kit CLI command, and merges
      # in any additional completion rules from the input file.
      #
      # @return [Hash{String => Array<String>}]
      #
      def completion_rules
        completion_rules = completion_rules_for(load_class)

        if @input_file
          additional_completion_rules = YAML.load_file(@input_file)

          # merge the additional completion rules
          additional_completion_rules.each do |command_string,completions|
            if completion_rules[command_string]
              completion_rules[command_string].concat(completions)
            else
              completion_rules[command_string] = completions
            end
          end
        end

        return completion_rules
      end

    end
  end
end
