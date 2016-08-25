require 'net/http'
require 'json'
require 'uri'

class SlackClient
  def initialize(channel)
    @channel = channel
  end

  def notify_success(message)
    post_slack(
      attachments: [{
        text: message,
        color: 'good',
        mrkdwn_in: ['text'],
      }],
    )
  end

  def notify_failure(message)
    post_slack(
      attachments: [{
        text: message,
        color: 'danger',
        mrkdwn_in: ['text'],
      }],
    )
  end

  private

  def post_slack(payload)
    Net::HTTP.post_form(
      endpoint_uri,
      payload: default_payload.merge(payload).to_json,
    )
  end

  def default_payload
    { link_names: 1, channel: @channel }
  end

  def endpoint_uri
    @endpoint_uri ||= URI.parse(ENV['SLACK_WEBHOOK_URL'])
  end
end
