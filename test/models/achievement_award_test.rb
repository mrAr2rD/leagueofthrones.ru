require "test_helper"

class AchievementAwardTest < ActiveSupport::TestCase
  test "achievement registry preserves the requested secret nomination contract" do
    definition = AchievementDefinition.fetch("faceless_chosen")

    assert_equal "Избранник Безликих", definition.name
    assert_equal :skulls, definition.metric
    assert_equal "achievements/faceless_chosen.png", definition.icon_path
    assert definition.secret?
  end

  test "belongs to city player and optional awarding admin" do
    award = build_award

    assert award.valid?, award.errors.full_messages.to_sentence
    assert_equal cities(:moscow), award.city
    assert_equal players(:daenerys), award.player
    assert_equal admin_users(:admin), award.awarded_by
  end

  test "nullifies awarded_by when admin is deleted" do
    awarding_admin = AdminUser.create!(login: "award_admin", password: "password")
    award = build_award(awarded_by: awarding_admin)
    award.save!

    awarding_admin.destroy!

    assert_nil award.reload.awarded_by
  end

  test "validates game format achievement key and nonnegative value" do
    award = build_award(game_format: "unknown", achievement_key: "unknown", stat_value: -1)

    assert_not award.valid?
    assert award.errors[:game_format].any?
    assert award.errors[:achievement_key].any?
    assert award.errors[:stat_value].any?
  end

  test "validates achievement applicability to format" do
    award = build_award(game_format: "classic", achievement_key: "dragon_slayer")

    assert_not award.valid?
    assert_includes award.errors[:achievement_key], "не применяется к выбранному игровому формату"
  end

  test "is unique by city format achievement and player" do
    build_award.save!
    duplicate = build_award

    assert_not duplicate.valid?
    assert duplicate.errors[:player_id].any?
  end

  test "allows the same achievement for another city or format" do
    build_award.save!
    other_city = build_award(city: cities(:spb), game_format: "mother_of_dragons")
    other_format = build_award(game_format: "classic")

    assert other_city.valid?, other_city.errors.full_messages.to_sentence
    assert other_format.valid?, other_format.errors.full_messages.to_sentence
  end

  private

  def build_award(overrides = {})
    AchievementAward.new({
      city: cities(:moscow),
      player: players(:daenerys),
      game_format: "mother_of_dragons",
      achievement_key: "conqueror",
      stat_value: 3,
      awarded_at: Time.zone.parse("2026-07-01 12:00"),
      published_at: Time.zone.parse("2026-07-01 12:00"),
      awarded_by: admin_users(:admin)
    }.merge(overrides))
  end
end
