require 'sequel'
class User < Sequel::Model
  set_primary_key :id
  one_to_many :items
  one_to_many :permissions
  one_to_many :logs

  def before_validation
    self.created_at ||= Time.now
  end

  def validate
    super
    validates_presence %i[name created_at]
    validates_format /\A[A-Za-z]*\Z/, :name, message: 'is not a valid name'
    validates_min_length 3, :name
    validates_max_length 15, :name
    validates_unique :name
  end
end
