require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  test "superadmin can access every city" do
    admin = admin_users(:admin)
    assert admin.superadmin?
    assert admin.can_access_city?(cities(:moscow))
    assert admin.can_access_city?(cities(:spb))
    assert_equal City.ordered.to_a, admin.accessible_cities.to_a
  end

  test "regular admin only accesses assigned cities" do
    admin = admin_users(:city_admin)
    assert_not admin.superadmin?
    assert admin.can_access_city?(cities(:moscow))
    assert_not admin.can_access_city?(cities(:spb))
    assert_equal [ cities(:moscow) ], admin.accessible_cities.to_a
  end

  test "can_access_city? is false for nil" do
    assert_not admin_users(:city_admin).can_access_city?(nil)
  end
end
