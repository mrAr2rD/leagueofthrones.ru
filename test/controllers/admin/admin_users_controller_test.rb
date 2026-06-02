require "test_helper"

module Admin
  class AdminUsersControllerTest < ActionDispatch::IntegrationTest
    def login(user)
      post admin_login_url, params: { login: user.login, password: "password" }
    end

    test "superadmin can list admins" do
      login admin_users(:admin)
      get admin_admin_users_url
      assert_response :success
      assert_match "city_admin", response.body
    end

    test "creates a city-scoped admin" do
      login admin_users(:admin)

      assert_difference -> { AdminUser.count }, 1 do
        post admin_admin_users_url, params: { admin_user: {
          login: "spb_admin", password: "secret123", password_confirmation: "secret123",
          superadmin: "0", city_ids: [ cities(:spb).id ]
        } }
      end

      created = AdminUser.find_by(login: "spb_admin")
      assert_redirected_to admin_admin_users_url
      assert_not created.superadmin?
      assert_equal [ cities(:spb) ], created.cities.to_a
    end

    test "edit keeps password when left blank" do
      login admin_users(:admin)
      target = admin_users(:city_admin)
      old_digest = target.password_digest

      patch admin_admin_user_url(target), params: { admin_user: {
        login: "city_admin", password: "", password_confirmation: "", superadmin: "1"
      } }

      assert_redirected_to admin_admin_users_url
      target.reload
      assert target.superadmin?
      assert_equal old_digest, target.password_digest
    end

    test "cannot delete yourself" do
      login admin_users(:admin)
      assert_no_difference -> { AdminUser.count } do
        delete admin_admin_user_url(admin_users(:admin))
      end
      assert_redirected_to admin_admin_users_url
    end

    test "regular admin cannot access admin management" do
      login admin_users(:city_admin)
      get admin_admin_users_url
      assert_redirected_to admin_root_url
    end
  end
end
