# frozen_string_literal: true

# Generated by curation_concerns:models:install
class FileSet < ActiveFedora::Base
  property :allow_display_after_expiration, predicate: ::RDF::URI.new('http://fulcrum.org/ns#allowDisplayAfterExpiration'), multiple: false do |index|
    index.as :symbol
  end

  property :allow_download, predicate: ::RDF::URI.new('http://fulcrum.org/ns#allowDownload'), multiple: false do |index|
    index.as :symbol
  end

  property :allow_download_after_expiration, predicate: ::RDF::URI.new('http://fulcrum.org/ns#allowDownloadAfterExpiration'), multiple: false do |index|
    index.as :symbol
  end

  property :allow_hi_res, predicate: ::RDF::URI.new('http://fulcrum.org/ns#allowHiRes'), multiple: false do |index|
    index.as :symbol
  end

  property :alt_text, predicate: ::RDF::Vocab::SCHEMA.accessibilityFeature do |index|
    index.as :stored_searchable
  end

  property :book_needs_handles, predicate: ::RDF::URI.new('http://fulcrum.org/ns#bookNeedsHandles'), multiple: false do |index|
    index.as :symbol
  end

  property :caption, predicate: ::RDF::Vocab::SCHEMA.caption do |index|
    index.as :stored_searchable
  end

  property :content_type, predicate: ::RDF::Vocab::SCHEMA.contentType do |index|
    index.as :stored_searchable, :facetable
  end

  property :copyright_status, predicate: ::RDF::URI.new('http://fulcrum.org/ns#copyrightStatus'), multiple: false do |index|
    index.as :symbol
  end

  property :credit_line, predicate: ::RDF::URI.new('http://fulcrum.org/ns#creditLine'), multiple: false do |index|
    index.as :symbol
  end

  property :display_date, predicate: ::RDF::URI.new('http://fulcrum.org/ns#displayDate') do |index|
    index.as :stored_searchable
  end

  property :exclusive_to_platform, predicate: ::RDF::URI.new('http://fulcrum.org/ns#exclusiveToPlatform'), multiple: false do |index|
    index.as :symbol, :facetable
  end

  property :external_resource, predicate: ::RDF::URI.new('http://fulcrum.org/ns#externalResource'), multiple: false do |index|
    index.as :symbol
  end

  property :ext_url_doi_or_handle, predicate: ::RDF::URI.new('http://fulcrum.org/ns#externalUrlDoiOrHandle'), multiple: false do |index|
    index.as :symbol
  end

  property :keywords, predicate: ::RDF::Vocab::DC.subject do |index|
    index.as :stored_searchable, :facetable
  end

  property :permissions_expiration_date, predicate: ::RDF::URI.new('http://fulcrum.org/ns#permissionsExpirationDate'), multiple: false do |index|
    index.as :symbol
  end
  validates :permissions_expiration_date, format: {
    with: /\A\d\d\d\d-\d\d-\d\d\z/,
    message: "Your permissions expiration date must be in YYYY-MM-DD format",
    allow_blank: true
  }

  property :primary_creator_role, predicate: ::RDF::Vocab::SCHEMA.roleName do |index|
    index.as :stored_searchable, :facetable
  end

  property :redirect_to, predicate: ::RDF::URI.new('http://fulcrum.org/ns#redirectTo'), multiple: false do |index|
    index.as :symbol
  end

  property :rights_granted, predicate: ::RDF::URI.new('http://fulcrum.org/ns#rightsGranted'), multiple: false do |index|
    index.as :symbol
  end

  property :rights_granted_creative_commons, predicate: ::RDF::URI.new('http://fulcrum.org/ns#rightsGrantedCreativeCommons'), multiple: false do |index|
    index.as :symbol
  end

  property :section_title, predicate: ::RDF::Vocab::DC.relation do |index|
    index.as :stored_searchable, :facetable
  end

  property :sort_date, predicate: ::RDF::Vocab::DC.date, multiple: false do |index|
    index.as :stored_searchable, :facetable
  end
  validates :sort_date, format: { with: /\A\d\d\d\d-\d\d-\d\d\z/, message: "Your sort date must be in YYYY-MM-DD format", allow_blank: true }

  property :transcript, predicate: ::RDF::URI.new('http://fulcrum.org/ns#transcript'), multiple: false do |index|
    index.as :stored_searchable
  end

  property :translation, predicate: ::RDF::URI.new('http://fulcrum.org/ns#translation') do |index|
    index.as :stored_searchable
  end

  property :use_crossref_xml, predicate: ::RDF::URI.new('http://fulcrum.org/ns#useCrossrefXml'), multiple: false do |index|
    index.as :symbol
  end

  include GlobalID::Identification
  include HeliotropeUniversalMetadata
  include StoresCreatorNameSeparately
  include ::Hyrax::FileSetBehavior
  include ::Hyrax::BasicMetadata

  self.indexer = ::FileSetIndexer
  # Cast to a SolrDocument by querying from Solr
  # Hyrax Heliotrope override: cast to an actual presenter, not just a solr_doc
  def to_presenter
    ::Hyrax::FileSetPresenter.new(CatalogController.new.fetch(id).last, nil)
  end
end
