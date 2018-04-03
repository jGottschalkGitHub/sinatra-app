require 'sequel' 
	 
class Permission < Sequel::Model 
    many_to_one :user 
    many_to_one :list 
end