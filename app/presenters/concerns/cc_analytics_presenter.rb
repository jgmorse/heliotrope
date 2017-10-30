# frozen_string_literal: true

module CCAnalyticsPresenter
  extend ActiveSupport::Concern

  def pageviews_by_path(path)
    count = 0
    pageviews = Rails.cache.read('ga_pageviews')
    return '?' if pageviews.nil?
    if pageviews.is_a?(Array)
      pageviews.each do |entry|
        count += entry[:pageviews].to_i if entry[:pagePath] == path
      end
    end
    count
  end

  def pageviews_by_ids(ids)
    count = 0
    pageviews = Rails.cache.read('ga_pageviews')
    return '?' if pageviews.nil?
    if pageviews.is_a?(Array)
      pageviews.each do |entry|
        ids.each do |id|
          count += entry[:pageviews].to_i if entry[:pagePath].include? id
        end
      end
    end
    count
  end
end