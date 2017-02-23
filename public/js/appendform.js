// script to append the first modal's field values to the form
$( document ).ready(function() {


  $('button.demo-form-button').click(function(){
      $('form#demo-form').each(function(){
          $(this).submit();
      });
  });


  $('#signup-name-password-mobile').submit(function(event) {
    var username = $('#signup-email-mobile input[name=username]').val();
    var input = $('<input>')
                      .attr('type', 'hidden')
                      .attr('name', 'username')
                      .val(username);
    $('#signup-name-password-mobile').append($(input));

    var formdata = $("form#signup-name-password-mobile").serializeArray();
    var data = {};
    $(formdata).each(function(index, obj){
        data[obj.name] = obj.value;
    });
    console.log(data);
    mixpanel.people.set(data);

    mixpanel.track('freemium registration submitted', {'platform':'mobile'}); 

  });

  $('#signup-name-password').submit(function(event) {
    var username = $('#signup-email input[name=username]').val();
    var input = $('<input>')
                      .attr('type', 'hidden')
                      .attr('name', 'username')
                      .val(username);
    $('#signup-name-password').append($(input));

    var formdata = $("form#signup-name-password").serializeArray();
    var data = {};
    $(formdata).each(function(index, obj){
        data[obj.name] = obj.value;
    });
    console.log(data);
    mixpanel.people.set(data);

    mixpanel.track('freemium registration submitted', {'platform':'desktop'}); 

  });


  $('#main-signup-form').submit(function(event) {
    $('.signup-form').each(function(index) {
      var info = $(this).serializeArray();

      for (var i = 0; i < info.length; i++) {
        var input = $('<input>')
                      .attr('type', 'hidden')
                      .attr('name', info[i]['name'])
                      .val(info[i]['value']);
        $('#main-signup-form').append($(input));
      }


    });
    event.preventDefault();

    $.post('freemium-signup', $('#main-signup-form').serialize())
          .done(function(data) {
            $('#congratsModal').modal('toggle');
          });
  });


  $('#login').on('submit', function(event) {
    // event.preventDefault();
    var teacherinfo = $("#teacher-info").serializeArray();


    for (var i = 0; i < teacherinfo.length; i++) {
      var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', teacherinfo[i]['name'])
                    .val(teacherinfo[i]['value']);
      $('#login').append($(input));
    }

    var role = $('<input>')
                  .attr('type', 'hidden')
                  .attr('name', 'role')
                  .val('teacher');
    $('#login').append($(role));

  });


  $('#admin-login').submit(function(event) {

    var adminInfo = $('#teacher-info').serializeArray();

    for (var i = 0; i < adminInfo.length; i++) {
      var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', adminInfo[i]['name']).val(adminInfo[i]['value']);
      $('#admin-login').append($(input));
    }

    var first_name = $("#admin-login").find("input[name=first_name]").val();
    var last_name = $("#admin-login").find("input[name=last_name]").val();

    var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', 'first_name')
                    .val(first_name);
    $('#admin-login').append($(input));

    var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', 'last_name')
                    .val(first_name);
    $('#admin-login').append($(input));

    var signature = first_name + " " + last_name;
    var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', 'signature')
                    .val(signature);
    $('#admin-login').append($(input));

    var role = $('<input>')
                  .attr('type', 'hidden')
                  .attr('name', 'role')
                  .val('admin');
    $('#admin-login').append($(role));

  });

});



