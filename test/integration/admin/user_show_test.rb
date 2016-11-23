require "test_helper"

class Admin::UserShowTest < ActionDispatch::IntegrationTest
  def setup
    super
    @path = admin_user_path(user)
  end

  def admin
    @admin ||= admins(:nick)
  end

  def user
    @user ||= users(:reed)
  end

  def site
    @site ||= user.source_site
  end

  def test_user_show
    with_signed_in_admin(admin) do
      with_selected_site(site) do
        visit @path

        within ".admin_content" do
          assert has_content?(user.name)
          assert has_link?(user.email)
        end
      end
    end
  end
end