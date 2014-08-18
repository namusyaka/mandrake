require 'spec_helper'

describe Mandrake::DSL::Stringify do
  Sample = Class.new(described_class)
  context "basic" do
    subject { Sample.stringify.unknown_method.eq('hello').to_s }
    it { should eq('sample.unknown_method == "hello"') }
  end

  describe "arguments" do
    context "with Fixnum" do
      subject { Sample.stringify.hello_world(1234).eq('1234').to_s }
      it { should eq('sample.hello_world(1234) == "1234"') }
    end

    context "with String" do
      subject { Sample.stringify.hello_world('1234').eq('1234').to_s }
      it { should eq('sample.hello_world("1234") == "1234"') }
    end

    context "with Array" do
      subject { Sample.stringify.hello_world([1, 2, 3, 4]).eq([1, 2, 3, 4]).to_s }
      it { should eq('sample.hello_world([1, 2, 3, 4]) == [1, 2, 3, 4]') }
    end

    context "with Hash" do
      subject { Sample.stringify.hello_world({a: :hey}).eq({a: :hey}).to_s }
      it { should eq('sample.hello_world({:a=>:hey}) == {:a=>:hey}') }
    end
  end


  describe "[]" do
    subject { Sample.stringify.method_that_does_not_exist['Hello'].eq('Hello World').to_s }
    it { should eq('sample.method_that_does_not_exist["Hello"] == "Hello World"') }
  end

  describe "and" do
    subject { Sample.stringify.a.eq('Hello World').and(Sample.stringify.b.start_with?("/public")).to_s }
    it { should eq('sample.a == "Hello World" && sample.b.start_with?("/public")') }
  end

  describe "or" do
    subject { Sample.stringify.a.eq('Hello World').or(Sample.stringify.b.start_with?("/public")).to_s }
    it { should eq('sample.a == "Hello World" || sample.b.start_with?("/public")') }
  end

  context "use == instead of eq" do
    subject { Sample.stringify.a == 'hello'}
    it { should eq('sample.a == "hello"') }
  end

  context "without eq" do
    subject { Sample.stringify.method_that_does_not_exist['Hello'].include?('howl').to_s }
    it { should eq('sample.method_that_does_not_exist["Hello"].include?("howl")') }
  end

  describe "#reset_string" do
    subject { Sample.stringify.method_that_does_not_exist.reset_string.hey['hello'].include?('howl').to_s }
    it { should eq('sample.hey["hello"].include?("howl")') }
  end
end
