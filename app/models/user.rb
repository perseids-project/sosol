#Represents a system user.
class User < ActiveRecord::Base

  include Swagger::Blocks
  swagger_schema :User do
    key :required, [:id]
    property :id do
      key :type, :integer
    end
    property :admin do
      key :type, :boolean
    end
    property :affiliation do 
      key :type, :string
    end
    property :email do
      key :type, :string
    end
    property :email_opt_out do
      key :type, :boolean
    end
    property :full_name do
      key :type, :string
    end
    property :has_repository do
      key :type, :boolean
    end
    property :is_community_master_admin do
      key :type, :boolean
    end
    property :is_master_admin do
      key :type, :boolean
    end
    property :language_prefs do
      key :type, :string
    end
    property :name do
      key :type, :string
    end
    property :uri do
      key :type, :string
    end
    property :accepted_terms do
      key :type, :integer
    end
  end

  validates_uniqueness_of :name, :case_sensitive => false

  has_many :user_identifiers, :dependent => :destroy

  has_many :communities_members
  has_many :community_memberships, :through => :communities_members, :source => :community
  has_many :communities_admins
  has_many :community_admins,  :through => :communities_admins, :source => :community

  has_many :boards_users
  has_many :boards, :through => :boards_users
  has_many :finalizing_boards, :class_name => 'Board', :foreign_key => 'finalizer_user_id'

  has_and_belongs_to_many :emailers

  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner, :dependent => :destroy

  has_many :comments

  has_repository

  after_create do |user|
    user.repository.create

    # create some fixture publications/identifiers
    # ["p.genova/p.genova.2/p.genova.2.67.xml",
    # "sb/sb.24/sb.24.16003.xml",
    # "p.lond/p.lond.7/p.lond.7.2067.xml",
    # "p.ifao/p.ifao.2/p.ifao.2.31.xml",
    # "p.gen.2/p.gen.2.1/p.gen.2.1.4.xml",
    # "p.harr/p.harr.1/p.harr.1.109.xml",
    # "p.petr.2/p.petr.2.30.xml",
    # "sb/sb.16/sb.16.12255.xml",
    # "p.harr/p.harr.2/p.harr.2.193.xml",
    # "p.oxy/p.oxy.43/p.oxy.43.3118.xml",
    # "chr.mitt/chr.mitt.12.xml",
    # "sb/sb.12/sb.12.11001.xml",
    # "p.stras/p.stras.9/p.stras.9.816.xml",
    # "sb/sb.6/sb.6.9108.xml",
    # "p.yale/p.yale.1/p.yale.1.43.xml",

    if ENV['RAILS_ENV'] != 'test'
      if ENV['RAILS_ENV'] == 'development'
        user.admin = true
        user.save!

        Sosol::Application.config.dev_init_files.each do |pn_id|
          p = Publication.new
          p.owner = user
          p.creator = user
          p.populate_identifiers_from_identifiers(pn_id)
          p.save!
          p.branch_from_master

          e = Event.new
          e.category = "started editing"
          e.target = p
          e.owner = user
          e.save!
        end # each
      end # == development
    end # != test
  end # after_create

  before_destroy :remove_from_collections

  def human_name
    # get user name
    if self.full_name && self.full_name.strip != ""
      return self.full_name.strip
    else
      return who_name = self.name
    end
  end

  # Checks user acceptance against request terms version
  #  
  #*Args*
  # - version the terms version to check against
  #*Returns*
  # - true if the user has agreed to the site terms of service
  # - false if the user has not agreed to the site terms of service
  def accepted_terms?(version=0)
    return accepted_terms >= version
  end
  
  def jgit_actor
    org.eclipse.jgit.lib.PersonIdent.new(self.full_name, self.email)
  end

  # Copied from: https://raw.github.com/mojombo/grit/v2.4.1/lib/grit/actor.rb
  # Outputs an actor string for Git commits.
  #
  #   actor = Actor.new('bob', 'bob@email.com')
  #   actor.output(time) # => "bob <bob@email.com> UNIX_TIME +0700"
  #
  # time - The Time the commit was authored or committed.
  #
  # Returns a String.
  def output(time)
    out = @name.to_s.dup
    if @email
      out << " <#{@email}>"
    end
    hours = (time.utc_offset.to_f / 3600).to_i # 60 * 60, seconds to hours
    rem   = time.utc_offset.abs % 3600
    out << " #{time.to_i} #{hours >= 0 ? :+ : :-}#{hours.abs.to_s.rjust(2, '0')}#{rem.to_s.rjust(2, '0')}"
  end

  def author_string
    "#{self.full_name} <#{self.email}>"
  end

  def git_author_string
    local_time = Time.now
    "#{self.author_string} #{local_time.to_i} #{local_time.strftime('%z')}"
  end

  def get_collection

  end

  before_destroy do |user|
    user.repository.destroy
  end

  #Sends an email to all users on the system that have an email address.
  #*Args*
  #- +subject_line+ the email's subject
  #- +email_content+ the email's body
  def self.compose_email_for_all_users(subject_line, email_content)
    #get users that have email addresses
    users = User.where(email_opt_out: false).where("email IS NOT NULL")

    users.each { |user| user.compose_email(subject_line, email_content) }
  end

  def self.stats(user_id)
    if user_id.is_a? Integer
      stats = ActiveRecord::Base.connection.execute("select p.id AS pub_id, p.title AS pub_title, p.status AS pub_status, i.title AS id_title, c.comment AS comment, c.reason AS reason, c.created_at AS created_at from comments c LEFT OUTER JOIN publications p ON c.publication_id=p.id LEFT OUTER JOIN identifiers i ON c.identifier_id=i.id where c.user_id=#{user_id} ORDER BY c.created_at;")
      stats.each {|row|
        row["created_at"] = DateTime.parse(row["created_at"])
        unless row["comment"].nil?
          row["comment"] = URI.unescape(row["comment"]).gsub("+", " ")
        end
        }
    end
  end

  def uri
    "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.name)}"
  end

  def get_collection(create_if_missing = false)
    collection = CollectionsHelper::get_collection(self.pid)
    if create_if_missing && ! collection
      collection = CollectionsHelper::create_user_collection(user)
    end
    return collection.id
  end

  def compose_email(subject_line, email_content)
    if email.strip != "" && !email_opt_out
      EmailerMailer.announcement_email(email, subject_line, email_content).deliver
    end
  end

  private

    def remove_from_collections
      # TODO we should really add a rollback in case it fails..
      collection = CollectionsHelper::make_collection(self)
      CollectionsHelper::delete_collection(collection)
    end

end
