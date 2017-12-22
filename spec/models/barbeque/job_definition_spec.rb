require 'rails_helper'

RSpec.describe Barbeque::JobDefinition do
  let(:job_definition) { FactoryBot.create(:job_definition) }

  describe '#execution_stats' do
    let(:to) { Time.zone.now.beginning_of_hour }
    let(:from) { 1.day.ago(to) }

    before do
      # Out of range
      FactoryBot.create(:job_execution, job_definition_id: job_definition.id, created_at: 1.day.ago(from))

      # In range
      FactoryBot.create(:job_execution, job_definition_id: job_definition.id, created_at: from + 1.hour, finished_at: from + 1.hour + 10.seconds)
      FactoryBot.create(:job_execution, job_definition_id: job_definition.id, created_at: from + 1.hour, finished_at: from + 1.hour + 20.seconds)
    end

    it 'returns execution count' do
      stats = job_definition.execution_stats(from, to)
      expect(stats.size).to eq(24)
      expect(stats[0]).to eq(date_hour: from, count: 0, avg_time: 0)
      expect(stats[1]).to match(date_hour: from + 1.hour, count: 2, avg_time: within(1e-6).of(15.0))
    end
  end
end
