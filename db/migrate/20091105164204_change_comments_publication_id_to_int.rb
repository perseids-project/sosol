class ChangeCommentsPublicationIdToInt < ActiveRecord::Migration[4.2]
  def self.up
    if activerecord::base.connection.adapter_name == 'postgresql'
      change_column :comments, :publication_id, "integer using nullif(publication_id, '')::int"
    else
      change_column :comments, :publication_id, :integer
    end
  end

  def self.down
    if activerecord::base.connection.adapter_name == 'postgresql'
      change_column :comments, :publication_id, "string using nullif(publication_id, '')::string"
    else
      change_column :comments, :publication_id, :string
    end
  end
end
