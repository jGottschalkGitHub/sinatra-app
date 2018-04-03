require 'sequel' 
class User < Sequel::Model 
    set_primary_key :id 
    one_to_many :items 
    one_to_many :permissions 
    one_to_many :logs 
end 