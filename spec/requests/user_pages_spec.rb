require 'rails_helper'

describe 'User pages' do

  subject { page }
  shared_examples_for 'all static pages' do
    it { should have_selector('h1', text: heading) }
    it { should have_title(full_title(page_title)) }
  end

  describe 'Signup page' do
    before { visit signup_path }
    let(:heading)    { 'Sign up' }
    let(:page_title) { 'Sign up' }

    it_should_behave_like 'all static pages'
    it { should have_title('| Sign up') }
  end
end
