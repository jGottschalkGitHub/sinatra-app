
class Item < Sequel::Model
  set_primary_key :id
  many_to_one :user
  many_to_one :list

  def before_validation
    puts 'inside before_validate item'
    self.created_at = Time.now
    super
  end

  def before_save
    puts 'inside before_save item'
    self.created_at ||= self.updated_at = Time.now
    puts self.created_at
    super
  end

  def validate
    super
    validates_presence %i[name created_at]
    validates_format /\A[A-Za-z\s]*\Z/, :name, message: 'is not a valid name'
    validates_min_length 3, :name
    validates_max_length 20, :name
  end
end
