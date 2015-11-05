require 'rails_helper'
describe 'UserPages' do

  describe 'index page' do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit users_path
    end

    it { expect(page).to have_title('All Users')}
    it { expect(page).to have_content('All Users')}

    describe 'pagination' do
      before(:all) { 30.times { FactoryGirl.create(:user)} }
      after(:all) { User.delete_all }

      it { expect(page).to have_selector('div.pagination')}

      it 'should list each users' do
        User.paginate(page: 1).each do |user|
          expect(page).to have_selector('li', text: user.name)
        end
      end
    end

    describe 'delete link' do
      it { expect(page).not_to have_link('Delete')}

      describe 'as an admin user' do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { expect(page).to have_link('delete', href: user_path(User.first))}
        it 'should be able to delete another user' do
          expect do
            click_link('delete', match: :first)
          end.to change(User, :count).by(-1)
        end
        it { expect(page).not_to have_link('delete', href: user_path(admin))}
      end
    end
  end

  describe 'profile page' do
    let(:user) { FactoryGirl.create(:user) }
    before do
      31.times { |n| FactoryGirl.create(:micropost, user: user) }
      visit user_path(user)
    end

    it { expect(page).to have_content(user.name) }
    it { expect(page).to have_title(user.name) }

    describe 'pagenation' do
      after { Micropost.delete_all }

      it { expect(page).to have_selector('div.pagination')}
      it { expect(page).to have_content(user.microposts.count)}

      it 'should list each posts' do
        count = 0
        user.microposts.paginate(page: 1).each do |micropost|
          expect(page).to have_selector('li', text: micropost.content)
          count += 1
        end
        expect(count).to eq(30)
      end

      it 'should list each posts in page 2' do
        count = 0
        user.microposts.paginate(page: 2).each do |micropost|
          expect(page).to have_selector('li', text: micropost.content)
          count += 1
        end
        expect(count).to eq(1)

      end
    end
    describe 'follow/unfollow buttons' do
      let(:other_user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe 'following a user' do
        before { visit user_path(other_user) }

        it 'should increment the followed user count' do
          expect do
            click_button 'Follow'
          end.to change(user.followed_users, :count).by(1)
        end

        it "should increment the other user's followers count" do
          expect do
            click_button 'Follow'
          end.to change(other_user.followers, :count).by(1)
        end

        describe 'toggling the button' do
          before { click_button 'Follow'}
          it { expect(page).to have_xpath("//input[@value='Unfollow']") }
        end
      end

      describe 'unfollowing a user' do
        before do
          user.follow!(other_user)
          visit user_path(other_user)
        end

        it 'should decrement the followed user count' do
          expect do
            click_button 'Unfollow'
          end.to change(user.followed_users, :count).by(-1)
        end

        it "should decrement the other user's followers count" do
          expect do
            click_button 'Unfollow'
          end.to change(other_user.followers, :count).by(-1)
        end

        describe 'toggling the button' do
          before { click_button 'Unfollow' }
          it { expect(page).to have_xpath("//input[@value='Follow']") }
        end
      end
    end
  end

  describe 'signup page' do
    before { visit signup_path }
    let(:submit) { 'Create my account' }

    describe 'with invalid information'do
      it 'should not create a user' do
        expect { click_button submit }.not_to change(User, :count)
      end

      describe 'after submittion' do
        before { click_button submit }
        it { expect(page).to have_title('Sign Up')}
        it { expect(page).to have_content('error')}
      end
    end

    describe 'with valid information' do
      before do
        fill_in 'Name',         with: 'Example User'
        fill_in 'Email',        with: 'user@example.com'
        fill_in 'Password',     with: 'foobar'
        fill_in 'Confirmation', with: 'foobar'
      end

      it 'should create a user' do
        expect { click_button submit }.to change(User, :count).by(1)
      end

      describe 'after saving the user' do
        before { click_button submit }
        let(:user) { User.find_by(email: 'user@example.com')}

        it { expect(page).to have_link('Sign out') }
        it { expect(page).to have_title(user.name) }
        it { expect(page).to have_selector('div.alert.alert-success', text: 'Welcome')}
      end

    end

    it { expect(page).to have_content('Sign Up')}
    it { expect(page).to have_title(full_title('Sign Up'))}
  end

  describe 'edit' do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe 'forbidden attributes' do
      let(:params) do
        {user: {admin: true, password: user.password, password_confirmation: user.password}}
      end
      before do
        sign_in user , no_capybara: true
        patch user_path(user), params
      end

      it { expect(user.reload).not_to be_admin}
    end

    describe 'page' do
      it { expect(page).to have_content('Update your profile') }
      it { expect(page).to have_title('Edit user') }
      it { expect(page).to have_link('change', href: 'http://gravatar.com/emails') }
    end

    describe 'with invalid information' do
      before { click_button 'Save changes'}
      it { expect(page).to have_content('error') }
    end

    describe 'with valid information' do
      let(:new_name)  { 'New Name' }
      let(:new_email) { 'new@example.com' }
      before do
        fill_in 'Name',  with: new_name
        fill_in 'Email', with: new_email
        fill_in 'Password',         with: user.password
        fill_in 'Confirm', with: user.password
        click_button 'Save changes'
      end

      it { expect(page).to have_title(new_name) }
      it { expect(page).to have_selector('div.alert.alert-success') }
      it { expect(page).to have_link('Sign out', href: signout_path) }
      specify { expect(user.reload.name).to  eq new_name }
      specify { expect(user.reload.email).to eq new_email }
    end
  end

  describe 'profile page' do
    let(:user) { FactoryGirl.create(:user) }
    let(:other) { FactoryGirl.create(:user) }
    let!(:m1)  { FactoryGirl.create(:micropost, user: user, content: 'Foo') }
    let!(:m2)  { FactoryGirl.create(:micropost, user: user, content: 'Bar') }

    before { visit user_path(user) }

    it { expect(page).to have_title(user.name) }
    it { expect(page).to have_content(user.name) }

    describe 'microposts' do
      it { expect(page).to have_content(m1.content) }
      it { expect(page).to have_content(m2.content) }
      it { expect(page).to have_content(user.microposts.count) }
    end

    describe 'should not have delete link with auth user' do
      before do
        sign_in user
        visit user_path(other)
      end

      it { expect(page).not_to have_link('Delete')}
    end
  end

  describe 'following/followers' do
    let(:user) {FactoryGirl.create(:user)}
    let(:other_user) {FactoryGirl.create(:user)}
    before { user.follow!(other_user) }

    describe 'followed users' do
      before {
        sign_in user
        visit following_user_path(user)
      }

      it { expect(page).to have_title('Following')}
      it { expect(page).to have_selector('h3', text: 'Following')}
      it { expect(page).to have_link(other_user.name,  href: user_path(other_user))}
    end


    describe 'folloing users' do
      before {
        sign_in other_user
        visit followers_user_path(other_user)
      }

      it { expect(page).to have_title('Followers')}
      it { expect(page).to have_selector('h3', text: 'Followers')}
      it { expect(page).to have_link(user.name,  href: user_path(user))}
    end
  end
end
