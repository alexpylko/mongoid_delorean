module Mongoid
  module Delorean
    module Trackable

      def self.included(klass)
        super
        klass.field :version, type: Integer, default: 0
        klass.field Mongoid::Delorean.config.attr_changes_name, type: Array, default: []

        klass.before_create :save_version_before_create
        klass.before_update :save_version_before_update
        klass.before_destroy :save_version_before_destroy
        klass.after_save :after_save_version
        klass.after_destroy :after_destroy_version
        klass.send(:include, Mongoid::Delorean::Trackable::CommonInstanceMethods)
      end

      def versions
        Mongoid::Delorean.tracker_class.where(original_class: self.class.name, original_class_id: self.id)
      end

      def save_version_before_create
        save_version('create')
      end

      def save_version_before_update
        save_version('update')
      end

      def save_version_before_destroy
        save_version('destroy')
      end

      def save_version(action = 'update')
        if self.track_history?
          last_version = self.versions.last
          _version = last_version ? last_version.version + 1 : 1

          _attributes = self.attributes_with_relations
          _attributes.merge!("version" => _version)
          _changes = self.changes_with_relations.dup
          _changes.merge!("version" => [self.version_was, _version])
          _changes.delete(Mongoid::Delorean.config.attr_changes_name.to_s)

          tracker = Mongoid::Delorean.tracker_class.create(original_class: self.class.name, original_class_id: self.id, version: _version, altered_attributes: _changes, full_attributes: _attributes, action: action)
          self.version = _version

          @__track_changes = false

          if action == 'update'
            _changes.delete("version")
            attr_changes = self[Mongoid::Delorean.config.attr_changes_name] || []
            attr_changes << {
              version: _version,
              changes: _changes,
              created_at: tracker.created_at,
            }
            self[Mongoid::Delorean.config.attr_changes_name] = attr_changes
          end
        end

        true
      end

      def after_save_version
        @__track_changes = Mongoid::Delorean.config.track_history
      end

      def after_destroy_version
        @__track_changes = Mongoid::Delorean.config.track_history
      end

      def track_history?
        @__track_changes.nil? ? Mongoid::Delorean.config.track_history : @__track_changes
      end

      def without_history_tracking
        previous_track_change = @__track_changes
        @__track_changes = false
        yield
        @__track_changes = previous_track_change
      end

      def revert!(version = (self.version - 1))
        old_version = self.versions.where(version: version).first
        if old_version
          old_version.full_attributes.each do |key, value|
            self.write_attribute(key, value)
          end
          self.save!
        end
      end

      module CommonEmbeddedMethods

        def save_version
          if self._parent.respond_to?(:save_version)
            if self._parent.respond_to?(:track_history?)
              if self._parent.track_history?
                self._parent.save_version
                self._parent.without_history_tracking do
                  self._parent.save!(validate: false)
                end
              end
            else
              self._parent.save_version
            end
          end

          true
        end

      end

      module CommonInstanceMethods

        def changes_with_relations
          _changes = self.changes.dup

          %w{version updated_at created_at}.each do |col|
            _changes.delete(col)
            _changes.delete(col.to_sym)
          end

          relation_changes = {}
          self.embedded_relations.each do |name, details|
            relation = self.send(name)
            relation_changes[name] = []
            if details.relation == Mongoid::Relations::Embedded::One
              relation_changes[name] = relation.changes_with_relations if relation
            else
              r_changes = relation.map {|o| o.changes_with_relations}
              relation_changes[name] << r_changes unless r_changes.empty?
              relation_changes[name].flatten!
            end
            relation_changes.delete(name) if relation_changes[name].empty?
          end

          _changes.merge!(relation_changes)
          return _changes
        end

        def attributes_with_relations
          _attributes = self.attributes.dup

          relation_attrs = {}
          self.embedded_relations.each do |name, details|
            relation = self.send(name)
            if details.relation == Mongoid::Relations::Embedded::One
              relation_attrs[name] = relation.attributes_with_relations if relation
            else
              relation_attrs[name] = []
              r_attrs = relation.map {|o| o.attributes_with_relations}
              relation_attrs[name] << r_attrs unless r_attrs.empty?
              r_changes = relation.map {|o| o.changes}
              relation_attrs[name].flatten!
            end
          end
          _attributes.merge!(relation_attrs)
          return _attributes
        end

      end

    end
  end
end
