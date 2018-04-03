Sequel.migration do 
    change do 
        create_table :users do 
            primary_key :id 
            String :name, :unique => true, :length => 32, :null => false 
            String :password, :length => 32, :null => false 
            DateTime :created_at 
        end 
    end 
end 