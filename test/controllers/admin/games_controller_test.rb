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

      patch_game(game,
        submitted_result_attributes(first_result, house: "stark"),
        submitted_result_attributes(second_result, house: "stark"))

      assert_response :unprocessable_entity
      assert_includes response.body, "уже выбран за этим столом"
      assert_equal "lannister", second_result.reload.house
    end

    test "rejects blank house for occupied slot" do
      result = game_results(:daenerys_game1)

      patch_game(result.game, submitted_result_attributes(result, house: ""))

      assert_response :unprocessable_entity
      assert_includes response.body, "Заполните игрока и дом в каждой занятой строке или очистите строку целиком"
      assert_equal "stark", result.reload.house
    end

    test "rejects a house already used by the same player" do
      result = game_results(:cersei_game1)

      patch_game(result.game,
        submitted_result_attributes(result, player_id: players(:daenerys).id, house: "stark"))

      assert_response :unprocessable_entity
      assert_includes response.body, "уже использовался этим игроком"
      assert_equal "targaryen", result.reload.house
    end

    test "allows swapping houses within one game" do
      game = games(:game_1a)
      first_result = game_results(:daenerys_game1)
      second_result = game_results(:jon_game1)

      patch_game(game,
        submitted_result_attributes(first_result, house: second_result.house),
        submitted_result_attributes(second_result, house: first_result.house))

      assert_redirected_to admin_tour_url(tours(:tour_one))
      assert_equal "lannister", game.reload.game_results.find_by(player_id: first_result.player_id).house
      assert_equal "stark", game.game_results.find_by(player_id: second_result.player_id).house
    end

    test "rejects a player already selected in another game of the tour" do
      result = game_results(:cersei_game1)

      patch_game(result.game,
        submitted_result_attributes(result, player_id: players(:daenerys).id, house: "arryn"))

      assert_response :unprocessable_entity
      assert_includes response.body, "уже выбран за другим столом этого тура"
      assert_equal players(:cersei).id, result.reload.player_id
    end

    test "rejects incomplete rows before saving" do
      result = game_results(:daenerys_game1)

      patch_game(result.game,
        submitted_result_attributes(result, house: ""),
        submitted_result_attributes(nil))

      assert_response :unprocessable_entity
      assert_includes response.body, "Заполните игрока и дом в каждой занятой строке или очистите строку целиком"
      assert_equal "stark", result.reload.house
    end

    test "allows saving players and houses without places" do
      game = games(:game_1a)
      extra_player = Player.create!(first_name: "Новый", nickname: "@newplayer")

      patch_game(game,
        submitted_result_attributes(game_results(:daenerys_game1), place: "", points: ""),
        submitted_result_attributes(game_results(:jon_game1), place: "", points: ""),
        submitted_result_attributes(
          nil,
          player_id: extra_player.id,
          house: "tyrell",
          place: "",
          points: "",
          capitals: 0,
          capital_captures: "",
          capital_controls: "",
          lands: "",
          skulls: "",
          dragons: 0,
          castles: 0
        ))

      assert_redirected_to admin_tour_url(tours(:tour_one))
      new_result = game.reload.game_results.find_by(player_id: extra_player.id)
      assert_not_nil new_result
      assert_nil new_result.place
      assert_nil new_result.points
      assert_equal "tyrell", new_result.house
      assert_nil new_result.capital_captures
      assert_nil new_result.capital_controls
    end

    test "keeps manually entered points even when they differ from the suggestion" do
      game = games(:game_1a)
      first_result = game_results(:daenerys_game1)
      second_result = game_results(:jon_game1)

      patch_game(game,
        submitted_result_attributes(first_result,
          points: 999,
          capital_captures: 2,
          capital_controls: 0,
          dragons: 1,
          castles: 0),
        submitted_result_attributes(second_result,
          points: 999,
          capital_captures: 1,
          capital_controls: 0,
          dragons: 0,
          castles: 2))

      assert_redirected_to admin_tour_url(tours(:tour_one))
      saved_results = game.reload.game_results.index_by(&:player_id)
      assert_equal 999, saved_results.fetch(first_result.player_id).points
      assert_equal 999, saved_results.fetch(second_result.player_id).points
      assert_equal 16, saved_results.fetch(first_result.player_id).suggested_points
      assert_equal 11, saved_results.fetch(second_result.player_id).suggested_points
    end

    test "preserves legacy capitals when split capital fields stay blank" do
      game = games(:game_1a)
      legacy_result = game_results(:daenerys_game1)

      patch_game(game, submitted_result_attributes(legacy_result,
        capital_captures: "",
        capital_controls: "",
        lands: "",
        skulls: ""))

      assert_redirected_to admin_tour_url(tours(:tour_one))
      saved_result = game.reload.game_results.find_by!(player_id: legacy_result.player_id)
      assert_equal 2, saved_result.capitals
      assert_nil saved_result.capital_captures
      assert_nil saved_result.capital_controls
      assert_equal 2, saved_result.effective_capitals
    end

    test "saves split capital fields and extra stats" do
      game = games(:game_1a)
      result = game_results(:daenerys_game1)

      patch_game(game, submitted_result_attributes(result,
        capital_captures: 2,
        capital_controls: 1,
        lands: 11,
        skulls: 3,
        dragons: 1,
        castles: 0,
        points: 17))

      assert_redirected_to admin_tour_url(tours(:tour_one))
      saved_result = game.reload.game_results.find_by!(player_id: result.player_id)
      assert_equal 2, saved_result.capitals
      assert_equal 2, saved_result.capital_captures
      assert_equal 1, saved_result.capital_controls
      assert_equal 11, saved_result.lands
      assert_equal 3, saved_result.skulls
      assert_equal 3, saved_result.effective_capitals
      assert_equal 17, saved_result.suggested_points
    end

    private

    def patch_game(game, *rows)
      patch admin_tour_game_url(tours(:tour_one), game), params: {
        game: {
          game_results_attributes: rows.each_with_index.to_h do |row, index|
            [ index.to_s, row ]
          end
        }
      }
    end

    def submitted_result_attributes(result = nil, overrides = {})
      base = if result
        {
          id: result.id,
          player_id: result.player_id,
          house: result.house,
          place: result.place,
          points: result.points,
          capitals: result.capitals,
          capital_captures: result.capital_captures,
          capital_controls: result.capital_controls,
          lands: result.lands,
          skulls: result.skulls,
          dragons: result.dragons,
          castles: result.castles
        }
      else
        {
          player_id: "",
          house: "",
          place: "",
          points: "",
          capitals: 0,
          capital_captures: "",
          capital_controls: "",
          lands: "",
          skulls: "",
          dragons: 0,
          castles: 0
        }
      end

      base.merge(overrides)
    end
  end
end
