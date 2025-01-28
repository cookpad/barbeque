jQuery(function($) {
  if (!document.querySelector('.barbeque_job_definitions_controller')) {
    return;
  }

  $('.use_slack_notification').bind('change', function(event) {
    const enabledField = $('.slack_notification_field');
    if (event.target.value === 'true') {
      enabledField.removeClass('active');
    } else {
      enabledField.addClass('active');
    }
  });

  $('.enable_retry_configuration').bind('change', function(event) {
    const enabledField = $('.retry_configuration_field');
    if (event.target.value === 'true') {
      enabledField.removeClass('active');
    } else {
      enabledField.addClass('active');
    }
  });
});
