# frozen_string_literal: true

class Post < ApplicationRecord
  before_create :generate_slug

  scope :with_tag, ->(tag) { where("tags @> ARRAY[?]", tag) }

  def self.all_tags
    pluck(:tags).flatten(1).uniq.sort_by(&:to_s).group_by { |tag| tag[0] }
  end

  def self.newest_first
    order(created_at: :desc)
  end

  def to_param
    slug
  end

  def to_s
    title
  end

  def cache_key
    [record_key, updated_at.to_s].join("/")
  end

  private

    def to_slug
      File.join created_at.strftime("%Y/%m/%d"), title.parameterize(separator: "_")
    end

    def generate_slug
      self.slug = to_slug
    end
end
