class User < ActiveRecord::Base
  validates_uniqueness_of :name
  has_many :articles
  has_many :comments
  has_many :publications
  
  def repository
    @repository ||= Repository.new(self)
  end
  
  def after_create
    repository.create
  end
  
  def before_destroy
    repository.destroy
    publications.destroy_all
  end
end
