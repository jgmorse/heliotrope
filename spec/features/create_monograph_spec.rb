require 'rails_helper'

feature 'Create a monograph' do
  context 'a logged in user' do
    before do
      login_as create(:user)
    end

    scenario do
      visit new_curation_concerns_monograph_path
      fill_in 'Title', with: 'Test monograph'
      fill_in 'Date published', with: 'Oct 20th'
      click_button 'Create Monograph'
      expect(page).to have_content 'Test monograph'
      expect(page).to have_content 'Oct 20th'
    end
  end
end
