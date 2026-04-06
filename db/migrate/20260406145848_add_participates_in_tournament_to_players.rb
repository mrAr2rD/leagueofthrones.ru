class AddParticipatesInTournamentToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :participates_in_tournament, :boolean, default: true, null: false
  end
end
