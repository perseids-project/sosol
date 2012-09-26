class CtsProxyController < ApplicationController

  def editions
    response = CTS::CTSLib.getEditionUrns(params[:inventory])
    render :text => response
  end
  
  def validreffs
    @publication = Publication.find(params[:publication_id])
    inventory = new_identifier.related_inventory
    response = CTS::CTSLib.proxyGetValidReff(inventory, params[:urn], params[:level])
    render :text => response
  end
  
  def translations
    response = CTS::CTSLib.getTranslationUrns(params[:inventory],params[:urn])
    render :text => response
  end
  
  def citations
    response = CTS::CTSLib.getCitationLabels(params[:inventory],params[:urn])
    render :text => response
  end
  
  def getpassage
    if (params[:id] =~ /^\d+$/)
      documentIdentifier = Identifier.find(params[:id])
      inventory = documentIdentifier.related_inventory.xml_content
      uuid = documentIdentifier.publication.id.to_s + params[:urn].gsub(':','_') + '_proxyreq'
      response = CTS::CTSLib.getPassageFromRepo(inventory,documentIdentifier.content,params[:urn],uuid)
    else
      response = CTS::CTSLib.proxyGetPassage(params[:id],params[:urn])
    end
    render :text => JRubyXML.apply_xsl_transform(
                      JRubyXML.stream_from_string(response),
                      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                      %w{data xslt cts extract_text.xsl})))  
  end
  
  def getcapabilities
    response = CTS::CTSLib.proxyGetCapabilities(params[:collection])
    render :text => JRubyXML.apply_xsl_transform(
                      JRubyXML.stream_from_string(response),
                      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                      %w{data xslt cts inventory_to_json.xsl})))
  end
  
  def getrepos
    render :text => CTS::CTSLib.getExternalCTSReposAsJson()
  end

end
