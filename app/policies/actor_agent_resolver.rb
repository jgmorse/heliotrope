# frozen_string_literal: true

require 'checkpoint/agent'

class ActorAgentResolver < Checkpoint::Agent::Resolver
  def expand(actor)
    agents = super(actor) + individuals(actor) + institutions(actor)
    agents
  end

  def convert(actor)
    agent = super(actor)
    agent
  end

  private

    def individuals(actor)
      return [] if actor.individual.blank?
      [convert(actor.individual)]
    end

    def institutions(actor)
      actor.institutions.map { |institution| convert(institution) }
    end
end
