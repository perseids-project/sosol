FactoryGirl.define do  

  sequence :name do |n|
    "name_#{n}"
  end

  sequence :full_name do |n|
    "Full Name #{n}"
  end

  sequence :email do |n|
      "person#{n}@example.com"
  end

  sequence :hgv_identifier_string do |n|
    "oai:papyri.info:identifiers:hgv:P.Fake:#{n}"
  end

  sequence :hgv_number do |n|
    "hgv#{n}"
  end

  sequence :ddb_identifier_string do |n|
    "oai:papyri.info:identifiers:ddbdp:0001:1:#{n}"
  end

  sequence :syriaca_identifier_string do |n|
    "http://syriaca.org/place/#{n}"
  end

  sequence :syriaca_person_identifier_string do |n|
    "http://syriaca.org/person/#{n}"
  end

  sequence :syriaca_work_identifier_string do |n|
    "http://syriaca.org/work/#{n}"
  end

  sequence :epi_cts_identifier_string do |n|
    "perseus/greekLit/tlg0012/tlg001/edition/perseus-grc#{n}"
  end

  sequence :treebank_cite_identifier_string do |n|
    "cite/perseus/lattb.#{n}.1"
  end

  factory :board do |f|
    f.title { FactoryGirl.generate(:name) }
    f.category 'category'
    f.identifier_classes ['DDBIdentifier']
  end

  factory :community_board, :parent => :board do |f|
    f.association :community
  end

  factory :apis_board, :parent => :board do |f|
    f.decrees { |decrees|
      [
        decrees.association(
          :count_decree,
          :trigger => 1.0,
          :board => nil,
          :action => "approve",
          :choices => "accept"),
        decrees.association(
          :count_decree,
          :trigger => 1.0,
          :board => nil,
          :action => "reject",
          :choices => "reject")
      ]
    }
    f.identifier_classes ['APISIdentifier']
  end

  factory :hgv_board, :parent => :board do |f|
    f.decrees { |decrees|
      [
        decrees.association(
          :percent_decree,
          :board => nil,
          :trigger => 100.0,
          :action => "approve",
          :choices => "yes no"),
        decrees.association(
          :count_decree,
          :trigger => 1.0,
          :board => nil,
          :action => "reject",
          :choices => "reject"),
        decrees.association(
          :count_decree,
          :trigger => 1.0,
          :board => nil,
          :action => "graffiti",
          :choices => "graffiti")
      ]
    }
  end

  factory :hgv_community_board, :parent => :hgv_board do |f|
    f.association :community
  end

  factory :hgv_meta_board, :parent => :hgv_board do |f|
    f.identifier_classes ['HGVMetaIdentifier']
  end


  factory :hgv_meta_community_board, :parent => :hgv_community_board do |f|
    f.identifier_classes ['HGVMetaIdentifier']
  end

  factory :hgv_trans_board, :parent => :hgv_board do |f|
    f.identifier_classes ['HGVTransIdentifier']
  end

  factory :hgv_trans_community_board, :parent => :hgv_community_board do |f|
    f.identifier_classes ['HGVTransIdentifier']
  end

  factory :master_community_board, :parent => :hgv_community_board do |f|
    f.identifier_classes ['DDBIdentifier','HGVMetaIdentifier','HGVTransIdentifier']
  end

  factory :syriaca_community_board, :parent => :hgv_community_board do |f|
    f.identifier_classes ['SyriacaIdentifier']
  end

  factory :syriaca_person_community_board, :parent => :hgv_community_board do |f|
    f.identifier_classes ['SyriacaPersonIdentifier']
  end


  factory :user do |f|
    f.name { FactoryGirl.generate(:name) }
    f.full_name { FactoryGirl.generate(:full_name) }
    f.email { FactoryGirl.generate(:email) }
  end

  factory :admin, :parent => :user do |f|
    f.admin true
  end

  factory :decree do |f|
    f.association :board
    f.tally_method Decree::TALLY_METHODS[:percent]
  end

  factory :percent_decree, :parent => :decree do |f|
    f.tally_method Decree::TALLY_METHODS[:percent]
  end

  factory :count_decree, :parent => :decree do |f|
    f.tally_method Decree::TALLY_METHODS[:count]
  end

  factory :rule do |f|
    f.expire_days 1
    f.floor 1
  end


  factory :emailer do |f|
    f.association :board
    f.extra_addresses ''
    f.include_document 'false'
    f.include_comments 'false'
    f.message 'MyText'
    f.subject 'MySubject'
  end

  factory :event do |f|
    f.category 'commit'
  end

  factory :vote do |f|
    f.association :user
    f.association :publication
    f.choice :choice #'MyString'
  end


  factory :publication do |f|
    f.association :owner, :factory => :user
    f.creator { |pub| pub.owner }
    f.title 'MyString'
  end

  factory :HGVMetaIdentifier do |f|
    f.name { FactoryGirl.generate(:hgv_identifier_string) }
    f.alternate_name { FactoryGirl.generate(:hgv_number) }
  end

  factory :DDBIdentifier do |f|
    f.name { FactoryGirl.generate(:ddb_identifier_string) }
  end

  factory :SyriacaIdentifier do |f|
    f.name { FactoryGirl.generate(:syriaca_identifier_string) }
  end

  factory :SyriacaPersonIdentifier do |f|
    f.name { FactoryGirl.generate(:syriaca_person_identifier_string) }
  end

  factory :SyriacaWorkIdentifier do |f|
    f.name { FactoryGirl.generate(:syriaca_work_identifier_string) }
  end

  factory :community do |f|
    f.name { FactoryGirl.generate(:name) }
    f.friendly_name { FactoryGirl.generate(:name) }
    f.description 'description'
    f.admins Array.new
  end

  factory :master_community do |f|
    f.name { FactoryGirl.generate(:name) }
    f.friendly_name { FactoryGirl.generate(:name) }
    f.description 'description'
    f.admins Array.new
  end

  factory :pass_through_community do |f|
    f.name { FactoryGirl.generate(:name) }
    f.friendly_name { FactoryGirl.generate(:name) }
    f.description 'description'
    f.admins Array.new
  end

  factory :end_user_community do |f|
    f.name { FactoryGirl.generate(:name) }
    f.friendly_name { FactoryGirl.generate(:name) }
    f.description 'description'
    f.admins Array.new
  end

  factory :comment do |f|
    f.comment :comment
    f.user_id :user_id
    f.identifier_id :identifier_id
    f.reason :reason
    f.publication_id :publication_id
    
  end

  factory :EpiCTSIdentifier do |f|
    f.name { FactoryGirl.generate(:epi_cts_identifier_string) }
    f.title :title
  end

  factory :TeiCTSIdentifier do |f|
    f.name { FactoryGirl.generate(:tei_cts_identifier_string) }
    f.title :title
  end

  factory :TreebankCiteIdentifier do |f|
    f.name { FactoryGirl.generate(:treebank_cite_identifier_string) }
    f.title :title
  end
end
