require 'uri'

module Barbeque
  class HakoS3Client
    # @param [String] oneshot_notification_prefix S3 location for oneshot notification
    def initialize(oneshot_notification_prefix)
      uri = URI.parse(oneshot_notification_prefix)
      @s3_bucket = uri.host
      @s3_prefix = uri.path.sub(%r{\A/}, '')
      @s3_region = URI.decode_www_form(uri.query || '').to_h['region']
    end

    # @param [Barbeque::EcsHakoTask] hako_task
    # @return [String]
    def s3_key_for_stopped_result(hako_task)
      "#{@s3_prefix}/#{hako_task.task_arn}/stopped.json"
    end

    # @return [Aws::S3::Client]
    def s3_client
      @s3_client ||= Aws::S3::Client.new(region: @s3_region, http_read_timeout: 5)
    end

    # @param [Barbeque::EcsHakoTask] hako_task
    # @return [Aws::ECS::Types::Task, nil]
    def get_stopped_result(hako_task)
      object = s3_client.get_object(bucket: @s3_bucket, key: s3_key_for_stopped_result(hako_task))
      result = JSON.parse(object.body.read)
      detail = result.fetch('detail')
      Aws::Json::Parser.new(Aws::ECS::Client.api.operation('describe_tasks').output.shape.member(:tasks).shape.member).parse(JSON.dump(detail))
    rescue Aws::S3::Errors::NoSuchKey
      nil
    end
  end
end
