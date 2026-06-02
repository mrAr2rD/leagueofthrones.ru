require "test_helper"

module Admin
  class ToursControllerTest < ActionDispatch::IntegrationTest
    setup do
      post admin_login_url, params: { login: "admin", password: "password" }
    end

    test "edit page renders the format selector" do
      get edit_admin_tour_url(tours(:tour_one))

      assert_response :success
      assert_includes response.body, "Формат игры"
      assert_includes response.body, "Классика (6 игроков)"
    end

    test "updates the tour format" do
      tour = tours(:tour_one)

      patch admin_tour_url(tour), params: { tour: { format: "classic" } }

      assert_redirected_to admin_tour_url(tour)
      assert_equal "classic", tour.reload.format
      assert_equal GameFormat.find("classic"), tour.game_format
    end

    test "rejects an unknown format" do
      tour = tours(:tour_one)

      patch admin_tour_url(tour), params: { tour: { format: "nonsense" } }

      assert_response :unprocessable_entity
      assert_equal "mother_of_dragons", tour.reload.format
    end

    test "new prefills the next number for the city" do
      get new_admin_tour_url(city: cities(:moscow).slug)

      assert_response :success
      assert_includes response.body, "Новый тур"
    end

    test "creates a tour for a city" do
      assert_difference -> { cities(:spb).tours.count }, 1 do
        post admin_tours_url, params: { tour: {
          city_id: cities(:spb).id, number: 1, format: "classic"
        } }
      end

      tour = cities(:spb).tours.find_by(number: 1)
      assert_redirected_to admin_tour_url(tour)
      assert_equal "classic", tour.format
    end

    test "rejects a duplicate tour number within a city" do
      assert_no_difference -> { Tour.count } do
        post admin_tours_url, params: { tour: {
          city_id: cities(:moscow).id, number: tours(:tour_one).number
        } }
      end

      assert_response :unprocessable_entity
    end

    test "creating a tour generates the requested number of tables" do
      post admin_tours_url, params: { tour: {
        city_id: cities(:spb).id, number: 1, format: "classic", tables_count: 2
      } }

      tour = cities(:spb).tours.find_by(number: 1)
      assert_equal %w[A B], tour.games.order(:table_letter).pluck(:table_letter)
    end

    test "reducing tables_count removes empty tables" do
      tour = cities(:moscow).tours.create!(number: 6, tables_count: 4)
      tour.sync_tables
      assert_equal 4, tour.games.count

      patch admin_tour_url(tour), params: { tour: { tables_count: 2 } }

      assert_equal %w[A B], tour.reload.games.order(:table_letter).pluck(:table_letter)
    end

    test "destroys a tour" do
      tour = cities(:moscow).tours.create!(number: 7)

      assert_difference -> { Tour.count }, -1 do
        delete admin_tour_url(tour)
      end

      assert_redirected_to admin_tours_url
    end

    test "moves a tour to another city" do
      tour = tours(:tour_two) # Москва, номер 2; в СПб номера 2 нет

      patch admin_tour_url(tour), params: { tour: { city_id: cities(:spb).id } }

      assert_redirected_to admin_tour_url(tour)
      assert_equal cities(:spb), tour.reload.city
    end

    test "rejects moving a tour to a city where the number is taken" do
      other = cities(:spb).tours.create!(number: 2)

      patch admin_tour_url(tours(:tour_two)), params: { tour: { city_id: cities(:spb).id } }

      assert_response :unprocessable_entity
      assert_equal cities(:moscow), tours(:tour_two).reload.city
      other.destroy
    end
  end
end
