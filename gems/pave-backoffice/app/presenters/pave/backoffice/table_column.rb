# frozen_string_literal: true

module Pave
  module Backoffice
    TableColumn = Data.define(:key, :header, :cell, :classes) do
      def initialize(key:, header: nil, cell: nil, classes: nil)
        super(
          key: key.to_s,
          header: header || key.to_s.humanize,
          cell: cell,
          classes: classes
        )
      end
    end
  end
end
