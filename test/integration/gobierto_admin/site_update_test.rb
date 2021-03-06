# frozen_string_literal: true

require "test_helper"

module GobiertoAdmin
  class SiteUpdateTest < ActionDispatch::IntegrationTest
    include SiteConfigHelpers

    def setup
      super
      @path = edit_admin_site_path(site)
    end

    def admin
      @admin ||= gobierto_admin_admins(:nick)
    end

    def unauthorized_admin
      @unauthorized_admin ||= gobierto_admin_admins(:tony)
    end

    def site
      @site ||= sites(:madrid)
    end

    def privacy_page
      @privacy_page ||= gobierto_cms_pages(:privacy)
    end

    def about_site
      @about_site ||= gobierto_cms_pages(:about_site)
    end

    def test_site_update
      with_auth_modules_for_domains(nil) do
        with_signed_in_admin(admin) do
          visit @path

          within "form.edit_site" do
            fill_in "site_title_translations_es", with: "Site Title"
            fill_in "site_name_translations_es", with: "Site Name"
            fill_in "site_organization_name", with: "Site Location"
            fill_in "site_domain", with: "test.gobierto.test"
            fill_in "site_head_markup", with: "Site Head markup"
            fill_in "site_foot_markup", with: "Site Foot markup"
            fill_in "site_links_markup", with: "Site Links markup"
            fill_in "site_google_analytics_id", with: "UA-000000-01"
            fill_in "site_populate_data_api_token", with: "APITOKEN"
            fill_in "site_raw_configuration_variables", with: <<-YAML
var1: value1
var2: value2
YAML

            attach_file "site_logo_file", "test/fixtures/files/sites/logo-madrid.png"

            within ".site-module-check-boxes" do
              check "Gobierto Development"
            end

            within ".auth-module-check-boxes" do
              check "Null Strategy"
            end

            within ".widget_save" do
              choose "Published"
            end

            select privacy_page.title, from: "site_privacy_page_id"
            select "GobiertoParticipation", from: "site_home_page"

            with_stubbed_s3_file_upload do
              with_stubbed_s3_upload! do
                click_button "Update"
              end
            end
          end

          assert has_message?("Site was successfully updated")

          within "form.edit_site" do
            assert has_field?("site_name_translations_es", with: "Site Name")
            assert has_field?("site_title_translations_es", with: "Site Title")
            assert has_field?("site_organization_name", with: "Site Location")
            assert has_field?("site_domain", with: "test.gobierto.test")
            assert has_field?("site_head_markup", with: "Site Head markup")
            assert has_field?("site_foot_markup", with: "Site Foot markup")
            assert has_field?("site_links_markup", with: "Site Links markup")
            assert has_field?("site_google_analytics_id", with: "UA-000000-01")
            assert has_select?("Privacy page", selected: privacy_page.title)
            assert has_select?("site_home_page", selected: "GobiertoParticipation")
            assert has_field?("site_populate_data_api_token", with: "APITOKEN")
            assert has_field?("site_raw_configuration_variables", with: "var1: value1\r\nvar2: value2\r\n")

            within ".site-module-check-boxes" do
              assert has_checked_field?("Gobierto Development")
            end

            within ".auth-module-check-boxes" do
              assert has_checked_field?("Null Strategy")
            end

            within ".widget_save" do
              assert has_checked_field?("Published")
            end
          end
        end
      end
    end

    def test_change_site_home_page
      with_signed_in_admin(admin) do
        visit @path

        within "form.edit_site" do
          select "GobiertoCms", from: "site_home_page"
          select about_site.title, from: "site_home_page_item_id"

          with_stubbed_s3_file_upload do
            with_stubbed_s3_upload! do
              click_button "Update"
            end
          end
        end

        assert has_message?("Site was successfully updated")

        within "form.edit_site" do
          assert has_select?("site_home_page", selected: "GobiertoCms")
          assert has_select?("Home page", selected: about_site.title)
        end
      end
    end

    def test_change_site_visibility_level
      with_signed_in_admin(admin) do
        visit admin_sites_path

        within "table.site-list tbody tr#site-item-#{site.id}" do
          assert has_content?("Published")
        end

        visit @path

        within "form.edit_site" do
          within ".widget_save" do
            choose "Draft"
            fill_in "site_username", with: "wadus"
            fill_in "site_password", with: "wadus"
          end

          click_button "Update"
        end

        assert has_message?("Site was successfully updated")

        within "form.edit_site" do
          within ".widget_save" do
            assert has_checked_field?("Draft")
          end

          fill_in "site_title_translations_en", with: "New Site Title"
          click_button "Update"
        end

        assert has_message?("Site was successfully updated")
      end
    end

    def test_change_site_visibility_level_without_credentials
      with_signed_in_admin(admin) do
        visit admin_sites_path

        within "table.site-list tbody tr#site-item-#{site.id}" do
          assert has_content?("Published")
        end

        visit @path

        within "form.edit_site" do
          within ".widget_save" do
            choose "Draft"
          end

          click_button "Update"
        end

        assert has_content?("Username can't be blank")
        assert has_content?("Password can't be blank")
      end
    end

    def test_unauthorized_admin_access
      with_signed_in_admin(unauthorized_admin) do
        visit admin_root_path
        assert has_no_link?("Customize site")

        visit @path

        assert has_no_selector?("form.edit_site")
        assert has_content?("You are not authorized to perform this action")
      end
    end

    def test_auth_modules_availability_by_domain
      with_auth_modules_for_domains([sites(:cortegada).domain]) do
        with_signed_in_admin(admin) do
          visit @path
          assert has_no_content?("Null Strategy")

          visit edit_admin_site_path(sites(:cortegada))
          assert has_content?("Null Strategy")
        end
      end
    end
  end
end
