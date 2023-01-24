$(document).ready(function() {
  $('a#verify-request-sms-link').unbind('ajax:success');
  $('a#verify-request-sms-link').bind('ajax:success', function(evt, data, status, xhr) {
    alert(data.message);
  });

  $('a#verify-request-phone-call-link').unbind('ajax:success');
  $('a#verify-request-phone-call-link').bind('ajax:success', function(evt, data, status, xhr) {
    alert(data.message);
  });
});

