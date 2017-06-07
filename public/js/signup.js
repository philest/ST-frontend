/**
 * JS for the purple-modals freemium signup page.
 */

$(document).ready(function () {
  
  var timezone = getUserTimezone();

  var tz = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'time_zone')
            .val(timezone);
  $('#invite-teacher-form').append($(tz));
  $('#school-info').append($(tz));

  var os = getMobileOperatingSystem();

  var operating_system = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'mobile_os')
            .val(os);
  $('#register').append($(operating_system));


});