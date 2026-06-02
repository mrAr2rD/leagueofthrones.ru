require "test_helper"

module Admin
  class CitiesControllerTest < ActionDispatch::IntegrationTest
    setup do
      post admin_login_url, params: { login: "admin", password: "password" }
    end

    test "index lists cities" do
      get admin_cities_url

      assert_response :success
      assert_match "Москва", response.body
    end

    test "creates a city" do
      assert_difference -> { City.count }, 1 do
        post admin_cities_url, params: { city: {
          name: "Казань", slug: "kazan", register_url: "https://t.me/kazan",
          default_format: "classic", position: 5
        } }
      end

      assert_redirected_to admin_cities_url
      assert_equal "classic", City.find_by(slug: "kazan").default_format
    end

    test "rejects an invalid slug" do
      assert_no_difference -> { City.count } do
        post admin_cities_url, params: { city: {
          name: "Плохой", slug: "Bad Slug!", default_format: "mother_of_dragons"
        } }
      end

      assert_response :unprocessable_entity
    end

    test "updates a city" do
      patch admin_city_url(cities(:moscow)), params: { city: { name: "Москва-Сити" } }

      assert_redirected_to admin_cities_url
      assert_equal "Москва-Сити", cities(:moscow).reload.name
    end

    test "destroys a city" do
      city = City.create!(name: "Удаляемый", slug: "delete-me", default_format: "classic")

      assert_difference -> { City.count }, -1 do
        delete admin_city_url(city)
      end

      assert_redirected_to admin_cities_url
    end
  end
end
