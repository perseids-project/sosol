require 'uri'

class CommentaryCiteIdentifier < CiteIdentifier   
  include OacHelper


  FRIENDLY_NAME = "Commentary Annotation"
  PATH_PREFIX="CITE_COMMENTARY_XML"
  FILE_TYPE="oac.xml"
  MAX_COMMENTARY_LENGTH = 525
  
  ##################################################
  # Public Class Method Overrides
  ##################################################

  # @overrides Identifier#preprocess
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(urn,content)
    #  this is where we can apply a word count limit
    #  transform can check language and apply tokenization
    #  rules per language
    #  default for base class is to allow any word length so
    #  will just return the original content
    max = MAX_COMMENTARY_LENGTH
    # -1 or undefined means no limit
    if (max.nil? || max < 0)
      return content
    else
      passed = JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt cite markdown_field_verify.xsl})),
          :e_max => max)
      if (passed == 'true')
        return content
      elsif (passed == 'error')
        raise Cite::CiteError.new("Unable to process commentary text.")
      else
        raise Cite::CiteError.new("Commentary text has #{passed} words, which exceeds the maximum of #{max}.")
     end
   end
  end

  ##################################################
  # Public Instance Method Overrides
  ##################################################

  # @overrides Identifier#file_template
  # uses identifier-specific variables
  def file_template()
    template_path = File.join(Rails.root, ['data','templates'],
                              "#{self.class.to_s.underscore}.xml.erb")

    template = ERB.new(File.new(template_path).read, nil, '-')
    annotation_uri = Sosol::Application.config.site_cite_collection_namespace + "/" + self.urn_attribute
    body_uri = annotation_uri + "/commentary"
    # TODO support user default for commentary language
    body_language = 'eng'
    date = Time.new
    annotator_uri = make_annotator_uri()
    return template.result(binding)
  end

  # @overrides Identifier#change_desc
  # to ensure consistent file formatting
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # this is a no-op because change desc is not added to this file
    # need to override to ensure consistent formatting of XML for all commits
    toXmlString self.rdf
  end
  
  # @overrides Identifier#set_content to reset memoized value set in CommentaryCiteIdentifier#rdf
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    @rdfDocX = nil
    super
  end

  # @overrides Identifier#before_commit
  # To preprocess the commentary
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> CommentaryCiteIdentifier XML as string
  def before_commit(content)
    CommentaryCiteIdentifier.preprocess(self.urn_attribute,content)
  end

  # @overrides Identifier#is_valid_xml?
  # we don't currently validate the CiteCommentary Contents
  # but we should
  def is_valid_xml?(content)
    return true
  end

  # @overrides Identifier#after_rename
  # updates the annotation uris to reflect the new name
  def after_rename(options = {})
    annot_uri = Sosol::Application.config.site_cite_collection_namespace + "/" + self.urn_attribute
    body_uri = annot_uri + "/commentary"
    OacHelper::update_annotation_uris(get_annotation,annot_uri,body_uri)
    oacRdf = toXmlString self.rdf
    # TODO should either update annotatedAt or set updatedAt (does that exist??)
    self.set_xml_content(oacRdf, :comment => 'Update uris to reflect new identifier')
  end

  # @overrides Identifier#mimetype
  def mimetype
    'application/rdf+xml'
  end

  # @overrides Identifier#schema
  def schema
    'http://www.openannotation.org/spec/core/'
  end


  ##################################################
  # Public ComentaryCiteIdentifier Instance Methods
  ##################################################


  # Get the language of the body of the Commentary
  def language()
    OacHelper::get_body_language(get_annotation)
  end

  # Get the text of the commentary
  def get_commentary_text()
    OacHelper::get_body_text(get_annotation)
  end

  # Get the target of the commentary
  def get_targets()
    OacHelper::get_targets(get_annotation)
  end

  # Update the commentary
  def update_commentary(a_lang,a_text,a_comment)
    OacHelper::update_body_text(get_annotation,a_lang,a_text)
    oacRdf = toXmlString self.rdf
    # TODO should either update annotatedAt or set updatedAt (does that exist??)
    self.set_xml_content(oacRdf, :comment => a_comment)
  end

  # Update the commentary targets
  def update_targets(a_targets,a_comment)
    OacHelper::update_targets(get_annotation,a_targets)
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => a_comment)
  end

  # @overrides Identifier#get_topic
  def get_topics()
    uris = {} 
    annotation = self.get_annotation()
    # we have to check that we have an annotation because this might get called
    # before the identifier has any contents
    unless annotation.nil?
      OacHelper::get_targets(annotation).each do |t|
        uris[t] = {}
      end
    end
    return CTS::CTSLib::validate_and_parse(uris)
  end

  ##################################
  # Private Helper Methods
  ##################################
  protected

    # return the RDF of the oac.xml as an REXML::Document
    def rdf
      @rdfDocX ||= REXML::Document.new(self.xml_content)
    end

    # Converts REXML::Document / ::Element into xml string
    # - *Args*  :
    #   - +xmlObject+ → REXML::Document / ::Element
    # - *Returns* :
    #   - +String+ formatted xml string using child class PrettySsime of parent class +REXML::Formatters::Pretty+
    def toXmlString xmlObject
      formatter = PrettySsime.new
      formatter.compact = true
      formatter.width = 2**32
      modified_xml_content = ''
      formatter.write xmlObject, modified_xml_content
      modified_xml_content
    end

    # get just the annotation
    def get_annotation()
      OacHelper::get_first_annotation(self.rdf)
    end
end
