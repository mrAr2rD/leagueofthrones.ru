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
    end

    test "should get edit" do
      get edit_admin_player_url(players(:daenerys))
      assert_response :success
    end

    test "should update player" do
      patch admin_player_url(players(:daenerys)), params: { player: { first_name: "Дени" } }
      assert_redirected_to admin_players_url
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
