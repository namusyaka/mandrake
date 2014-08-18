require 'spec_helper'

describe Mandrake::DSL do
  shared_examples_for('a constant for dsl'){|constant|
    it { expect(constant).to respond_to(:stringify) }}
  it_behaves_like 'a constant for dsl', described_class::Env
  it_behaves_like 'a constant for dsl', described_class::Request
end
