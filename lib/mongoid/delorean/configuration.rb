module Mongoid
  module Delorean
    class Configuration
      attr_accessor :track_history
      attr_accessor :tracker_class_name

      def initialize
        self.track_history = true
        self.tracker_class_name = 'HistoryTracker'
      end

    end
  end
end