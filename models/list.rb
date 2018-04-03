require 'sequel' 

class List < Sequel::Model 
    set_primary_key :id 
        
    one_to_many :items  #we need this line to have items included in the List if we get List
    one_to_many :permissions 
    one_to_many :logs
    one_to_many :comments 

    def self.new_list name, items, user
        
        list = List.create(name: name, created_at: Time.now)
        items.each do |item|
            Item.create(
                name: item[:name], 
                description: item[:description], 
                list: list, user: user, 
                created_at: Time.now, 
                updated_at: Time.now
                )
        end
        Permission.create(
            list: list, 
            user: user, 
            permission_level: 'read_write', 
            created_at: Time.now, 
            updated_at: Time.now
            )
        
        return list
    end

    def self.delete_list list_id
        
        Item.where(:list_id => list_id).delete
        Permission.where(:list_id => list_id).delete
        List.where(:id => list_id).delete
        
    end

    def self.edit_list id, name, items, user
        list = List.first(id: id)
        ##list.name = name
        #list.updated_at = Time.now
        booli = true
        list.save
        items.each do |item|
           item_id = item[:id].to_i
            if item[:deleted]

                i = Item.first(id: item_id).destroy
                next
            end
                i = Item.first(id: item_id)
            if i.nil?
                Item.create(
                    name: item["name"], 
                    description: item[:description], 
                    list: list, 
                    user: user, 
                    created_at: Time.now, 
                    updated_at: Time.now)
            else
                name = item["name"]
                i.name = name  
                i.description = item["description"]
                i.updated_at = Time.now 
                
                item["starred"] ? i.starred = 1 : i.starred = 0
                #duedate = DateTime.parse(item["date"]) if item["date"]
                m, d, y = item["date"].split("/") if item["date"]
                duedate = Time.utc(y,m,d) if y 
                i.due_date = duedate if duedate && duedate > Time.now     
                i.save
            end
        end
    end
end 
class Item < Sequel::Model 
    set_primary_key :id 
    	 
    many_to_one :user 
    many_to_one :list 
end

=begin
The Sequel model assumes the table name as a pluralized and underscored version of the name of the model. 
For instance, for the User model, the name should be assumed users by default. 
We can also get this information from the model itself. 
=end
