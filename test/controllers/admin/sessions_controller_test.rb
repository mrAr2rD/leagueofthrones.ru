require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "should get login page" do
      get admin_login_url
      assert_response :success
    end

    test "login with valid credentials" do
      post admin_login_url, params: { login: "admin", password: "password" }
      assert_redirected_to admin_root_url
    end

    test "login with invalid credentials" do
      post admin_login_url, params: { login: "admin", password: "wrong" }
      assert_response :unprocessable_entity
    end

    test "logout" do
      post admin_login_url, params: { login: "admin", password: "password" }
      delete admin_logout_url
      assert_redirected_to admin_login_url
    end
  end
end
