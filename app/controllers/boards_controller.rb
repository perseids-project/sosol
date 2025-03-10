class BoardsController < ApplicationController

  #layout "site"
  #layout "header_footer"
  before_filter :authorize
  before_filter :check_admin, :only => [:index, :new, :create, :destroy, :rank, :update_rankings, :confirm_destroy, :send_board_reminder_emails]
  before_filter :check_community_admin, :only => [:overview, :find_member, :add_member, :remove_member, :edit, :update, :show, :apply_rules, :confirm_apply_rules, :find_member_finalizer, :set_member_finalizer, :remove_member_finalizer ]


  #Ensures user has admin rights to view page. Otherwise returns 403 error.
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render :file => 'public/403', :status => '403', :layout => false, :formats => [:html]
    end
  end

  #Ensures user has full admin rights or at least community admin rights for a community board
  def check_community_admin
    find_board
    return if @current_user &&
      (@current_user.admin || (@board.community_id && @board.community.admins.include?(@current_user)))
    render :file => 'public/403', :status => '403', :formats => 'html'
  end


  #Presents overview for publication.
  # @deprecated ? This is not used in Perseids
  def overview
    # find_board is called from check_community_admin filter to set @boardt
    if @board.users.find_by_id(@current_user.id) || @current_user.developer
      # below is dangerous since it will expose publications to non owners
      #finalizing_publications = Publication.find(:all, :conditions => "status == 'finalizing'")
      
      #return only owner publications
      finalizing_publications = Publication.find_all_by_owner_id(@current_user.id, :conditions =>  { :status => 'finalizing'} )    

      if finalizing_publications
        @finalizing_publications = finalizing_publications.collect{|p| p.parent.owner == @board ? p :nil}.compact
      else
       @finalizing_publications = nil
      end
    else
      #dont let them have access
      redirect_to dashboard_url
      return
    end
    
  end
  
  def find_member
    # find_board is called from check_community_admin filter to set @board
  end

  def find_member_finalizer
    find_board
    @members = @board.users
  end

  #Adds the user to the board member list.
  def add_member
    # find_board is called from check_community_admin filter to set @board
    user = User.find_by_name(params[:user_name].to_s)

    if nil == @board.users.find_by_id(user.id) 
      @board.users << user
      @board.save
    end

    redirect_to :action => "edit", :id => (@board).id
  end

  #Removes a member from the board member list.
  def remove_member
    user = User.find(params[:user_id].to_s)

    # find_board is called from check_community_admin filter to set @board
    if @board.finalizer_user == user
      @board.finalizer_user = nil
    end
    @board.users.delete(user)
    @board.save

    redirect_to :action => "edit", :id => (@board).id
  end

  # Sets the default finalizer for the board
  def set_member_finalizer
    find_board
    if nil == @board.users.find_by_id(params[:user_id])
      flash[:error] = "User #{params[:user_name]} is not a member of this board."
    else 
      @board.finalizer_user = User.find(params[:user_id])
      @board.save
      flash[:notice] = "Default finalizer updated to #{params[:user_name]}."
    end
    redirect_to :action => :edit, :id => (@board).id
  end

  # Removes the default finalizer for the board
  def remove_member_finalizer
    @board.finalizer_user = nil
    @board.save
    flash[:notice] = "Default finalizer removed."
    redirect_to :action => :edit, :id => (@board).id
  end

  # GET /boards
  # GET /boards.xml
  def index
    @communities = Community.order('friendly_name ASC').all
    @boards = {}
    @communities.each do |c|
      @boards[c.friendly_name] = Board.ranked_by_community_id(c.id)
    end
    # for backwards compatibility, include boards without communities
    if Sosol::Application.config.allow_canonical_boards
        @boards['No Community'] = Board.ranked_by_community_id(nil)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @boards }
    end
  end

  # GET /boards/1
  # GET /boards/1.xml
  def show
    find_board
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @board }
    end
  end

  # GET /boards/new
  # GET /boards/new.xml
  def new
    
    @board = Board.new
    
    #don't let more than one board use the same identifier class
    @available_identifier_classes = Array.new(Identifier::IDENTIFIER_SUBCLASSES)

    #existing_boards = Board.find(:all)
    #existing_boards.each do |b|
    #  @available_identifier_classes -= b.identifier_classes
    #end
    
    @board.community_id =  params[:community_id].to_s

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @board }
    end
  end

  # GET /boards/1/edit
  def edit
    find_board
    @available_identifier_classes = Array.new(Identifier::IDENTIFIER_SUBCLASSES) - @board.identifier_classes
  end

  # POST /boards
  # POST /boards.xml
  def create


    @board = Board.new(params[:board])
    
    @board.identifier_classes = []

    #let them choose as many ids as they want
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.has_key?(identifier_class) && params[identifier_class].to_s == "1"
        @board.identifier_classes << identifier_class
      end
    end

    #put the new board in last rank
    @board.rank = Board.ranked_by_community_id( @board.community_id ).count  + 1 #+1 since ranks start at 1 not 0. Also new board has not been added to count until it gets saved.
    #just let them choose one identifer class
    #@board.identifier_classes << params[:identifier_class]
    

    mailers = YAML::load_file(File.join(Rails.root, %w{config board_mailers.yml}))[:mailers] || { :default => [] }
    if @board.community && mailers[@board.community.type] 
      mailers =  mailers[@board.community.type]
    else
      mailers =  mailers[:default]
    end
    mailers.each do | m |
      m[:board_id] = @board.id
      e = Emailer.new(m)
      if e.save
        @board.emailers << e
      else 
        flash[:warning]  = "Unable to save mailer"
      end
    end
     
    if @board.save
      flash[:notice] = 'Board was successfully created.'
      redirect_to :action => "edit", :id => (@board).id
    else
      @board.emailers.each do | m | 
        m.destroy
      end
      flash[:error] = "Board creation failed. #{@board.errors.to_a}"
      redirect_to dashboard_url
    end         
  end

  # PUT /boards/1
  # PUT /boards/1.xml
  def update
    find_board
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      if params.has_key?(identifier_class) && params[:"#{identifier_class}"].to_s == "1"
        @board.identifier_classes << identifier_class
      end
    end

    respond_to do |format|
      board_params = params[:board].slice(:friendly_name, :skip_finalize, :requires_assignment, :max_assignable)

      if @board.update_attributes(board_params)
        flash[:notice] = 'Board was successfully updated.'
        format.html { redirect_to(@board) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @board.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /boards/1
  # DELETE /boards/1.xml
  def destroy
    find_board
    @board.destroy

    respond_to do |format|
      format.html { redirect_to(boards_url) }
      format.xml  { head :ok }
    end
  end

  #*Returns* array of boards sorted by rank. Lowest rank (highest priority) first.
  #If community_id is given then the returned boards are only for that community.
  #If no community_id is given then the now deprecated "sosol" boards are returned. 
  def rank
    @boards = Board.ranked_by_community_id( params[:community_id] )
    @community_id = params[:community_id].to_s 
  end

  #Sorts board rankings by given array of board id's and saves new rankings.
  def update_rankings

    @boards = Board.ranked_by_community_id( params[:community_id] )
    
    #@boards = Board.find(:all)

    rankings = params[:ranking].to_s.split(',');
    
    rank_count = 1
    rankings.each do |rank_id|
      @boards.each do |board|
        if (board.id == rank_id.to_i)
          board.rank = rank_count
          board.save!
          break;
        end
      end
      rank_count+= 1
    end
    
    
    if params[:community_id].to_s
      redirect_to :controller => 'communities', :action => 'edit',  :id => params[:community_id].to_s
      return
    else
      #default to sosol boards
      redirect_to :action => "index"
      return
    end
    
  end

  # Displays confirmation screen for application of decree rules
  def confirm_apply_rules
    find_board
  end

  # Responds to affirmative confirmation from confirm_apply_rules
  # by iteratating through all board publications in the voting state
  # and calling publication.tally_votes with the apply_rules flag set to
  # true to initiate action if decree rules allow
  def apply_rules
    find_board
    notices = []
    @publications = Publication.where({:owner_id => @board.id,  :status => :voting})
    @publications.each do |p|
      action = p.tally_votes(nil,true)
      if action.nil? || action == ""
        notices << "Rule thresholds not met for #{p.title}"
      else
        notices << "Initiated #{action} for #{p.title}"
      end
    end
    flash[:notice] = notices.join("<br/>")
    redirect_to :controller => :user, :action => :board_dashboard, :board_id => @board.id
  end


  def send_board_reminder_emails
    
    addresses = Array.new

    boards = Board.ranked_by_community_id(params[:community_id])
    community = Community.find_by_id(params[:community_id])


    body_text = 'Greetings '
    if community
      body_text += community.name + " "
    end
    time_str = Time.now.strftime("%Y-%m-%d")
    body_text += "Board Members, as of " + time_str  + ", "
    boards.each do |board|
      #grab addresses for this board
      board.users.each do |board_user|
        addresses << board_user.email
      end

      body_text += "\n" + board.name + " has "

      #find all pubs that are still in voting phase
      voting_publications = board.publications.collect{|p| p.status == 'voting' ? p : nil}.compact
      #voting_publications = Publication.find_all_by_owner_id(board.id, :conditions => {:owner_type => 'Board', :status => "voting"}  )
      if voting_publications
        body_text += voting_publications.length.to_s
      else
        body_text += "no"
      end
      body_text += " publications requiring voting action, "

      body_text += " and "

      approved_publications = board.publications.collect{|p| p.status == 'approved' ? p : nil}.compact
      #approved_publications = Publication.find_all_by_owner_id(board.id, :conditions => {:owner_type => "Board", :status => "approved" }  )
      if approved_publications
        body_text += approved_publications.length.to_s
      else
        body_text += "no"
      end
      body_text += " approved publications waiting to be finalized.  "


      completed_publications = board.publications.collect{|p| (p.status == 'committed' || p.status == 'archived') ? p : nil}.compact

      if completed_publications
        body_text += completed_publications.length.to_s
      else
        body_text += "No"
      end
      body_text += " publications have been committed."


      subject_line = ""
      if community
        subject_line += community.name + " "
      end
      subject_line += "Board Publication Status Reminder "

      addresses.each do |address|
        if address && address.strip != ""
          begin
            EmailerMailer.general_email(address, subject_line, body_text).deliver
          rescue Exception => e
            Rails.logger.error("Error sending email: #{e.class.to_s}, #{e.to_s}")
          end
        end
      end
    end


    if community
      flash[:notice] = "Notifications sent to all " + community.name + " board members."
    else
      flash[:notice] = "Notifications sent to all PE board members."
    end
    redirect_to dashboard_url
  end

  def confirm_destroy
    find_board
  end

  protected
    def find_board
      @board = Board.find(params[:id].to_s)
    end

end
