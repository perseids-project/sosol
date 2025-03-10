
##Board represents an editorial review board.
class Board < ActiveRecord::Base
  has_many :decrees, :dependent => :destroy
  has_many :emailers, :dependent => :destroy
  
  has_many :votes
  
  has_many :boards_users
  has_many :users, :through => :boards_users
  belongs_to :finalizer_user, :class_name => 'User'
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner

  belongs_to :community


  #board rank determines workflow order for publication
  scope :sorted_by_community_and_ranked, :order => 'community_id ASC, rank ASC' 

  #ranked scopes returns the boards for a given community in order of their rank
  scope :ranked_by_community_id,  lambda { |id_in| { :order => 'rank ASC', :conditions => { :community_id => id_in } } }


  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes
  
  validates_uniqueness_of :title, :case_sensitive => false, :scope => [:community_id]

  # it would be nice to validate the presence of community too but we need
  # to be backwards-compatible
  validates_presence_of :title
  
  has_repository
  
  # Workaround, repository needs owner name for now.
  def name
    return title
  end
  
  def human_name
    return title
  end

  def jgit_actor
    org.eclipse.jgit.lib.PersonIdent.new(self.title, Sosol::Application.config.site_email_from)
  end
  
  after_create do |board|
    board.repository.create
  end
  
  before_destroy do |board|
    repository.destroy
  end
  
  #The original idea was to allow programmers to add whatever functionality they wanted to an identifier.
  #This functionality would be contained in a method called result_action_*.
  #When a decree is set up the list of possible result_actions would be parsed from these methods and be presented to the user in a drop down list to choose.
  #Currently (10-10-2011, CSC) I believe this is only used to make the drop down list when creating a decree. The default values are found in the identifier model.
  #
  #*Returns*
  #- string list of possible actions to be taken on an identifier (a.k.a. decree actions)
  def result_actions
    #return array of possible actions that can be implemented
    retval = []
    identifier_classes.each do |ic|
      im = ic.constantize.instance_methods
      match_expression = /(result_action_)/
      im.each do |method_name|
        if method_name =~ /(result_action_)/
          retval << method_name.to_s.sub(/(result_action_)/, "")
        end
      end
    end
    retval
    
  end
  
  #*Returns*:
  #- result_actions in a capitalized hash list for the select statement
  def result_actions_hash  
    ra = result_actions    
    ret_hash = {}
    
    #create hash
    ra.each do |v|
      ret_hash[v.sub(/_/, " ").capitalize] = v
    end
    ret_hash
  end

  
  #*Args*:
  #- +identifier+ identifier or subclass of identifier
  #*Returns*:
  #- +true+ if this board is responsible for the given identifier
  #- +false+ otherwise 
  def controls_identifier?(identifier)
    # For APIS boards there is only a single identifier class (APISIdentifier) across
    # all boards.
   if "APISIdentifier" == identifier.class.to_s
     self.identifier_classes.include?(identifier.class.to_s) && identifier.name.include?(self.title.downcase)
   else 
     self.identifier_classes.include?(identifier.class.to_s)  
   end
  end
  
  #Tallies the votes and returns the resulting decree action or returns an empty string if no decree has been triggered.
  #
  #*Args*:
  #- +votes+ the publication's votes
  #*Returns*:
  #- nil if no decree has been triggered
  #- decree action if the votes trigger a decree, if multiple decrees could be triggered by the vote count, only the first in the list will be returned.
  def tally_votes(votes)
    Rails.logger.info("Board#tally_votes on Board: #{self.inspect}\nWith votes: #{votes.inspect}")
    # NOTE: assumes board controls one identifier type, and user hasn't made
    # rules where multiple decrees can be true at once
    
    self.decrees.each do |decree|
      if decree.perform_action?(votes)
        Rails.logger.info("Board#tally_votes success on Board: #{self.inspect}\nFor decree: #{decree.inspect}\nWith votes: #{votes.inspect}")
        return decree.action
      end
    end
    
    return ""
  end #tally_votes

  # Checks to see if the decrees for this board have 
  # any rules associated with them
  #
  #*Returns*:
  # - true if there are rules
  # - false if there are none
  def has_rules?
    has_rules = false
    self.decrees.each do |decree|
      if decree.rules.size > 0
        has_rules = true
        break
      end
    end
    return has_rules
  end

  # Checks to see if the decrees for this board have 
  # any rules associated with them that can be applied
  # and if so returns the action that the rule would invoke
  # *Returns*:
  #   - the first action to be involved to a decree rule
  #   - or the empty string if no action applies
  def apply_rules(votes)
    self.decrees.each do |decree|
      decree.rules.each do |rule|
        if rule.apply_rule?(votes)
          return decree.action
        end
      end
    end
    return ""
  end


  # Sort a set of votes by the decree to which they apply
  # *Args*
  # - +votes+ the votes
  # *Returns*
  # - a hash whose keys are the decree action and whose values are the array of applicable votes
  def votes_per_decree(votes)
    status = Hash.new
    self.decrees.each do |decree|
      status[decree.action] = []
      votes.each do |v|
        if decree.is_vote_for_action?(v)
          status[decree.action] << v
        end
      end
    end
    status
  end
  

  #Will generally be called when the status of a publication is changed.
  #Emails will be sent according to emailer settings for the board.
  #
  #*Args*: 
  #- +when_to_send+ the new status of the publication.
  #- +publication+ the publication whose status has just changed.
  def send_status_emails(when_to_send, publication)
    #search emailer for status
    if self.emailers == nil
      return
    end
   
    #find identifiers for email
    email_identifiers = Array.new
    publication.identifiers.each do |identifier|
      if self.identifier_classes.include?(identifier.class.to_s)
        email_identifiers << identifier      
      end
    end

    self.emailers.each do |mailer|
      if mailer.when_to_send == when_to_send
        #send the email
        addresses = Array.new	
  	#--addresses
  			
        #board members
        if mailer.send_to_all_board_members
          self.users.each do |board_user|          
            addresses << board_user.email        
          end
        end
        
        #other sosol users
        if mailer.users
          mailer.users.each do |user|
            if user.email != nil
              addresses << user.email
            end
          end
        end
        
        #extra addresses
        if mailer.extra_addresses
          extras = mailer.extra_addresses.split(" ")
          extras.each do |extra|
            addresses << extra
          end
        end
        
        #owner address
  	if mailer.send_to_owner
  	  if publication && publication.creator && publication.creator.email
  	    addresses << publication.creator.email
  	  end
  	end
        # the board publication should be the one owned by the board initiating the mail 
        # it may or may not be the same as the publication that is the subject of the mail as that
        # depends upon what when_to_send status is.  Traversing all the children of the original publication
        # and selecting the last one which has the current board as its owner should work.
        board_publication = email_identifiers[0].publication.origin.all_children.select {|p| p.owner == self}.last
        begin
          EmailerMailer.identifier_email(when_to_send,email_identifiers,board_publication,addresses,mailer.include_document,mailer.include_comments,mailer.message,mailer.subject).deliver
        rescue Exception => e
          Rails.logger.error("Error sending email: #{e.class.to_s}, #{e.to_s}")
        end
      end	
    end
  end


  #Since friendly_name is an added feature, the existing boards will not have this data, so for backward compatability we may need to make it up.
  #This method could be removed after initial deploy.
  def friendly_name=(fn)
    if fn && (fn.strip != "")
      self[:friendly_name] = fn
    else
      self[:friendly_name] = self[:title]
    end
    
  end
  
  #Since board title is used to determine repository names, the title cannot be changed after board creation.
  #This friendly_name allows the users another name that they can change at will. 
  #*Returns*:  
  #- friendly_name if it has been set. Otherwise returns title.
  def friendly_name
    fn = self[:friendly_name]
    if fn && (fn.strip != "")
      return fn
    else
      return self[:title]
    end
  end

end
