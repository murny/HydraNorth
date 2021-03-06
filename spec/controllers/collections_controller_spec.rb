require 'spec_helper'

describe CollectionsController, type: :controller do
    routes { Hydra::Collections::Engine.routes }

  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user)  { FactoryGirl.create(:alice) }

  describe 'facet limiting' do
    let(:collection) do
      Collection.new(title: "Personal Collection") do |c|
        c.apply_depositor_metadata(user)
        c.save
      end
    end

    it "should attach collection facets properly" do
      results = controller.attach_collection_facet('/', collection)
      expect(results).to eq('/?f%5BhasCollection_ssim%5D%5B%5D=Personal+Collection')
      results = controller.attach_collection_facet('/?asdf=1234', collection)
      expect(results).to eq('/?asdf=1234&f%5BhasCollection_ssim%5D%5B%5D=Personal+Collection')
    end
  end

  describe "#edit" do
    let(:collection) do
      Collection.new(title: "Personal Collection") do |c|
        c.apply_depositor_metadata(user)
        c.save
      end
    end

    let(:official_collection) do
      Collection.new(title: "Official Collection that can be edited") do |c|
        c.apply_depositor_metadata(user)
        c.is_official = true
        c.save
      end
    end

    let(:admin_collection) do
      Collection.new(title: "Official Collection -Admin set") do |c|
        c.apply_depositor_metadata(user)
        c.is_official = true
        c.is_admin_set = true
        c.save
      end
    end


    before { sign_in other_user }
    it "cannot edit other people's personal collection" do
      get :edit, id: collection
      expect(flash[:alert]).to eq "You do not have sufficient privileges to edit this document"
    end
    it "can edit official collection" do
      get :edit, id: official_collection
      expect(flash[:alert]).to be_nil
    end
    it "cannot edit admin collection" do
      get :edit, id: admin_collection
      expect(flash[:alert]).to eq "You do not have sufficient privileges to edit this document"
    end

  end

  describe "#update" do
    before { sign_in user }

    let(:community) do
       Collection.new(title: "Community Title") do |community|
         community.apply_depositor_metadata(user.user_key)
         community.is_community = true
         community.is_official = true
         community.save
       end
    end

    let(:collection) do
      Collection.new(title: "Collection Title") do |collection|
        collection.apply_depositor_metadata(user.user_key)
        collection.save
      end
    end

    context "a collections members" do
      before do
        community.members = [collection]
        community.save
        collection.belongsToCommunity = [community.id]
        collection.save
        @asset1 = GenericFile.new(title: ["First of the Assets"])
        @asset1.apply_depositor_metadata(user.user_key)
        @asset1.save
        @asset2 = GenericFile.new(title: ["Second of the Assets"], depositor: user.user_key)
        @asset2.apply_depositor_metadata(user.user_key)
        @asset2.save
        @asset3 = GenericFile.new(title: ["Third of the Assets"], depositor:'abc')
        @asset3.apply_depositor_metadata(user.user_key)
        @asset3.save
      end

      it "should set collection on members" do
        put :update, id: collection, collection: {members:"add"}, batch_document_ids: [@asset3.id, @asset1.id, @asset2.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)

        expect(assigns[:collection].materialized_members).to match_array [@asset2, @asset3, @asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq @asset2.id
        afterupdate = GenericFile.find(@asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]

        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['hasCollection_ssim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["hasCollection_ssim"]).to eq ["Collection Title"]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""], fl:['belongsToCommunity_tesim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["belongsToCommunity_tesim"]).to match_array [community.id]
        put :update, id: collection, collection: {members:"remove"}, batch_document_ids: [@asset2]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['id',Solrizer.solr_name(:collection)]}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq @asset2.id
        afterupdate = GenericFile.find(@asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to be_nil

        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""],fl:['hasCollection_ssim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["hasCollection_ssim"]).to_not eq ["Collection Title"]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@asset2.id}\""], fl:['belongsToCommunity_tesim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["belongsToCommunity_tesim"]).to_not eq [community.id]

      end
    end

    context "a community" do
      before do
        @file = GenericFile.new(title: ["File belongs to community"]).tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save
        end

        @file2 = GenericFile.new(title: ["File belongs to collection"]).tap do |f|
          f.apply_depositor_metadata(user.user_key)
          f.save
        end

        @child_collection = Collection.new(title: "Child Collection to Community").tap do |c|
          c.apply_depositor_metadata(user.user_key)
          c.is_official = true
          c.save
        end

        @file2.hasCollectionId = [@child_collection.id]
        @file2.hasCollection = [@child_collection.title]
        @file2.save
        @child_collection.member_ids = [@file2.id]
        @child_collection.save

        @logo_file = fixture_file_upload('logo.jpg', 'image/jpg')

      end

      it "should add logo" do
        put :update, id: community, collection: {logo: @logo_file}
        expect(response).to redirect_to routes.url_helpers.collection_path(community)
      end

      it "should set belongsToCommunity on member file" do
        put :update, id: community, collection: { members: "add" }, batch_document_ids: [@file.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(community)
        expect(assigns[:collection].members.map(&:id)).to match_array [@file.id]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@file.id}\""],fl:['belongsToCommunity_tesim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["belongsToCommunity_tesim"]).to eq [community.id]

      end

      it "should set belongsToCommunity on member collection and their children files" do
        put :update, id: community, collection: { members: "add" }, batch_document_ids: [@child_collection.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(community)

        expect(assigns[:collection].materialized_members).to match_array [@child_collection]

        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@child_collection.id}\""],fl:['belongsToCommunity_tesim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["belongsToCommunity_tesim"]).to eq [community.id]

        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params:{fq:["id:\"#{@file2.id}\""],fl:['belongsToCommunity_tesim']}
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first

        expect(doc["belongsToCommunity_tesim"]).to eq [community.id]
      end

    end

  end
end
