require "test_helper"

class GalleryControllerTest < ActionDispatch::IntegrationTest
  test "redirects to login when not authenticated" do
    get gallery_url

    assert_redirected_to gallery_login_url
  end

  test "shows players from all cities once authenticated" do
    spb_player = Player.create!(first_name: "Питерец", nickname: "@spb_gallery")
    PlayerCity.create!(player: spb_player, city: cities(:spb))

    authenticate_gallery

    get gallery_url

    assert_response :success
    assert_match "samzakharov", response.body # игрок Москвы (фикстура)
    assert_match "spb_gallery", response.body  # игрок СПб
  end

  test "profile links point to a city-scoped player path" do
    authenticate_gallery

    get gallery_url

    assert_response :success
    assert_select "a[href=?]", city_player_path(cities(:moscow), players(:daenerys))
  end

  private

  def authenticate_gallery
    post gallery_authenticate_url, params: { login: "admin", password: "password" }
  end
end
