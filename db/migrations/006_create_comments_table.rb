Sequel.migration do
  change do
    create_table :comments do
      primary_key :id
      foreign_key :user_id
      foreign_key :list_id
      String :text, length: 256
      DateTime :creation_date
    end
  end
end
