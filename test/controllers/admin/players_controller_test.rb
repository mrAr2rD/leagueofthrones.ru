require "test_helper"

module Admin
  class PlayersControllerTest < ActionDispatch::IntegrationTest
    setup do
      post admin_login_url, params: { login: "admin", password: "password" }
    end

    test "should get index" do
      get admin_players_url
      assert_response :success
    end

    test "should get new" do
      get new_admin_player_url
      assert_response :success
    end

    test "should create player" do
      assert_difference("Player.count") do
        post admin_players_url, params: { player: { first_name: "Ходор", nickname: "Ходор" } }
      end
      assert_redirected_to admin_players_url
      assert Player.order(:id).last.participates_in_tournament?
    end

    test "should get edit" do
      get edit_admin_player_url(players(:daenerys))
      assert_response :success
    end

    test "should update player" do
      patch admin_player_url(players(:daenerys)), params: { player: { first_name: "Дени" } }
      assert_redirected_to admin_players_url
    end

    test "should update tournament participation" do
      patch admin_player_url(players(:daenerys)), params: { player: { participates_in_tournament: "0" } }

      assert_redirected_to admin_players_url
      assert_not players(:daenerys).reload.participates_in_tournament?
    end

    test "assigns cities to a new player" do
      post admin_players_url, params: { player: {
        first_name: "Многогородний", nickname: "@multi_city",
        city_ids: [ cities(:moscow).id, cities(:spb).id ]
      } }

      player = Player.find_by(nickname: "@multi_city")
      assert_equal [ cities(:moscow), cities(:spb) ].sort_by(&:id), player.cities.sort_by(&:id)
    end

    test "updates a player's cities" do
      player = players(:daenerys)
      assert_includes player.cities, cities(:moscow)

      patch admin_player_url(player), params: { player: { city_ids: [ cities(:spb).id ] } }

      assert_equal [ cities(:spb) ], player.reload.cities.to_a
    end

    test "should destroy player" do
      player = Player.create!(first_name: "Temp", nickname: "temp_test")
      assert_difference("Player.count", -1) do
        delete admin_player_url(player)
      end
    end

    test "requires authentication" do
      delete admin_logout_url
      get admin_players_url
      assert_redirected_to admin_login_url
    end
  end
end
