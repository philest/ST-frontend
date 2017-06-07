/**
 * JS for all homepage modals, forms, and validations.
 */

 $( document ).ready(function() {

  function transitionToNamePassword() {
    $('#signup-email-mobile').validate({ // initialize the plugin
        rules: {
            usernameDisplay: {
                validateContactId: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-email-mobile").valid();
    if (ValidStatus == false) {
        return false;
        mixpanel.track('invalid username given', {"platform": "mobile"});
    } else {
      var username = $('form#signup-email-mobile input[name=usernameDisplay]').val();
      if (validatePhone(username)) {
        console.log(validatePhone(username));
        var phone = username; 

        phone = phone.replace(/[\(\)\.\-\ ]/g, '');


        $('form#signup-email-mobile input[name=username]').val(phone);

      }


      $('#signup-email-mobile').slideUp();
      $('.signup-name-password-mobile').slideDown();
      mixpanel.track('email given', {"platform": "mobile"});
    }
  }


  $('form#signup-email-mobile input[name=usernameDisplay]').change(function(event) {
    var usernameDisplay = $('form#signup-email-mobile input[name=usernameDisplay]').val();
    $('form#signup-email-mobile input[name=username]').val(usernameDisplay);
  });

  $('#login').validate({ // initialize the plugin
     rules: {
         email: {
             required: true,
             email: true
         },
         password: {
             required: true
         },
         signature: {
           required: true
         }
     }
  });


  $('#signup-email-button').click(function(event) {
    event.preventDefault();

    $('#signup-email').validate({ // initialize the plugin
        rules: {
            usernameDisplay: {
                validateContactId: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-email").valid();
    if (ValidStatus == false) {
        mixpanel.track('invalid email given', {'platform':'desktop'});
        return false;
    }

    var username = $('form#signup-email input[name=usernameDisplay]').val();
    var usernameDisplay = username;
    if (validatePhone(username)) {
      console.log(validatePhone(username));
      var phone = username; 

      phone = phone.replace(/[\(\)\.\-\ ]/g, '');


      $('form#signup-email input[name=username]').val(phone);

      username = phone;

    }

    $.ajax({
      url: 'auth/user_exists',
      type: 'get',
      data: {
        username: username
      },
      success: function(data) {
        // a user already exists with this username/phone, so log that user in
        $('#teacher-info input[name=usernameDisplay]').val(usernameDisplay);
        $('#teacher-info input[name=username]').val(username);
        $('#myModal').modal('toggle'); 
      },
      error: function (xhr, ajaxOptions, thrownError){
          if(xhr.status==404) {
            // a user doesn't exist with this phone/username
            $('body').addClass('modalTransition');
            $('#signupNamePassword').modal('toggle');
              // alert(thrownError);
          }
      }

    });

    mixpanel.track('email given', {'platform':'desktop'});

    // $("body").addClass("modal-open");
  });




  $('#signup-name-password-button-mobile').click(function(event) {
    event.preventDefault();
    $('#signup-name-password-mobile').validate({ // initialize the plugin
        rules: {
            first_name: {
                required: true
            },
            last_name: {
              required: true
            },
            password: {
                required: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-name-password-mobile").valid();
    if (ValidStatus == false) {
        mixpanel.track('invalid name-password given', {'platform':'mobile'});
        return false;
    }

     // we want to POST this, clear the first-signup-form, the move on to the next modal
    $('#signup-name-password-mobile').submit();

  });



  $('#signup-name-password-button').click(function(event) {
    event.preventDefault();
    $('#signup-name-password').validate({ // initialize the plugin
        rules: {
            first_name: {
                required: true
            },
            last_name: {
              required: true
            },
            password: {
                required: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-name-password").valid();
    if (ValidStatus == false) {
        mixpanel.track('invalid name-password given', {'platform':'desktop'});
        return false;
    }
    // we want to POST this, clear the first-signup-form, the move on to the next modal
    $('#signup-name-password').submit();

    // $('body').addClass('modalTransition');
    // move on to next modal
    // $('#signupSchoolRole').modal('toggle');
    // $("body").addClass("modal-open");
  });


  $('#signup-signature-button').click(function(event) {
    event.preventDefault();
    $('#signup-signature').validate({ // initialize the plugin
        rules: {
            signature: {
                required: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-signature").valid();
    if (ValidStatus == false) {
        return false;
    }
    $('body').addClass('modalTransition');
    $('#schoolInfo').modal('toggle');
    // $("body").addClass("modal-open");
  });



  $('#school-info-button').click(function(event) {
    // gather all form fields + submit
    event.preventDefault();
    $('#school-info').validate({ // initialize the plugin
        rules: {
            school_name:  {required:true},
            school_city:  {required:true},
            school_state: {required:true}
        }
    }).form();

    var ValidStatus = $("#school-info").valid();
    if (ValidStatus == false) {
        return false;
    }

    // otherwise, gather everything from the forms!
    $('body').addClass('modalTransition');
    $('#main-signup-form').submit();
  });


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



  // this is also used in the get-the-app page
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


  // might belong to a different page...
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


  
  // might also belong to a different page...
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


  $('.modal').on('hidden.bs.modal', function(event) {
     // $('body').addClass('destroy-padding');
     // $('body').removeClass('hide-scroll');
     $("body").css("padding-right", '0px');


    // if body has the class modal transition,
    //  don't remove my-modal-open
    //  remove modalTransition
    // else
    //  remove my-modal-open
    if ($('body').hasClass("modalTransition")) {
      $('body').removeClass("modalTransition");
    } else {
      $("body").removeClass("my-modal-open");
    }

  });

  $('.modal').on('shown.bs.modal', function(event) {
    // $('body').removeClass('destroy-padding');
    // $('body').addClass('hide-scroll');
    $('body').css("padding-right", '0px');
    $("body").addClass("my-modal-open");
  });
  

  // 
  // 
  // YUP, SIGNUP FLOW, RIGHT ABOVE ME!!!!!

  $('.logger-in.signup-button#top-button').click(function(event) {
    console.log('clicked the top button');
    $('#myModal').modal('toggle');
  });



}); // end (document).ready