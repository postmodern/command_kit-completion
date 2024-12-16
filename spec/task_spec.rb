require 'spec_helper'
require 'command_kit/completion/task'

require 'tempfile'
require 'command_kit/command'
require 'command_kit/commands'

describe CommandKit::Completion::Task do
  let(:class_file)  { './examples/cli' }
  let(:class_name)  { 'Foo::CLI' }
  let(:tempfile)    { Tempfile.new(['command_kit-completion','.sh']) }
  let(:output_file) { tempfile.path }

  let(:fixtures_dir) { File.join(__dir__,'fixtures') }

  subject do
    described_class.new(
      class_file:  class_file,
      class_name:  class_name,
      output_file: output_file
    )
  end

  describe "#define" do
    before { subject }

    it "must define a task for the output file" do
      expect(Rake::Task[output_file]).to_not be_nil
    end

    it "must define a 'command_kit:completion' task" do
      expect(Rake::Task['command_kit:completion']).to_not be_nil
    end

    it "must define a 'completion' task" do
      expect(Rake::Task['completion']).to_not be_nil
    end
  end

  describe "#initialize" do
    it "must set #class_file" do
      expect(subject.class_file).to eq(class_file)
    end

    it "must set #class_name" do
      expect(subject.class_name).to eq(class_name)
    end

    it "must set #output_file" do
      expect(subject.output_file).to eq(output_file)
    end

    it "must default #input_file to nil" do
      expect(subject.input_file).to be(nil)
    end

    it "must default #wrap_function to false" do
      expect(subject.wrap_function).to be(false)
    end

    it "must default #function_name to nil" do
      expect(subject.function_name).to be(nil)
    end
  end

  describe "#load_class" do
    it "must return the Class object for #class_name in #class_file" do
      expect(subject.load_class).to be(Foo::CLI)
    end
  end

  describe "#load_input_file" do
    let(:input_file) { File.join(fixtures_dir,'additional_rules.yml') }

    subject do
      described_class.new(
        class_file:  class_file,
        class_name:  class_name,
        input_file:  input_file,
        output_file: output_file
      )
    end

    it "must load the YAML from the input file" do
      expect(subject.load_input_file).to eq(
        {
          'foo update' => ['$(foo list)']
        }
      )
    end

    context "when the input file contains YAML aliases" do
      let(:input_file) do
        File.join(fixtures_dir,'additional_rules_with_aliases.yml')
      end

      it "must support parsing YAML aliases" do
        expect(subject.load_input_file).to eq(
          {
            'foo update' => ['$(foo list)'],
            'foo up'=> ['$(foo list)']
          }
        )
      end
    end
  end

  describe "#completion_rules_for" do
    context "when given a simple CommandKit::Command class" do
      class TestBasicCommand < CommandKit::Command

        command_name 'test'

        option :foo, desc: 'Foo option'

        option :bar, value: {
                       type: String
                     },
                     desc: 'Bar option'

      end

      let(:command_class) { TestBasicCommand }

      it "must return a Hash of completion rules for the command" do
        expect(subject.completion_rules_for(command_class)).to eq(
          {
            "test" => %w[--foo --bar]
          }
        )
      end

      context "when one of the options accepts a FILE value" do
        class TestCommandWithFILEOption < CommandKit::Command

          command_name 'test'

          option :foo, desc: 'Foo option'

          option :bar, value: {
                         type:  String,
                         usage: 'FILE'
                       },
                       desc: 'Bar option'

        end

        let(:command_class) { TestCommandWithFILEOption }

        it "must add a separate completion rule for the option using the <file> keyword" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test" => %w[--foo --bar],
              'test*--bar' => %w[<file>]
            }
          )
        end
      end

      context "when one of the options accepts a DIR value" do
        class TestCommandWithDIROption < CommandKit::Command

          command_name 'test'

          option :foo, desc: 'Foo option'

          option :bar, value: {
                         type:  String,
                         usage: 'DIR'
                       },
                       desc: 'Bar option'

        end

        let(:command_class) { TestCommandWithDIROption }

        it "must add a separate completion rule for the option using the <directory> keyword" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test" => %w[--foo --bar],
              'test*--bar' => %w[<directory>]
            }
          )
        end
      end

      context "when one of the options accepts a HOST value" do
        class TestCommandWithHOSTOption < CommandKit::Command

          command_name 'test'

          option :foo, desc: 'Foo option'

          option :bar, value: {
                         type:  String,
                         usage: 'HOST'
                       },
                       desc: 'Bar option'

        end

        let(:command_class) { TestCommandWithHOSTOption }

        it "must add a separate completion rule for the option using the <hostname> keyword" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test" => %w[--foo --bar],
              'test*--bar' => %w[<hostname>]
            }
          )
        end
      end

      context "when one of the options accepts a USER value" do
        class TestCommandWithUSEROption < CommandKit::Command

          command_name 'test'

          option :foo, desc: 'Foo option'

          option :bar, value: {
                         type:  String,
                         usage: 'USER'
                       },
                       desc: 'Bar option'

        end

        let(:command_class) { TestCommandWithUSEROption }

        it "must add a separate completion rule for the option using the <user> keyword" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test" => %w[--foo --bar],
              'test*--bar' => %w[<user>]
            }
          )
        end
      end

      context "but the command class does not include CommandKit::Options" do
        class TestCommandWithoutOptions
          include CommandKit::CommandName
          include CommandKit::Usage
          include CommandKit::Arguments

          command_name 'test'
        end

        let(:command_class) { TestCommandWithoutOptions }

        it "must return an empty Hash" do
          expect(subject.completion_rules_for(command_class)).to eq({})
        end
      end
    end

    context "when the command class includes CommandKit::Arguments" do
      context "and has at least one argument" do
        context "and it's named FILE" do
          class TestCommandWithFILEArgument < CommandKit::Command

            command_name 'test'

            option :foo, desc: 'Foo option'

            argument :bar, usage: 'FILE', desc: 'Bar option'

          end

          let(:command_class) { TestCommandWithFILEArgument }

          it "must add '<file>' to the command's completion rule" do
            expect(subject.completion_rules_for(command_class)).to eq(
              {
                "test" => %w[--foo <file>]
              }
            )
          end
        end

        context "and it's named DIR" do
          class TestCommandWithDIRArgument < CommandKit::Command

            command_name 'test'

            option :foo, desc: 'Foo option'

            argument :bar, usage: 'DIR', desc: 'Bar option'

          end

          let(:command_class) { TestCommandWithDIRArgument }

          it "must add '<directory>' to the command's completion rule" do
            expect(subject.completion_rules_for(command_class)).to eq(
              {
                "test" => %w[--foo <directory>]
              }
            )
          end
        end

        context "and it's named HOST" do
          class TestCommandWithHOSTArgument < CommandKit::Command

            command_name 'test'

            option :foo, desc: 'Foo option'

            argument :bar, usage: 'HOST', desc: 'Bar option'

          end

          let(:command_class) { TestCommandWithHOSTArgument }

          it "must add '<hostname>' to the command's completion rule" do
            expect(subject.completion_rules_for(command_class)).to eq(
              {
                "test" => %w[--foo <hostname>]
              }
            )
          end
        end

        context "and it's named USER" do
          class TestCommandWithUSERArgument < CommandKit::Command

            command_name 'test'

            option :foo, desc: 'Foo option'

            argument :bar, usage: 'USER', desc: 'Bar option'

          end

          let(:command_class) { TestCommandWithUSERArgument }

          it "must add '<user>' to the command's completion rule" do
            expect(subject.completion_rules_for(command_class)).to eq(
              {
                "test" => %w[--foo <user>]
              }
            )
          end
        end

        context "but it's named something else" do
          class TestCommandWithArgument < CommandKit::Command

            command_name 'test'

            option :foo, desc: 'Foo option'

            argument :bar, usage: 'BAR', desc: 'Bar option'

          end

          let(:command_class) { TestCommandWithArgument }

          it "must not add additional suggestions to the command's completion rule" do
            expect(subject.completion_rules_for(command_class)).to eq(
              {
                "test" => %w[--foo]
              }
            )
          end
        end
      end

      context "but has no arguments" do
        class TestCommandWithoutArguments < CommandKit::Command

          command_name 'test'

          option :foo, desc: 'Foo option'

        end

        let(:command_class) { TestCommandWithoutArguments }

        it "must not add additional suggestions" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test" => %w[--foo]
            }
          )
        end
      end
    end

    context "when the command class includes CommandKit::Commands" do
      class TestCommandWithSubCommands < CommandKit::Command
        include CommandKit::Commands

        option :global_option, short: '-g',
                               desc:  'A global option'

        class Foo < CommandKit::Command

          option :foo_opt1, desc: 'Foo option 1'

          option :foo_opt2, value: {
                              type: String
                            },
                            desc: 'Foo option 2'

        end

        class Bar < CommandKit::Command

          option :bar_opt1, desc: 'Bar option 1'

          option :bar_opt2, value: {
                              type: String
                            },
                            desc: 'Bar option 2'

        end

        command_name 'test'
        command Foo
        command Bar

      end

      let(:command_class) { TestCommandWithSubCommands }

      it "must add completion rules for the other commands" do
        expect(subject.completion_rules_for(command_class)).to eq(
          {
            "test"     => %w[--global-option -g help foo bar],
            "test foo" => %w[--foo-opt1 --foo-opt2],
            "test bar" => %w[--bar-opt1 --bar-opt2]
          }
        )
      end

      context "when the command has command aliases" do
        class TestCommandWithSubCommandsAndCommandAliases < CommandKit::Command
          include CommandKit::Commands

          option :global_option, short: '-g',
                                 desc:  'A global option'

          class Foo < CommandKit::Command

            option :foo_opt1, desc: 'Foo option 1'

            option :foo_opt2, value: {
                                type: String
                              },
                              desc: 'Foo option 2'

          end

          class Bar < CommandKit::Command

            option :bar_opt1, desc: 'Bar option 1'

            option :bar_opt2, value: {
                                type: String
                              },
                              desc: 'Bar option 2'

          end

          command_name 'test'
          command Foo
          command Bar

          command_aliases['foo2'] = 'foo'
          command_aliases['bar2'] = 'bar'

        end

        let(:command_class) { TestCommandWithSubCommandsAndCommandAliases }

        it "must include the command aliases in the completion rules" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test"     => %w[--global-option -g help foo bar foo2 bar2],
              "test foo" => %w[--foo-opt1 --foo-opt2],
              "test bar" => %w[--bar-opt1 --bar-opt2]
            }
          )
        end
      end

      context "but when one of the commands does not define any options" do
        class TestCommandWithSubCommandsWithNoOptions < CommandKit::Command
          include CommandKit::Commands

          option :global_option, short: '-g',
                                 desc:  'A global option'

          class Foo < CommandKit::Command

            option :foo_opt1, desc: 'Foo option 1'

            option :foo_opt2, value: {
                                type: String
                              },
                              desc: 'Foo option 2'

          end

          class Bar < CommandKit::Command
          end

          command_name 'test'
          command Foo
          command Bar

        end

        let(:command_class) { TestCommandWithSubCommandsWithNoOptions }

        it "must omit the command from the completion rules" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test"     => %w[--global-option -g help foo bar],
              "test foo" => %w[--foo-opt1 --foo-opt2]
            }
          )
        end
      end

      context "and when one of the sub-commands also includes CommandKit::Commands" do
        class TestCommandWithSubSubCommands < CommandKit::Command
          include CommandKit::Commands

          option :global_option, short: '-g',
                                 desc:  'A global option'

          class Foo < CommandKit::Command

            option :foo_opt1, desc: 'Foo option 1'

            option :foo_opt2, value: {
                                type: String
                              },
                              desc: 'Foo option 2'

          end

          class Bar < CommandKit::Command

            include CommandKit::Commands

            option :bar_opt1, desc: 'Bar option 1'

            option :bar_opt2, value: {
                                type: String
                              },
                              desc: 'Bar option 2'

            class Baz < CommandKit::Command

              option :baz_opt1, desc: 'Baz option 1'

              option :baz_opt2, value: {
                                  type: String
                                },
                                desc: 'Baz option 2'

            end

            class Qux < CommandKit::Command

              option :qux_opt1, desc: 'Qux option 1'

              option :qux_opt2, value: {
                                  type: String
                                },
                                desc: 'Qux option 2'

            end

            command Baz
            command Qux

          end

          command_name 'test'
          command Foo
          command Bar

        end

        let(:command_class) { TestCommandWithSubSubCommands }

        it "must recursively include completion rules for the sub-sub-commands" do
          expect(subject.completion_rules_for(command_class)).to eq(
            {
              "test"     => %w[--global-option -g help foo bar],
              "test foo" => %w[--foo-opt1 --foo-opt2],
              "test bar" => %w[--bar-opt1 --bar-opt2 help baz qux],
              "test bar baz" => %w[--baz-opt1 --baz-opt2],
              "test bar qux" => %w[--qux-opt1 --qux-opt2]
            }
          )
        end
      end
    end
  end

  describe "#suggestions_for_argument" do
    context "when given 'FILE'" do
      it "must return ['<file>']" do
        expect(subject.suggestions_for_argument('FILE')).to eq(
          %w[<file>]
        )
      end
    end

    context "when the string ends with '_FILE'" do
      it "must return ['<file>']" do
        expect(subject.suggestions_for_argument('FOO_FILE')).to eq(
          %w[<file>]
        )
      end
    end

    context "when given 'DIR'" do
      it "must return ['<directory>']" do
        expect(subject.suggestions_for_argument('DIR')).to eq(
          %w[<directory>]
        )
      end
    end

    context "when the string ends with '_DIR'" do
      it "must return ['<directory>']" do
        expect(subject.suggestions_for_argument('FOO_DIR')).to eq(
          %w[<directory>]
        )
      end
    end

    context "when given 'PATH'" do
      it "must return ['<file>', '<directory>']" do
        expect(subject.suggestions_for_argument('PATH')).to eq(
          %w[
            <file>
            <directory>
          ]
        )
      end
    end

    context "when the string ends with '_PATH'" do
      it "must return ['<file>', '<directory>']" do
        expect(subject.suggestions_for_argument('FOO_PATH')).to eq(
          %w[
            <file>
            <directory>
          ]
        )
      end
    end

    context "when given 'HOST'" do
      it "must return ['<hostname>']" do
        expect(subject.suggestions_for_argument('HOST')).to eq(
          %w[<hostname>]
        )
      end
    end

    context "when the string ends with '_HOST'" do
      it "must return ['<hostname>']" do
        expect(subject.suggestions_for_argument('FOO_HOST')).to eq(
          %w[<hostname>]
        )
      end
    end

    context "when given 'USER'" do
      it "must return ['<user>']" do
        expect(subject.suggestions_for_argument('USER')).to eq(
          %w[<user>]
        )
      end
    end

    context "when the string ends with '_USER'" do
      it "must return ['<user>']" do
        expect(subject.suggestions_for_argument('FOO_USER')).to eq(
          %w[<user>]
        )
      end
    end
  end

  describe "#completion_rules" do
    it "must load the class from #class_file and return the generated completion rules for it" do
      expect(subject.completion_rules).to eq(
        {
          "foo" => %w[--config-file -C help config list update ls up],
          "foo config" => %w[help get set],
          "foo update" => %w[--quiet -q],
          "foo*--config-file" => %w[<file>],
          "foo*-C" => %w[<file>]
        }
      )
    end

    context "when #input_file is set" do
      let(:input_file) { File.join(fixtures_dir,'additional_rules.yml') }

      subject do
        described_class.new(
          class_file:  class_file,
          class_name:  class_name,
          output_file: output_file,
          input_file:  input_file
        )
      end

      it "must merge the additional completion rules with the generated ones" do
        expect(subject.completion_rules).to eq(
          {
            "foo" => %w[--config-file -C help config list update ls up],
            "foo config" => %w[help get set],
            "foo update" => ['--quiet', '-q', '$(foo list)'],
            "foo*--config-file" => %w[<file>],
            "foo*-C" => %w[<file>]
          }
        )
      end
    end
  end
end
