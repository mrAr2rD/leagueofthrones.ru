require "test_helper"

module Admin
  class GamesControllerTest < ActionDispatch::IntegrationTest
    setup do
      post admin_login_url, params: { login: "admin", password: "password" }
    end

    test "should get edit" do
      get edit_admin_tour_game_url(tours(:tour_one), games(:game_1a))
      assert_response :success
    end

    test "rejects duplicate house in one game" do
      game = games(:game_1a)
      first_result = game_results(:daenerys_game1)
      second_result = game_results(:jon_game1)

      patch admin_tour_game_url(tours(:tour_one), game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: first_result.id,
              player_id: first_result.player_id,
              house: "stark",
              place: first_result.place,
              points: first_result.points,
              capitals: first_result.capitals,
              dragons: first_result.dragons,
              castles: first_result.castles
            },
            "1" => {
              id: second_result.id,
              player_id: second_result.player_id,
              house: "stark",
              place: second_result.place,
              points: second_result.points,
              capitals: second_result.capitals,
              dragons: second_result.dragons,
              castles: second_result.castles
            }
          }
        }
      }

      assert_response :unprocessable_entity
      assert_includes response.body, "уже выбран за этим столом"
      assert_equal "lannister", second_result.reload.house
    end

    test "rejects blank house for occupied slot" do
      result = game_results(:daenerys_game1)

      patch admin_tour_game_url(tours(:tour_one), result.game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: result.id,
              player_id: result.player_id,
              house: "",
              place: result.place,
              points: result.points,
              capitals: result.capitals,
              dragons: result.dragons,
              castles: result.castles
            }
          }
        }
      }

      assert_response :unprocessable_entity
      assert_includes response.body, "должен быть выбран для занятого слота"
      assert_equal "stark", result.reload.house
    end

    test "rejects a house already used by the same player" do
      result = game_results(:cersei_game1)

      patch admin_tour_game_url(tours(:tour_one), result.game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: result.id,
              player_id: players(:daenerys).id,
              house: "stark",
              place: result.place,
              points: result.points,
              capitals: result.capitals,
              dragons: result.dragons,
              castles: result.castles
            }
          }
        }
      }

      assert_response :unprocessable_entity
      assert_includes response.body, "уже использовался этим игроком"
      assert_equal "targaryen", result.reload.house
    end
  end
end
