
class Item < Sequel::Model
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def before_validation
    self.created_at = Time.now
    super
  end

  def before_save
    self.updated_at = Time.now
  end

  def validate
    super
    validates_presence %i[name created_at]
    validates_format /\A[A-Za-z\s]*\Z/, :name, message: 'is not a valid name'
    validates_min_length 3, :name
    validates_max_length 20, :name
    errors.add(:due_date, message: 'date is in the past') if due_date && due_date < Time.now
  end
end
