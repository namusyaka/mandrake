require 'spec_helper'

describe Mandrake::DSL::ConditionalExpression do
  SampleCondition = Class.new(described_class)
  SampleCondition.template '({:condition:})'

  describe "+" do
    let(:a){ Mandrake::DSL::If.new("a and b") }
    let(:b){ Mandrake::DSL::Unless.new("a and b") }
    subject { (a + b).to_s }
    it { should eq('(a and b) && !(a and b)') }
  end

  describe "concat" do
    let(:a){ Mandrake::DSL::If.new("a and b") }
    let(:b){ Mandrake::DSL::Unless.new("a and b") }
    before { a.concat(b) }
    subject { a.to_s }
    it { should eq('(a and b) && !(a and b)') }
  end

  describe "built-in classes" do
    describe "If" do
      let(:condition){ Mandrake::DSL::If.new("a and b") }
      subject { condition.to_s }
      it { should eq('(a and b)') }
    end

    describe "Unless" do
      let(:condition){ Mandrake::DSL::Unless.new("a and b") }
      subject { condition.to_s }
      it { should eq('!(a and b)') }
    end
  end
end
