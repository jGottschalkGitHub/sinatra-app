require 'sequel'

class List < Sequel::Model
  set_primary_key :id
  one_to_many :items # we need this line to have items included in the List if we get List
  one_to_many :permissions
  one_to_many :logs
  one_to_many :comments

  def self.new_list(name, user)
    list = List.new(name: name)
    list_saved = list.save # I need the list id in the route
    if list_saved
      Permission.create(
        list: list,
        user: user,
        permission_level: 'read_write',
        created_at: Time.now,
        updated_at: Time.now
      )
      return list_saved
    end
    list
  end

  def self.delete_list(list_id)
    Item.where(list_id: list_id).delete
    Permission.where(list_id: list_id).delete
    List.where(list_id: list_id).delete
  end
  # this is an instance method called on the instance of List that we are in
  # use instead of self.delete_list

  def before_destroy
    items.each(&:destroy)
    permissions.each(&:destroy)
    comments.each(&:destroy)
    super
  end

  def before_validation
    self.created_at ||= Time.now
    super
  end

  def validate
    super
    validates_presence %i[name created_at]
    validates_format /\A[A-Za-z\s]*\Z/, :name, message: 'is not a valid name'
    validates_min_length 3, :name
    validates_max_length 20, :name
    validates_unique :name
  end

  def self.edit_list(id, name, items)
    list = List.first(id: id)
    list.name = name if name
    return list if !list.save || items.nil?
    items.each do |item|
      item_id = item[:id]
      if item[:deleted]
        Item.first(id: item_id).destroy
        next
      end
      i = Item.first(id: item_id)
      name = item['name']
      i.name = name
      i.description = item['description']
      i.starred = item['starred'] ? 1 : 0
      y, m, d = item['date'].split('-') if item['date']
      duedate = Time.utc(y, m, d) if y
      i.due_date = duedate if duedate # && duedate > Time.now --> moved to validation
      return i unless i.save
    end
    list
  end
end
