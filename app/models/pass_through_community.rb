# a Pass Through community is one which funnels publications
# to another community or an external agent upon completion
class PassThroughCommunity < Community

  validate :pass_to_must_be_valid

  def pass_to_must_be_valid
    # must  be a valid object and not itself
    if self.pass_to == self.name || pass_to_obj.nil?
      errors.add(:pass_to, "Must be a valid Community Name or Agent URI")
    end
  end

  def pass_to_obj
    if self.pass_to.nil?
      return nil  
    end
    # it's either a community or an external agent
    Community.find_by_name(self.pass_to) || AgentHelper::agent_of(self.pass_to)
  end

  #Checks to see whether or not to allow members to submit to the community
  # Overrides the base class method to require an end_user
  #
  #*Returns*
  #- true if the community is setup properly to receive submissions
  #- false if community should not be submitted to
  def is_submittable?
    #if there is nowhere for the final publication to go, don't let them submit
    #if there are no boards to review the publication, don't let them submit
    return !self.pass_to_obj.nil? && (self.boards && self.boards.length > 0)
  end

  # Promotes a publication to the next step in the workflow
  # after board approval.
  #
  # For a PassThrough community this means it either
  # gets submitted to the next community or sent off
  # to an agent
  # 
  # *Args* +publication+ the publication to promote
  #
  def promote(publication)
    #copy to  space
    Rails.logger.debug "----pass through to get it"
    next_obj = self.pass_to_obj
    Rails.logger.debug "---" + next_obj.inspect

    if next_obj.class.name =~ /Community/
      # switch publication community to the new community
      publication.community = next_obj
      # reset everything back to editing
      publication.status = "editing"
      publication.identifiers.each do |id|
        id.status = "editing"
        id.save
      end
      # TODO maybe we need an event here?
      publication.submit_to_next_board
    else
      begin
        agent_client = AgentHelper::get_client(next_obj)
        if agent_client.nil?
          raise Exception.new("Unable to get client for #{next_obj.inspect}")
        end
        publication.send_to_agent(agent_client)
        # the original publication is done now so we can
        # set the status of the original publication
        # to committed
        publication.origin.change_status("committed")
      rescue Exception => e
        Rails.logger.error(e) 
        Rails.logger.error(e.backtrace) 
        raise Exception.new("Unable to send finalization copy to agent. Message was #{e.message}")
      end
    end
  end

  def finalize(publication)
    if self.pass_to_obj.nil?
      raise Exception("No pass through point for the community. Unable to finalize")
    end
  end

end
