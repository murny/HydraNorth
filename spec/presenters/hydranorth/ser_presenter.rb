require 'spec_helper'

describe Hydranorth::SerPresenter do
  describe ".terms" do
    it "should return a list" do
      expect(described_class.terms).to eq([:resource_type, :title, :ser, :creator, :contributor, :description, :date_created, :license, :subject, :spatial, :temporal, :is_version_of, :source, :related_url, :language])
    end
  end
end
  
