require 'spec_helper'

describe 'users should not see edit collection', :type => :feature do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:jill) { FactoryGirl.create(:jill) }
  let!(:official_collection) do
    Collection.create( title: 'Official') do |c|
      c.apply_depositor_metadata(admin.user_key)
      c.is_official = true
    end
  end
  let!(:admin_collection) do
    Collection.create( title: 'Admin') do |c|
      c.apply_depositor_metadata(admin.user_key)
      c.is_admin_set = true
    end
  end

  after :each do
    cleanup_jetty
  end

  context 'jill' do
    before do
      sign_in jill
    end
    it 'should not be able to see edit for admin collection' do
      visit collections.collection_path(admin_collection)
      expect(page).to_not have_content 'edit'
    end
    it 'should not be able to see edit for official collection' do
      visit collections.collection_path(official_collection)
      expect(page).to_not have_content 'edit'
    end
  end

  context 'admin' do
    before do
      sign_in admin
    end
    it 'should be able to see edit for admin collection' do
      visit collections.collection_path(admin_collection)
      expect(page).to have_content 'Edit'
    end
    it 'should be able to see edit for official collection' do
      visit collections.collection_path(official_collection)
      expect(page).to have_content 'Edit'
    end
  end

end
