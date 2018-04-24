require 'sequel' 

class List < Sequel::Model 
    set_primary_key :id 
        
    one_to_many :items  #we need this line to have items included in the List if we get List
    one_to_many :permissions 
    one_to_many :logs
    one_to_many :comments 

    def self.new_list name, items, user
        
        list = List.new(name: name, created_at: Time.now)
        list_saved = list.save
        if list_saved
            if items
                items.each do |item|
                    Item.create(
                        name: item[:name],
                        description: item[:description],
                        list: list, user: user,
                        created_at: Time.now,
                        updated_at: Time.now
                    )
                end
            end
            Permission.create(
                list: list, 
                user: user, 
                permission_level: 'read_write', 
                created_at: Time.now, 
                updated_at: Time.now
            )  
            return list_saved
        end
        return list
    end

    def self.delete_list list_id
        
        Item.where(:list_id => list_id).delete
        Permission.where(:list_id => list_id).delete
        List.where(:id => list_id).delete
        
    end

    #this is an instance method called on the instance of List that we are in
    #use instead of self.delete_list
    def before_destroy
        items.each(&:destroy)
        permissions.each(&:destroy)
        comments.each(&:destroy)
        super
    end

    def before_validation
        self.created_at ||= Time.now
    
    end
    
    def validate

        super
        validates_presence [:name, :created_at]
        validates_format /\A[A-Za-z]*\Z/, :name, message: 'is not a valid name'
        validates_min_length 3, :name
        validates_max_length 20, :name
        validates_unique :name
        binding.pry
        
    end

    def self.edit_list id, name, items, user
        list = List.first(id: id)
        ##list.name = name
        #list.updated_at = Time.now
        booli = true
        binding.pry
        list.name = name if name
        list.new? ? list.save : list.save(:validate => false)
        if list.save
            if items
                items.each do |item|
                item_id = item[:id].to_i
                    if item[:deleted]
                        i = Item.first(id: item_id).destroy
                        next
                    end
                        i = Item.first(id: item_id)
                    if i.nil?
                        Item.new(
                            name: item["name"], 
                            description: item[:description], 
                            list: list, 
                            user: user, 
                            created_at: Time.now, 
                            updated_at: Time.now
                            )
                    else
                        
                        name = item["name"]
                        i.name = name  
                        i.description = item["description"]
                        i.updated_at = Time.now 
                        item["starred"] ? i.starred = 1 : i.starred = 0
                        y, m, d = item["date"].split("-") if item["date"]
                        duedate = Time.utc(y,m,d) if y 
                        i.due_date = duedate if duedate && duedate > Time.now
                        
                        i.save
                    end
                end
            end
        end
    end
end 
class Item < Sequel::Model 
    set_primary_key :id 
    	 
    many_to_one :user 
    many_to_one :list 


    def before_validation
        self.created_at ||= Time.now
    
    end
    
    def validate
        super
        validates_presence [:name, :created_at]
        validates_format /\A[A-Za-z\s]*\Z/, :name, message: 'is not a valid name'
        validates_min_length 3, :name
        validates_max_length 20, :name
    end

end

=begin
The Sequel model assumes the table name as a pluralized and underscored version of the name of the model. 
For instance, for the User model, the name should be assumed users by default. 
We can also get this information from the model itself. 
=end