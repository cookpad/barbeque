#!/usr/bin/env ruby
require 'aws-sdk-s3'
require 'json'
require 'logger'

bucket = ENV.fetch('BARBEQUE_S3_BUCKET_NAME')
num_workers = Integer(ENV.fetch('BARBEQUE_MIGRATOR_NUM_WORKERS', 16))

queue = Thread::SizedQueue.new(1000)
s3_client = Aws::S3::Client.new
logger = Logger.new($stdout)

STOP = Object.new

producer = Thread.start do
  Thread.current.name = 'producer'
  begin
    s3_client.list_objects_v2(
      bucket: bucket,
      delimiter: '/',
      max_keys: 1000,
    ).each do |page|
      page.common_prefixes.each do |app_prefix|
        s3_client.list_objects_v2(
          bucket: bucket,
          delimiter: '/',
          max_keys: 1000,
          prefix: app_prefix.prefix,
        ).each do |page|
          page.common_prefixes.each do |job_prefix|
            logger.info "Listing #{job_prefix.prefix}"
            s3_client.list_objects_v2(
              bucket: bucket,
              delimiter: '/',
              max_keys: 1000,
              prefix: job_prefix.prefix,
            ).each do |page|
              page.contents.each do |content|
                queue.push(content.key)
              end
            end
          end
        end
      end
    end
  ensure
    logger.info('Finish listing')
    num_workers.times do
      queue.push(STOP)
    end
  end
end

consumers = num_workers.times.map do |i|
  Thread.start do
    Thread.current.name = "consumer-#{i}"
    begin
      loop do
        key = queue.pop
        if key.equal?(STOP)
          break
        end
        log = JSON.parse(s3_client.get_object(bucket: bucket, key: key).body.read)
        puts "#{key}: #{log}"
        if log.key?('message')
          s3_client.put_object(bucket: bucket, key: "#{key}/message.json", body: log.fetch('message'))
        end
        s3_client.put_object(bucket: bucket, key: "#{key}/stdout.txt", body: log.fetch('stdout'))
        s3_client.put_object(bucket: bucket, key: "#{key}/stderr.txt", body: log.fetch('stderr'))
        s3_client.delete_object(bucket: bucket, key: key)
      end
    rescue => e
      logger.error("consumer-#{i} raised error")
      logger.error(e)
      raise e
    end
  end
end

def safe_join(thread)
  thread.join
rescue => e
  $stderr.puts "#{thread.name} raised error: #{e.class}: #{e.message}"
  $stderr.puts e.backtrace
end

safe_join(producer)
consumers.each { |c| safe_join(c) }
