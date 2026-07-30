require "application_system_test_case"

class AdminFinalTourHouseReuseTest < ApplicationSystemTestCase
  test "admin sees and confirms a repeated house in the final tour" do
    final_tour = cities(:moscow).tours.create!(number: 8, format: "mother_of_dragons")
    final_game = final_tour.games.create!(table_letter: "A")

    visit admin_login_path
    fill_in "Логин", with: "admin"
    fill_in "Пароль", with: "password"
    click_button "Войти"
    assert_current_path admin_root_path

    visit edit_admin_tour_game_path(final_tour, final_game)

    first_row = all("[data-slot-toggle-target='row']").first
    player_input = first_row.find("[data-slot-toggle-target='playerInput']")
    player_input.click
    player_input.set(players(:daenerys).admin_option_label)
    first_row.find("[data-player-id='#{players(:daenerys).id}']").click

    house_select = first_row.find("[data-slot-toggle-target='houseSelect']")
    assert_includes house_select.all("option").map(&:text), "Старк — уже играл"

    house_select.select("Старк — уже играл")

    within first_row do
      assert_text "игрок уже играл за дом «Старк»"
      assert_text "В заключительном туре повтор разрешён"
      assert_selector "[data-slot-toggle-target='houseHint'].text-amber-700"
    end

    click_button "Сохранить результаты"

    assert_text "Результаты сохранены"
    assert_equal "stark", final_game.reload.game_results.find_by!(player: players(:daenerys)).house
  end
end
