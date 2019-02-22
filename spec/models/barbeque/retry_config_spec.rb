require 'rails_helper'

RSpec.describe Barbeque::RetryConfig do
  let(:job_definition) { FactoryBot.create(:job_definition) }
  let(:retry_config) { FactoryBot.create(:retry_config, job_definition: job_definition) }

  describe '#delay_seconds' do
    it 'returns delay seconds with jitter by default' do
      expect(retry_config.delay_seconds(0)).to be_between(0, 0.3)
      expect(retry_config.delay_seconds(1)).to be_between(0, 0.6)
      expect(retry_config.delay_seconds(2)).to be_between(0, 1.2)
    end

    context 'without jitter' do
      before do
        retry_config.update!(jitter: false)
      end

      it 'returns delay seconds without randomness' do
        expect(retry_config.delay_seconds(0)).to be_within(0.1).of(0.3)
        expect(retry_config.delay_seconds(1)).to be_within(0.1).of(0.6)
        expect(retry_config.delay_seconds(2)).to be_within(0.1).of(1.2)
      end
    end

    context 'with max_delay' do
      before do
        retry_config.update!(max_delay: 0.5)
      end

      it 'returns capped delay seconds' do
        expect(retry_config.delay_seconds(0)).to be_between(0, 0.3)
        expect(retry_config.delay_seconds(1)).to be_between(0, 0.5)
        expect(retry_config.delay_seconds(2)).to be_between(0, 0.5)
      end
    end
  end
end
