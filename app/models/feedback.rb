# frozen_string_literal: true

class Feedback
  include ActiveModel::Model

  attr_accessor :feedback

  def persisted?
    false
  end
end
