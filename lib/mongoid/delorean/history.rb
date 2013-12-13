module Mongoid::Delorean
  module History
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      include Mongoid::Timestamps

      field :original_class, type: String
      field :original_class_id, type: String
      field :version, type: Integer, default: 0
      field :altered_attributes, type: Hash, default: {}
      field :full_attributes, type: Hash, default: {}
      field :action, type: String, default: ''

      Mongoid::Delorean.config.tracker_class_name = name.tableize.singularize.to_sym
    end
  end
end