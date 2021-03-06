# frozen_string_literal: true

# == Schema Information
#
# Table name: improvements
#
#  id          :bigint           not null, primary key
#  description :string
#  type        :string
#  rating      :integer
#  stat_limit  :integer
#  playbook_id :bigint
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  advanced    :boolean
#
module Improvements
  # This is for Improvements like "Take another [Playbook] move"
  class PlaybookMove < Improvement
    def apply(hunters_improvement)
      return false if add_errors(hunters_improvement)
      hunters_improvement.hunter.moves << move(hunters_improvement)
    end

    def add_errors(hunters_improvement)
      super(hunters_improvement)
      validate_hunter hunters_improvement
      validate_improvable hunters_improvement
      hunters_improvement.errors.present?
    end

    def validate_hunter(hunters_improvement)
      return unless hunter_has_move?(hunters_improvement.hunter, move(hunters_improvement))
      hunters_improvement.errors.add(:hunter, "already has move with id #{move(hunters_improvement).id}")
    end

    def validate_improvable(hunters_improvement)
      move = move(hunters_improvement)
      return unless move
      hunters_improvement.errors.add(:improvable, "is not from playbook #{playbook.name}") unless move_matches_playbook?(move)
    end

    def move_matches_playbook?(move)
      move.playbook == playbook
    end

    def hunter_has_move?(hunter, move)
      hunter.moves.include? move
    end

    def move(hunters_improvement)
      Move.find(hunters_improvement.improvable&.dig('move', 'id'))
    rescue ActiveRecord::RecordNotFound => e
      hunters_improvement.errors.add(:improvable, e.message)
      false
    end

    def improvable_options(hunter)
      moves = Move
              .where.not(id: hunter.moves.select(:id))
              .where(playbook_id: playbook_id)
              .select(:id, :name, :description)
      { move: { data: moves, count: 1 } }
    end
  end
end
