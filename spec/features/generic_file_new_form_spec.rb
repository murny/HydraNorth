require 'spec_helper'

describe 'generic file new', type: :feature do
  let(:user) { FactoryGirl.create :user }

  before do
    sign_in user
    visit '/files/new'
  end

  describe 'unfold agreement div', js: true do
    it "allows toggling of read more" do
      within("#local") do
        expect(page).not_to have_css('div#agreement-text-multiple.unfolded')
        click_button('unfold-agreement-multiple')
        expect(page).to have_css('div#agreement-text-multiple.unfolded')
        click_button('unfold-agreement-multiple')
        expect(page).not_to have_css('div#agreement-text-multiple.unfolded')
      end
  end
  end

  describe 'new item fields', js: true do
    # This is a very poor test... Sufia being stupid I am assuming?
    # we are checking if we have a select tag that is not multiple but still uses an array???
    it "should not allow multiple resource_type selections, but assign to an array" do
      skip 'Test fails if stack is being slow, very flaky, disable this as not really testing anything of value'

      within("form#fileupload") do
        check('terms_of_service')
        attach_file "files[]", [fixture_path + '/world.png']
        click_button('main_upload_start')
      end

      expect(page).to have_xpath('//select[@name="generic_file[resource_type][]" and not(@multiple)]')
    end
  end

  describe 'check form fields', js: true do

    let!(:community1) do
      Collection.create( title: 'Community 1') do |c|
        c.apply_depositor_metadata(user.user_key)
        c.is_community = true
        c.is_official = true
      end
    end

    let!(:community2) do
      Collection.create( title: 'Community 2') do |c|
        c.apply_depositor_metadata(user.user_key)
        c.is_community = true
        c.is_official = true
        c.is_admin_set = true
      end
    end

    after do
      cleanup_jetty
    end

    it "sets up fields properly" do
      skip 'Test fails if stack is being slow, very flaky, disable this as not really testing anything of value'

      within("form#fileupload") do
        check('terms_of_service')
        choose('resource_type_Computing_Science_Technical_Report')
        page.attach_file "files[]", [fixture_path + '/world.png']
        click_button('main_upload_start')
      end

      within("form#new_generic_file") do
        expect(find_field('Description or Abstract')).to have_content ''
        expect(find_field('Date Created')).to have_content ''
        expect(find_field('generic_file_title')).to have_content ''
        expect(page).to have_content 'world.png'
        expect(find_field('Creator')).to have_content ''
        click_button("Show Additional Descriptive Fields")
        expect(page).not_to have_field('Identifier')

        # Check if its CSTR report id field is present
        expect(page).to have_field('generic_file_trid')

      end

      expect(page).to have_xpath('//select[@name="generic_file[belongsToCommunity][]"]/option[text() = "Community 1"]')
      expect(page).not_to have_xpath('//select[@name="generic_file[belongsToCommunity][]"]/option[text() = "Community 2"]')
    end
  end
end
