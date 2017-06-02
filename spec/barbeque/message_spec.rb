require 'barbeque/worker'
require 'rails_helper'

describe Barbeque::Message::Base do
  let(:application) { 'cookpad' }
  let(:job)         { 'NotifyAuthor' }
  let(:job_queue) { create(:job_queue) }
  let(:message_id)  { SecureRandom.uuid }
  let(:message_body) { { "foo" => "bar" } }
  let(:receipt_handle) do
    "MbZj6wDWli+JvwwJaBV+3dcjk2YW2vA3+STFFljTM8tJJg6HRG6PYSasuWXPJB+Cw
    Lj1FjgXUv1uSj1gUPAWV66FU/WeR4mq2OKpEGYWbnLmpRCJVAyeMjeU5ZBdtcQ+QE
    auMZc8ZRv37sIW2iJKq3M9MFx1YvV11A2x/KSbkJ0="
  end
  let(:raw_sqs_message) do
    {
      'Type'        => 'JobExecution',
      'Application' => application,
      'Job'         => job,
      'Message'     => message_body,
    }.to_json
  end
  let(:sqs_message) do
    double('Aws::SQS::Types::Message', body: raw_sqs_message, message_id: message_id, receipt_handle: receipt_handle)
  end

  context 'given JobExecution' do
    it 'parses a SQS message' do
      message = Barbeque::Message.parse(sqs_message)
      expect(message.application).to eq(application)
      expect(message.job).to eq(job)
      expect(message.id).to eq(message_id)
      expect(message.receipt_handle).to eq(receipt_handle)
      expect(message.body).to eq(message_body)
    end

    context 'given JSON formatted string as message_body' do
      let(:message_body) { { "foo" => "bar" }.to_json }
      it 'parses a SQS message' do
        message = Barbeque::Message.parse(sqs_message)
        expect(message.application).to eq(application)
        expect(message.job).to eq(job)
        expect(message.id).to eq(message_id)
        expect(message.receipt_handle).to eq(receipt_handle)
        expect(message.body).to eq({ "foo" => "bar" })
      end
    end
  end

  context 'given JobRetry' do
    let(:retry_message_id) { SecureRandom.uuid }
    let(:raw_sqs_message) do
      {
        'Type'           => 'JobRetry',
        'RetryMessageId' => retry_message_id,
      }.to_json
    end

    it 'parses a SQS message' do
      message = Barbeque::Message.parse(sqs_message)
      expect(message.id).to eq(message_id)
      expect(message.receipt_handle).to eq(receipt_handle)
      expect(message.retry_message_id).to eq(retry_message_id)
    end
  end

  context 'given Notification' do
    let(:sns_subscription) { create(:sns_subscription, job_queue: job_queue) }
    let(:raw_sqs_message) do
      {
        'Type'     => 'Notification',
        'TopicArn' => sns_subscription.topic_arn,
        'Message'  => message_body,
      }.to_json
    end

    it 'parses a SQS message' do
      message = Barbeque::Message.parse(sqs_message)
      expect(message).to be_a(Barbeque::Message::Notification)
      expect(message.id).to eq(message_id)
      expect(message.receipt_handle).to eq(receipt_handle)
      expect(message.body).to eq(message_body)
      expect(message.topic_arn).to eq(sns_subscription.topic_arn)
    end

    context 'given JSON formatted string as message_body' do
      let(:message_body) { { "foo" => "bar" }.to_json }
      it 'parses a SQS message' do
        message = Barbeque::Message.parse(sqs_message)
        expect(message).to be_a(Barbeque::Message::Notification)
        expect(message.id).to eq(message_id)
        expect(message.receipt_handle).to eq(receipt_handle)
        expect(message.body).to eq({ "foo" => "bar" })
        expect(message.topic_arn).to eq(sns_subscription.topic_arn)
      end
    end
  end

  describe 'valid?' do
    subject { Barbeque::Message.parse(sqs_message).valid? }

    context 'when SQS message is a valid JSON' do
      it { is_expected.to eq(true) }
    end

    context 'when SQS message is not valid as JSON' do
      let(:raw_sqs_message) { '{' }

      it { is_expected.to eq(false) }
    end

    context 'when Type of SQS message is invalid' do
      let(:raw_sqs_message) do
        { 'Type' => 'Undefined' }.to_json
      end

      it { is_expected.to eq(false) }
    end
  end
end
