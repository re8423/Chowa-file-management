require 'bundler/setup'
Bundler.require

if development?
    ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end

class User < ActiveRecord::Base
    has_secure_password
    
    validates :name,
        presence: true
    has_many :tasks, dependent: :destroy
end

class Task <ActiveRecord::Base
    default_scope -> { order(start: :asc) }

    scope :due_over, -> {where('due_date < ?', Date.today).where(completed: [nil, false]) }
    scope :had_by, -> (user) { where(user_id: user.id) }
    scope :star, -> {where(star: [true])}

    validates :title,
        presence: true
    belongs_to :user
    belongs_to :list
    belongs_to :cat    
end

class List < ActiveRecord::Base
    has_many :tasks
end

class Cat < ActiveRecord::Base
    has_many :tasks
end
