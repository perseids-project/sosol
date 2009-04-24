class Board < ActiveRecord::Base
	has_many :articles
	has_many :users
	has_many :decrees
	has_many :emailers
	
	#has_many :users
	#belongs_to :user
	has_and_belongs_to_many :users
	

	   
	 def tally_votes(votes)
	 #work in progress
	 #how to determine order -- just assume user hasn't made rules where multiple decress can be true at once?
	 #errMsg = " "	 	
	   self.decrees.each do |decree|


			#pull choices out
			decree_choices = decree.choices.split(' ')	     
			#count votes
			decree_vote_count = 0
			votes.each do |vote|	      
	     		#see if vote is in choices
			  	index = decree_choices.index(vote.choice) #double check that this doesn't return true for no in known
			  	if  index != nil
						decree_vote_count = decree_vote_count + 1      	     
					end
			end	
			   
			#see if we are using percent or min voting counting
			if decree.trigger < 1
			#percentage
					if decree_vote_count > 0
						percent = self.users.length.to_f / decree_vote_count.to_f
					
						if percent >= decree.trigger
						#check if the action has already been done
						#do the action? or return the action?
						#	  
						#errMsg += percent.to_s  
						return decree.action
					end
				end
			else 
			#min vote count
				if decree_vote_count >= decree.trigger
				#check if the action has already been done
				#do the action? or return the action?
				#
				#errMsg += " " + decree_vote_count + " " + vote.choice + " " 
				return decree.action
				end
			
			end
			   	    
	   end	 	#decree 

#raise errMsg
		return ""
		
	 end #tally_votes
	
	
	
end
