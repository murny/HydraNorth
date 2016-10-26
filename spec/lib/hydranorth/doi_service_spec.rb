require 'spec_helper'

describe Hydranorth::DOIService do
  let(:example_doi_id) { 'doi:10.5072/FK2RF5RK24' }
  let(:generic_file) do
    FactoryGirl.create(:generic_file, title: ['Test Title'],
                                      creator: ['John Doe'],
                                      resource_type: ['Book'])
  end

  describe '.create' do
    it 'should fail if generic file is not valid' do
      VCR.use_cassette('ezid_minting') do
        ezid_identifer = Hydranorth::DOIService.create(GenericFile.new)
        expect(ezid_identifer).to eq(nil)
      end
    end

    it 'should succeed if generic file has valid attributes' do
      expect(generic_file.doi). to eq(nil)
      VCR.use_cassette('ezid_minting') do
        ezid_identifer = Hydranorth::DOIService.create(generic_file)
        expect(ezid_identifer).not_to eq(nil)
        expect(ezid_identifer.datacite_publisher).to eq(Hydranorth::DOIService::PUBLISHER)
        expect(ezid_identifer.datacite_title).to eq(generic_file.title.first)
        expect(ezid_identifer.datacite_resourcetype).to eq('Text/Book')
        expect(ezid_identifer.datacite_publicationyear).to eq('(:unav)')
        expect(ezid_identifer.status).to eq(Ezid::Status::PUBLIC)
        expect(generic_file.doi).not_to eq(nil)
      end
    end
  end

  describe '.update' do
    it 'should successfully update when passing in valid doi and metadata' do
      VCR.use_cassette('ezid_updating') do
        ezid_identifer = Hydranorth::DOIService.update(example_doi_id, title: 'Different Title')
        expect(ezid_identifer).not_to eq(nil)
        expect(ezid_identifer.id).to eq(example_doi_id)
        expect(ezid_identifer.title).to eq('Different Title')
      end
    end
  end

  describe '.unavailable' do
    it 'should successfully update status on doi' do
      VCR.use_cassette('ezid_unavailable') do
        ezid_identifer = Hydranorth::DOIService.unavailable(example_doi_id)
        expect(ezid_identifer).not_to eq(nil)
        expect(ezid_identifer.id).to eq(example_doi_id)
        expect(ezid_identifer.status).to eq(Ezid::Status::UNAVAILABLE)
      end
    end

    it 'should successfully update status on doi with custom message' do
      VCR.use_cassette('ezid_unavailable_with_message') do
        ezid_identifer = Hydranorth::DOIService.unavailable(example_doi_id, 'Example Message')
        expect(ezid_identifer).not_to eq(nil)
        expect(ezid_identifer.id).to eq(example_doi_id)
        expect(ezid_identifer.status).to eq("#{Ezid::Status::UNAVAILABLE} | Example Message")
      end
    end
  end
end
