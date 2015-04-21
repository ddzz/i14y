class Document
  include Elasticsearch::Persistence::Model
  index_name [Rails.env, Rails.application.engine_name.split('_').first, self.name.tableize].join('-')

  attribute :document_id, String
  validates :document_id, presence: true
  attribute :collection_handle, String
  validates :collection_handle, presence: true
  attribute :path, String
  validates :path, presence: true
  
  attribute :title, String
  attribute :description, String
  attribute :content, String
  
  attribute :language, String
  validates :language, presence: true
  attribute :updated, DateTime
  attribute :created, DateTime
  validates :created, presence: true
  attribute :promote, Boolean

  after_save { Rails.logger.info "Successfully saved #{self.class.name.tableize}: #{self}" }

  gateway do
    def serialize(document)
      document_hash = super
      language = document_hash[:language]
      
      title = document_hash.delete :title
      document_hash.store("title_#{language}", title) if title.present?
      
      description = document_hash.delete :description
      document_hash.store("description_#{language}", description) if description.present?
      
      content = document_hash.delete :content
      document_hash.store("content_#{language}", content) if content.present?
      
      document_hash
    end

    def deserialize(document)
      document_hash = document['_source']
      language = document_hash['language']

      title = document_hash.delete "title_#{language}"
      document_hash[:title] = title if title.present?

      description = document_hash.delete "description_#{language}"
      document_hash[:description] = description if description.present?

      content = document_hash.delete "content_#{language}"
      document_hash[:content] = content if content.present?
      
      klass.new document_hash
      super
    end
  end

end