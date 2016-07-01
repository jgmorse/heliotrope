module Heliotrope::Forms
  class FileSetEditForm < CurationConcerns::Forms::FileSetEditForm
    self.terms += [:resource_type, :caption, :alt_text, :copyright_holder,
                   :description, :content_type, :date_created, :keywords,
                   :language, :identifier, :relation, :external_resource,
                   :persistent_id, :creator_family_name, :creator_given_name,
                   :sort_date]
  end
end