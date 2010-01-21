#Decrees represent the possible choices, outcomes and counting methods of a vote.
class Decree < ActiveRecord::Base
  belongs_to :board
  
  TALLY_METHODS = Hash[%w{percent count}.map {|i| [i.to_sym, i]}]
  
  validates_inclusion_of :tally_method,
                         :in => TALLY_METHODS.values
                         
  validates_presence_of :tally_method
  
  def self.tally_methods_hash
  #hash with friendly name for valid tally methods. Mainly for setting selection on forms.
    { "Percentage" => TALLY_METHODS[:percent], "Absolute Count" => TALLY_METHODS[:count]}
  end
  
 # def self.result_actions_hash
  #hash with friendly name for valid decree actions. Mainly for setting selection on forms.
#    {"Approve" => "approve", "Reject" => "reject", "Graffiti" => "graffiti" } 
#  end
  
  #Returns an array of the possible choices that represent this decree.
  def get_choice_array
    self.choices.split(' ')  
  end
  
  def perform_action?(votes)
    #pull choices out
    decree_choices = self.get_choice_array
    #count votes
    decree_vote_count = 0
    votes.each do |vote|
      #see if vote is in choices
      if decree_choices.include?(vote.choice)
        decree_vote_count = decree_vote_count + 1
      end
    end

    #see if we are using percent or min voting counting
    if tally_method == TALLY_METHODS[:percent]
      #percentage
      if decree_vote_count > 0 && self.board.users.length.to_f > 0
        percent =  decree_vote_count.to_f / self.board.users.length.to_f

        if percent >= self.trigger
          #check if the action has already been done
          #do the action? or return the action?
          #   
          #errMsg += percent.to_s
          return true
        end
      end
    elsif tally_method == Decree::TALLY_METHODS[:count]
      #min absolute vote count
      if decree_vote_count >= self.trigger
        #check if the action has already been done
        #do the action? or return the action?
        #
        #errMsg += " " + decree_vote_count + " " + vote.choice + " " 
        return true
      end
    end
    
    return false
  end
end
