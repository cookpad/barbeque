jQuery ($) ->
  return if $('.job_definitions_controller').length == 0

  $('.use_slack_notification').bind('change', (event) ->
    enabledField = $('.slack_notification_field')
    if event.target.value == 'true'
      enabledField.removeClass('active')
    else
      enabledField.addClass('active')
  )
