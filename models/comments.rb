require 'sequel'

class Comment < Sequel::Model
  set_primary_key :id

  many_to_one :user
  many_to_one :list

  def self.delete_comment(comment_id)
    Comment.where(id: comment_id).delete
  end

  def validate
    super
    errors.add(:text, message: 'Please enter a text') if text.empty?
  end

  # here we do not need to use self. since we are operating from an instance of Comment
  def editable?(user)
    user_id == user.id && creation_date > Time.now - 15 * 60 # returns true
  end
end
