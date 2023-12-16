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

  describe "#completion_rules_for" do
    context "when given a simple CommandKit::Command class" do
      class TestBasicCommand < CommandKit::Command

        command_name :test

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

          command_name :test

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

          command_name :test

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

          command_name :test

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

          command_name :test

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

          command_name :test
        end

        let(:command_class) { TestCommandWithoutOptions }

        it "must return an empty Hash" do
          expect(subject.completion_rules_for(command_class)).to eq({})
        end
      end
    end

    context "when the command class includes CommandKit::Commands" do
      context "but when one of the commands does not define any options" do
        it "must omit the command from the completion rules"
      end

      context "and when one of the sub-commands also includes CommandKit::Commands" do
      end
    end
  end

  describe "#completion_rules" do
    it "must load the class from #class_file and return the generated completion rules for it"

    context "when #input_file is set" do
      it "must merge the additional completion rules with the generated ones"
    end
  end
end
