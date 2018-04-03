Sequel.migration do 
    change do 
        alter_table :items do
            add_column(:due_date, DateTime)
            add_column(:starred, TrueClass)   
        end 
    end 
end 