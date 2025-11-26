# frozen_string_literal: true

module Presenters
  # Presents analysis results in a consistent format
  class AnalysisPresenter
    def initialize(analysis_result)
      @result = analysis_result
    end

    def as_json
      {
        assistant: @result[:assistant],
        insights: @result[:insights] || [],
        structured_insights: @result[:structured_insights] || [],
        details: @result[:details] || {},
        timestamp: Time.current.iso8601
      }
    end
  end
end
