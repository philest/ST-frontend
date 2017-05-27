$(document).ready(function () {
  
  var timezone = getUserTimezone();

  var tz = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'time_zone')
            .val(timezone);
  $('#invite-teacher-form').append($(tz));
  $('#school-info').append($(tz));

  var os = getMobileOperatingSystem();

  // console.https://s3.amazonaws.com/st-webpage/assets/logo/logo-large.png(os);

  var operating_system = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'mobile_os')
            .val(os);
  $('#register').append($(operating_system));


  // if (os.toLowerCase() == 'android') {
  //   $('#app-link').attr('href', 'https://play.google.com/store/apps/details?id=com.mcesterwahl.storytime');
  // }

  // if (os.toLowerCase() == 'ios') {
  //   $('#page3link').attr('href', '#page5');
  // }

});