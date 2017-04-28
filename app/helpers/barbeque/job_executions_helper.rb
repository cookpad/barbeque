module Barbeque::JobExecutionsHelper
  def status_label(status)
    color =
      case status
      when 'success'
        'success'
      when 'failed'
        'danger'
      when 'retried'
        'warning'
      when 'pending'
        'info'
      when 'error'
        'danger'
      else
        'default'
      end
    content_tag(:span, status.upcase, class: "label label-#{color}")
  end
end
