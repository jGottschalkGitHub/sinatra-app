require 'sequel'

class Comment < Sequel::Model
    set_primary_key :id

    many_to_one :user
    many_to_one :list

    def self.new_comment text, listid, userid
        
        creat_date=Time.now
        Comment.create(  
            list_id: listid, 
            user_id: userid, 
            text: text, 
            creation_date: creat_date
            )      
    end

    def self.delete_comment commentId

        Comment.where(:id => commentId).delete
       
    end

    def before_destroy
        puts "destroying comment #{self.id}"
    end

    #here we do not need to use self. since we are operating from an instance of Comment
    def editable? user
        user_id == user.id && creation_date > Time.now - 15 * 60 #returns true
    end

end
