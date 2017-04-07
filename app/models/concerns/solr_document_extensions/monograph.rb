module SolrDocumentExtensions::Monograph
  extend ActiveSupport::Concern

  def buy_url
    Array(self[Solrizer.solr_name('buy_url', :symbol)])
  end

  # copyright_holder is also in FileSet

  # date_published is also in FileSet

  def creator_family_name
    Array(self[Solrizer.solr_name('creator_family_name', :stored_searchable)]).first
  end

  def creator_full_name
    Array(self[Solrizer.solr_name('creator_full_name', :stored_searchable)]).first
  end

  def creator_given_name
    Array(self[Solrizer.solr_name('creator_given_name', :stored_searchable)]).first
  end

  def editor
    Array(self[Solrizer.solr_name('editor', :stored_searchable)]).first
  end

  def isbn
    Array(self[Solrizer.solr_name('isbn', :stored_searchable)])
  end

  def isbn_ebook
    Array(self[Solrizer.solr_name('isbn_ebook', :stored_searchable)])
  end

  def isbn_paper
    Array(self[Solrizer.solr_name('isbn_paper', :stored_searchable)])
  end

  def press
    Array(self[Solrizer.solr_name('press', :stored_searchable)]).first
  end

  def sub_brand
    Array(self[Solrizer.solr_name('sub_brand', :symbol)])
  end
end