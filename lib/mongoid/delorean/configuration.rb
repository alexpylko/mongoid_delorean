module Mongoid
  module Delorean
    class Configuration
      attr_accessor :track_history
      attr_accessor :tracker_class_name
      attr_accessor :attr_changes_name
      attr_accessor :ignored_fields

      def initialize
        self.track_history = true
        self.tracker_class_name = 'HistoryTracker'
        self.attr_changes_name = :attr_changes
        self.ignored_fields = []
      end

    end
  end
end