$(document).ready(function () {
  // THIS IS WHERE I'LL DO THE SIGNUP FLOW
  // 

  jQuery.validator.addMethod("validateEmailPhone", function(value, element) {
    return ValidateEmail(value) || validatePhone(value);
  }, "Invalid email or phone number.");


  function ValidateEmail(mail)   
  {  
   if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(mail))  
    {  
      return (true)  
    }  

    return (false)  
  }  

  function validatePhone(phone) {
      var error = "";
      var stripped = phone.replace(/[\(\)\.\-\ ]/g, '');

     if (stripped == "") {
          error = "You didn't enter a phone number.";
          return false;
      } else if (isNaN(parseInt(stripped))) {
          phone = "";
          error = "The phone number contains illegal characters.";
          return false;

      } else if (!(stripped.length == 10 || stripped.length == 11)) {
          phone = "";
          error = "The phone number is the wrong length. Make sure you included an area code.\n";
          return false;
      } else {
        return true;
      }
  }

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

  $('#signup-email-button').click(function(event) {
    event.preventDefault();

    $('#signup-email').validate({ // initialize the plugin
        rules: {
            email: {
                validateEmailPhone: true
            }
        }
    }).form();

    var ValidStatus = $("#signup-email").valid();
    if (ValidStatus == false) {
        mixpanel.track('invalid email given', {'platform':'desktop'});
        return false;
    }

    // now check to see if anyone exists by that name/email
    var email = $('#signup-email input[name=email]').val();

    $.ajax({
      url: '/user_exists',
      type: 'get',
      data: {
        email: email
      },
      success: function(data) {
        // a user already exists with this email/phone, so log that user in
        $('#teacher-info input[name=email]').val(email);
        $('#myModal').modal('toggle'); 
      },
      error: function (xhr, ajaxOptions, thrownError){
          if(xhr.status==404) {
            // a user doesn't exist with this phone/email
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

  $('#signup-school-role-button').click(function(event) {
    $('body').addClass('modalTransition');
    $('#signupSignature').modal('toggle');
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

  // 
  // 
  // YUP, SIGNUP FLOW, RIGHT ABOVE ME!!!!!

  $('.logger-in.signup-button#top-button').click(function(event) {
    console.log('clicked the top button');
    $('#myModal').modal('toggle');
  });

  // $("#join.signature-modal").on('click', function(event) {
  //   event.preventDefault();
  //   $('#teacher-info').validate({ // initialize the plugin
  //       rules: {
  //           email: {
  //               required: true,
  //               email: true
  //           },
  //           password: {
  //               required: true
  //           }
  //       }
  //   }).form();

  //   var ValidStatus = $("#teacher-info").valid();
  //   if (ValidStatus == false) {
  //       return false;
  //   }
  //   $('#myModal').modal('toggle');
  //   // animate a loading gif...
  //   var teacher_data = $("#teacher-info").serializeArray();
  //   // var teacher_data = $("#teacher-info").serialize();
  //   var email = teacher_data[0]['value'];
  //   var password = teacher_data[1]['value'];

  //   // then AJAX req existing user....
  //   $.ajax({
  //     url: 'user_exists',
  //     // crossDomain: true,
  //     type: 'get',
  //     dataType: 'json',
  //     data: {
  //       email: email,
  //       password: password
  //     },
  //     success: function(data) {
  //       if (data.educator == 'false') {
  //         // $('body').css("padding-right", '15px');
  //         // $("body").addClass("hide-scroll");
  //         $('body').addClass('modalTransition');
  //         $('#chooseRoleModal').modal('toggle');
  //         // show a different modal here....

  //       } else { 
  //         var signature = data.educator;
  //         var role      = data.role;
  //         var input = $('<input>').attr('type', 'hidden').attr('name', 'signature').val(signature);
  //         $('#teacher-info').append($(input));

  //         var role = $('<input>').attr('type', 'hidden').attr('name', 'role').val(role);
  //         $('#teacher-info').append($(role));

  //         // $("#teacher-info input[name='signature']").val(data);
  //         $('#teacher-info').submit();
  //       } 
  //     },
  //     error: function(xhr) {
  //       d = xhr;
  //       console.log('error');
  //       console.log(xhr);
  //     }
  //   }); // $.ajax()

  // }); // join signature modal

}); // on document ready