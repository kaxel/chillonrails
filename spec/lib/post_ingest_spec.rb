require 'rails_helper'

describe PostIngest do
  let(:name) { "Test Name" }
  let(:post_ingest) { PostIngest.new(name) }

  describe "#initialize" do
    it "sets the name instance variable" do
      expect(post_ingest.instance_variable_get(:@name)).to eq(name)
    end
  end

  describe "#greeting" do
    it "returns a greeting with the name" do
      expect(post_ingest.greeting).to eq("Hello, Test Name!")
    end
  end
end