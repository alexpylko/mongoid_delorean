module Mongoid
  module Delorean
    class Configuration
      attr_accessor :track_history
      attr_accessor :tracker_class_name
      attr_accessor :attr_changes_name

      def initialize
        self.track_history = true
        self.tracker_class_name = 'HistoryTracker'
        self.attr_changes_name = :attr_changes
      end

    end
  end
end