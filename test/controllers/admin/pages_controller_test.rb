require "test_helper"

module Admin
  class PagesControllerTest < ActionDispatch::IntegrationTest
    setup do
      post admin_login_url, params: { login: "admin", password: "password" }
    end

    test "index lists pages with their city" do
      get admin_pages_url

      assert_response :success
      assert_match "Регламент турнира", response.body
      assert_match "Москва", response.body
    end

    test "edit page is addressed by id" do
      get edit_admin_page_url(site_pages(:rules_moscow))

      assert_response :success
      assert_match "Регламент турнира", response.body
    end

    test "updates a page" do
      patch admin_page_url(site_pages(:rules_moscow)),
        params: { site_page: { title: "Новые правила", content: "Обновлённый текст" } }

      assert_redirected_to edit_admin_page_url(site_pages(:rules_moscow))
      assert_equal "Новые правила", site_pages(:rules_moscow).reload.title
    end

    test "creates a page for a city" do
      assert_difference -> { SitePage.count }, 1 do
        post admin_pages_url, params: { site_page: {
          city_id: cities(:moscow).id, slug: "faq", title: "Вопросы", content: "Текст"
        } }
      end

      page = SitePage.find_by(slug: "faq", city: cities(:moscow))
      assert_redirected_to edit_admin_page_url(page)
    end

    test "rejects a duplicate slug within a city" do
      assert_no_difference -> { SitePage.count } do
        post admin_pages_url, params: { site_page: {
          city_id: cities(:moscow).id, slug: "rules", title: "Дубль", content: "x"
        } }
      end

      assert_response :unprocessable_entity
    end
  end
end
