require "test_helper"

module Admin
  # Проверяет, что обычный (city-scoped) админ ограничен своими городами.
  class AccessControlTest < ActionDispatch::IntegrationTest
    setup do
      # city_admin привязан только к Москве (фикстура admin_user_cities).
      post admin_login_url, params: { login: "city_admin", password: "password" }
      @spb_tour = cities(:spb).tours.create!(number: 1, format: "classic")
    end

    test "cannot open the cities section" do
      get admin_cities_url
      assert_redirected_to admin_root_url
    end

    test "tour index shows only assigned cities" do
      get admin_tours_url
      assert_response :success
      assert_match "Тур #{tours(:tour_one).number}", response.body # Москва
      assert_no_match "Санкт-Петербург", response.body
    end

    test "can edit a tour in an assigned city" do
      get edit_admin_tour_url(tours(:tour_one))
      assert_response :success
    end

    test "cannot edit a tour in another city" do
      get edit_admin_tour_url(@spb_tour)
      assert_redirected_to admin_root_url
    end

    test "cannot edit a game in another city" do
      spb_game = @spb_tour.games.create!(table_letter: "A")
      get edit_admin_tour_game_url(@spb_tour, spb_game)
      assert_redirected_to admin_root_url
    end

    test "player index is scoped to assigned cities" do
      spb_only = Player.create!(first_name: "Питерец", nickname: "@spb_scoped_only")
      PlayerCity.create!(player: spb_only, city: cities(:spb))

      get admin_players_url

      assert_response :success
      assert_match "samzakharov", response.body  # игрок Москвы
      assert_no_match "spb_scoped_only", response.body
    end

    test "regular admin cannot delete a player" do
      assert_no_difference -> { Player.count } do
        delete admin_player_url(players(:daenerys))
      end
      assert_redirected_to admin_players_url
    end

    test "editing a player preserves memberships in cities the admin does not manage" do
      player = players(:daenerys)
      PlayerCity.create!(player: player, city: cities(:spb)) # теперь в Москве и СПб

      # city_admin снимает Москву (отправляет пустой список своих городов)
      patch admin_player_url(player), params: { player: {
        first_name: player.first_name, nickname: player.nickname, city_ids: [ "" ]
      } }

      player.reload
      assert_not_includes player.cities, cities(:moscow), "Москву (свой город) должен снять"
      assert_includes player.cities, cities(:spb), "чужой город СПб должен сохраниться"
    end
  end
end
