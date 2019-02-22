jQuery ($) ->
  return if !document.querySelector('.barbeque_job_definitions_controller')

  $('.use_slack_notification').bind('change', (event) ->
    enabledField = $('.slack_notification_field')
    if event.target.value == 'true'
      enabledField.removeClass('active')
    else
      enabledField.addClass('active')
  )

  $('.enable_retry_configuration').bind('change', (event) ->
    enabledField = $('.retry_configuration_field')
    if event.target.value == 'true'
      enabledField.removeClass('active')
    else
      enabledField.addClass('active')
  )
