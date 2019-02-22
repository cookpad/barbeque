class Barbeque::RetryConfig < Barbeque::ApplicationRecord
  belongs_to :job_definition

  validates :retry_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :base_delay, numericality: { greater_than: 0.0 }, allow_nil: true
  validates :max_delay, numericality: { greater_than: 0 }, allow_nil: true

  def should_retry?(retries)
    retries < retry_limit
  end

  # This algorithm is based on "Exponential Backoff And Jitter" article
  # https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
  def delay_seconds(retries)
    delay = 2 ** retries * base_delay
    if max_delay
      delay = [delay, max_delay].min
    end
    if jitter
      delay = Kernel.rand(0 .. delay)
    end
    delay
  end
end
