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
      assert_includes response.body, "Заполните игрока и дом в каждой занятой строке или очистите строку целиком"
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

    test "allows swapping houses within one game" do
      game = games(:game_1a)
      first_result = game_results(:daenerys_game1)
      second_result = game_results(:jon_game1)

      patch admin_tour_game_url(tours(:tour_one), game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: first_result.id,
              player_id: first_result.player_id,
              house: second_result.house,
              place: first_result.place,
              points: first_result.points,
              capitals: first_result.capitals,
              dragons: first_result.dragons,
              castles: first_result.castles
            },
            "1" => {
              id: second_result.id,
              player_id: second_result.player_id,
              house: first_result.house,
              place: second_result.place,
              points: second_result.points,
              capitals: second_result.capitals,
              dragons: second_result.dragons,
              castles: second_result.castles
            }
          }
        }
      }

      assert_redirected_to admin_tour_url(tours(:tour_one))
      assert_equal "lannister", game.reload.game_results.find_by(player_id: first_result.player_id).house
      assert_equal "stark", game.game_results.find_by(player_id: second_result.player_id).house
    end

    test "rejects a player already selected in another game of the tour" do
      result = game_results(:cersei_game1)

      patch admin_tour_game_url(tours(:tour_one), result.game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: result.id,
              player_id: players(:daenerys).id,
              house: "arryn",
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
      assert_includes response.body, "уже выбран за другим столом этого тура"
      assert_equal players(:cersei).id, result.reload.player_id
    end

    test "rejects incomplete rows before saving" do
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
            },
            "1" => {
              player_id: "",
              house: "",
              place: "",
              points: "",
              capitals: "",
              dragons: "",
              castles: ""
            }
          }
        }
      }

      assert_response :unprocessable_entity
      assert_includes response.body, "Заполните игрока и дом в каждой занятой строке или очистите строку целиком"
      assert_equal "stark", result.reload.house
    end

    test "allows saving players and houses without places" do
      game = games(:game_1a)
      extra_player = Player.create!(first_name: "Новый", nickname: "@newplayer")

      patch admin_tour_game_url(tours(:tour_one), game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: game_results(:daenerys_game1).id,
              player_id: game_results(:daenerys_game1).player_id,
              house: game_results(:daenerys_game1).house,
              place: "",
              points: "",
              capitals: 0,
              dragons: 0,
              castles: 0
            },
            "1" => {
              id: game_results(:jon_game1).id,
              player_id: game_results(:jon_game1).player_id,
              house: game_results(:jon_game1).house,
              place: "",
              points: "",
              capitals: 0,
              dragons: 0,
              castles: 0
            },
            "2" => {
              player_id: extra_player.id,
              house: "tyrell",
              place: "",
              points: "",
              capitals: 0,
              dragons: 0,
              castles: 0
            }
          }
        }
      }

      assert_redirected_to admin_tour_url(tours(:tour_one))
      new_result = game.reload.game_results.find_by(player_id: extra_player.id)
      assert_not_nil new_result
      assert_nil new_result.place
      assert_nil new_result.points
      assert_equal "tyrell", new_result.house
    end

    test "keeps manually entered points even when they differ from the suggestion" do
      game = games(:game_1a)
      first_result = game_results(:daenerys_game1)
      second_result = game_results(:jon_game1)

      patch admin_tour_game_url(tours(:tour_one), game), params: {
        game: {
          game_results_attributes: {
            "0" => {
              id: first_result.id,
              player_id: first_result.player_id,
              house: first_result.house,
              place: 1,
              points: 999,
              capitals: 2,
              dragons: 1,
              castles: 0
            },
            "1" => {
              id: second_result.id,
              player_id: second_result.player_id,
              house: second_result.house,
              place: 2,
              points: 999,
              capitals: 1,
              dragons: 0,
              castles: 2
            }
          }
        }
      }

      assert_redirected_to admin_tour_url(tours(:tour_one))
      saved_results = game.reload.game_results.index_by(&:player_id)
      assert_equal 999, saved_results.fetch(first_result.player_id).points
      assert_equal 999, saved_results.fetch(second_result.player_id).points
      assert_equal 16, saved_results.fetch(first_result.player_id).suggested_points
      assert_equal 11, saved_results.fetch(second_result.player_id).suggested_points
    end
  end
end
