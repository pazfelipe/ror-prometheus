class Todo < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, length: { maximum: 500 }
  validates :completed, inclusion: { in: [true, false] }

  after_save :cache_todo
  after_destroy :remove_from_cache

  private

  def cache_todo
    REDIS_CLIENT.set("todo:#{id}", self.to_json)
  end

  def remove_from_cache
    REDIS_CLIENT.del("todo:#{id}")
  end
end
