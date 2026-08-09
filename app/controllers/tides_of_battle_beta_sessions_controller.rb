class TidesOfBattleBetaSessionsController < TidesOfBattleSessionsController
  def show
    side = params[:preview].to_s
    return unless TidesOfBattleSession::SIDES.include?(side)
    return unless @battle_session.card_drawn?(side)
    return if @battle_session.revealed?

    @peeked_side = side
    @auto_hide = true
  end

  def draw
    side = params[:side].to_s
    @battle_session.draw!(side)
    respond_with_spin_result(side)
  end

  def reroll
    side = params[:side].to_s
    @battle_session.reroll!(side)
    respond_with_spin_result(side)
  end

  private

  def battle_session_path
    city_tides_of_battle_beta_session_path(@city, @battle_session.token)
  end

  def preview_path(side)
    city_tides_of_battle_beta_session_path(@city, @battle_session.token, preview: side)
  end

  def respond_with_spin_result(side)
    respond_to do |format|
      format.html { redirect_to preview_path(side), status: :see_other }
      format.json do
        render json: {
          card: spin_card_payload(side),
          preview_url: preview_path(side)
        }
      end
    end
  end

  def spin_card_payload(side)
    card = @battle_session.card_for(side)

    {
      key: @battle_session.public_send("#{side}_card"),
      strength: card.fetch(:strength),
      symbol: card[:symbol],
      label: card.fetch(:label)
    }
  end
end
