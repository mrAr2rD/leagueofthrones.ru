class TidesOfBattleSession < ApplicationRecord
  class InvalidTransition < StandardError; end

  SIDES = %w[attacker defender].freeze

  CARD_FACES = {
    "zero" => { strength: 0, symbol: nil, label: "Без символа" },
    "skull" => { strength: 0, symbol: "skull", label: "Череп" },
    "sword" => { strength: 1, symbol: "sword", label: "Меч" },
    "fortification" => { strength: 1, symbol: "fortification", label: "Укрепление" },
    "two" => { strength: 2, symbol: nil, label: "Без символа" },
    "three" => { strength: 3, symbol: nil, label: "Без символа" }
  }.freeze

  DECK = [
    *Array.new(8, "zero"),
    *Array.new(2, "skull"),
    *Array.new(4, "sword"),
    *Array.new(4, "fortification"),
    *Array.new(4, "two"),
    *Array.new(2, "three")
  ].freeze

  belongs_to :city

  before_validation :assign_token, on: :create
  before_validation :shuffle_deck, on: :create

  validates :token, presence: true, uniqueness: true
  validates :attacker_card, :defender_card, inclusion: { in: CARD_FACES.keys }, allow_nil: true
  validates :rerolled_side, inclusion: { in: SIDES }, allow_nil: true

  def draw!(side)
    side = normalized_side(side)

    with_lock do
      return self if card_drawn?(side)

      raise InvalidTransition, "Карты уже раскрыты" if revealed?

      remaining_deck = deck_order.dup
      card = remaining_deck.shift
      raise InvalidTransition, "Колода пуста" unless card

      update!("#{side}_card" => card, deck_order: remaining_deck)
    end

    self
  end

  def reroll!(side)
    side = normalized_side(side)

    with_lock do
      raise InvalidTransition, "Сначала обе стороны должны вытянуть карты" unless both_drawn?
      raise InvalidTransition, "Карты уже раскрыты" if revealed?
      raise InvalidTransition, "Валирийский меч уже использован" if rerolled_side.present?

      remaining_deck = deck_order.dup
      card = remaining_deck.shift
      raise InvalidTransition, "Колода пуста" unless card

      update!("#{side}_card" => card, deck_order: remaining_deck, rerolled_side: side)
    end

    self
  end

  def reveal!
    with_lock do
      raise InvalidTransition, "Сначала обе стороны должны вытянуть карты" unless both_drawn?

      update!(revealed_at: Time.current) unless revealed?
    end

    self
  end

  def card_drawn?(side)
    public_send("#{normalized_side(side)}_card").present?
  end

  def both_drawn?
    attacker_card.present? && defender_card.present?
  end

  def revealed?
    revealed_at.present?
  end

  def reroll_available?
    both_drawn? && rerolled_side.nil? && !revealed?
  end

  def card_for(side)
    card_key = public_send("#{normalized_side(side)}_card")
    CARD_FACES[card_key]
  end

  private

  def assign_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end

  def shuffle_deck
    self.deck_order = DECK.shuffle if deck_order.blank?
  end

  def normalized_side(side)
    side = side.to_s
    return side if SIDES.include?(side)

    raise ArgumentError, "Неизвестная сторона боя"
  end
end
