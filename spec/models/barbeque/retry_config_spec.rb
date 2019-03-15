require 'rails_helper'

RSpec.describe Barbeque::RetryConfig do
  let(:job_definition) { FactoryBot.create(:job_definition) }
  let(:retry_config) { FactoryBot.create(:retry_config, job_definition: job_definition) }

  describe '#delay_seconds' do
    it 'returns delay seconds with jitter by default' do
      expect(retry_config.delay_seconds(0)).to be_between(0, 15)
      expect(retry_config.delay_seconds(1)).to be_between(0, 30)
      expect(retry_config.delay_seconds(2)).to be_between(0, 60)
    end

    context 'without jitter' do
      before do
        retry_config.update!(jitter: false)
      end

      it 'returns delay seconds without randomness' do
        expect(retry_config.delay_seconds(0)).to be_within(0.1).of(15)
        expect(retry_config.delay_seconds(1)).to be_within(0.1).of(30)
        expect(retry_config.delay_seconds(2)).to be_within(0.1).of(60)
      end
    end

    context 'with max_delay' do
      before do
        retry_config.update!(max_delay: 20)
      end

      it 'returns capped delay seconds' do
        expect(retry_config.delay_seconds(0)).to be_between(0, 15)
        expect(retry_config.delay_seconds(1)).to be_between(0, 20)
        expect(retry_config.delay_seconds(2)).to be_between(0, 20)
      end
    end
  end
end
