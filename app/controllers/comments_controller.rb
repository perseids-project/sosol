class CommentsController < ApplicationController
  before_filter :authorize
  before_filter :ownership_guard, :only => [:destroy, :edittext]
  before_filter :admin_guard, :only => [:index, :edit ]
  
  layout false
  # GET /comments
  # GET /comments.xml
  def index
    @comments = Comment.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET
  # - shows current comments and gives form for new comment
  def ask_for
    @publication = Publication.find(params[:publication_id].to_s)
    @publication_id = @publication.origin.id
   
    if (params[:identifier_id] && params[:identifier_id] != '') 
      @identifier = Identifier.find(params[:identifier_id].to_s)
      @identifier_id  = @identifier.origin.id
    end   
    @comments = Comment.find_all_by_publication_id(@publication_id, :order => 'created_at').reverse

  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = Comment.find(params[:id].to_s)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = Comment.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.find(params[:id].to_s)
  end

  # GET /comments/1/edittext
  def edittext
    @comment = Comment.find(params[:id].to_s)
    @from = params[:from]
  end

  # POST /comments
  # POST /comments.xml
  def create
  
    @comment = Comment.new(params[:comment])

    @comment.user_id = @current_user.id
 #   if params[:reason] != nil
 #     @comment.reason = params[:reason]
 #   end
  
    respond_to do |format|
      if @comment.save
        flash[:notice] = 'Comment was successfully created.'
        
        #url will not work correctly without :id, however id is not used in ask_for, so we just use 1
        format.html { redirect_to :id => 1, :controller => "comments", :action => "ask_for", :publication_id => @comment.publication_id, :identifier_id => @comment.identifier ? @comment.identifier.id : '', :method => "get" }
        #format.html { redirect_to(@comment) }
        #TODO redirect xml?
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = Comment.find(params[:id].to_s)

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { 
          if params[:from] == 'ask_for' 
            redirect_to :id => 1, :controller => "comments", :action => "ask_for", :publication_id => @comment.publication_id, :identifier_id => @comment.identifier ? @comment.identifier.id : '', :method => "get" 
          else
            redirect_to(@comment)
          end
        }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    # ownership_guard on destroy sets @comment
    @comment.destroy

    respond_to do |format|
      flash[:notice] = 'Comment was successfully deleted'
      format.html { 
        if params[:publication_id]
          redirect_to :id => 1, :controller => "comments", :action => "ask_for", :publication_id => params[:publication_id], :identifier_id => params[:identifier_id], :method => "get" 
        else
          redirect_to(comments_url) 
        end
      }
      format.xml  { head :ok }
    end
  end

  protected
    def ownership_guard
      @comment = Comment.find(params[:id].to_s)
      if @comment.user != @current_user || (@comment.reason != 'general' && @comment.reason != 'review')
        flash[:error] = 'Operation not permitted.'
        redirect_to dashboard_url and return
      end
    end

    def admin_guard
      unless @current_user.admin
        flash[:error] = "This action requires administrator rights"
        redirect_to dashboard_url and return
      end
    end

end
