// script to validate the signature, email, and password fields for login
$(document).ready(function () {
  $('#top-button').click(function(event) {
    console.log('opening modal....');
    $('#myModal').modal('toggle');
  });

  $('#modalSig').on('hidden.bs.modal', function(event) {
    $("body").removeClass("hide-scroll");
    $("body").css("padding-right", '0px');
  });

  $('#adminSig').on('hidden.bs.modal', function(event) {
    $("body").removeClass("hide-scroll");
    $("body").css("padding-right", '0px');
  });

  $('.modal').on('hidden.bs.modal', function(event) {
    $('body').addClass('destroy-padding');
    // $("body").css("padding-right", '0px');
  });

  $('.modal').on('shown.bs.modal', function(event) {
    $('body').removeClass('destroy-padding');
    // $('body').css("padding-right", '15px');
  });


  // $('.modal').on('shown.bs.modal', function(event) {
  //   $('body').removeClass('destroy-padding');
  // });

  $("#join.signature-modal").on('click', function(event) {
    event.preventDefault();
    $('#teacher-info').validate({ // initialize the plugin
        rules: {
            email: {
                required: true,
                email: true
            },
            password: {
                required: true
            }
        }
    }).form();

    var ValidStatus = $("#teacher-info").valid();
    if (ValidStatus == false) {
        return false;
    }

    $('#myModal').modal('toggle');

    // animate a loading gif...

    var teacher_data = $("#teacher-info").serializeArray();
    // var teacher_data = $("#teacher-info").serialize();
    var email = teacher_data[0]['value'];
    var password = teacher_data[1]['value'];

    // then AJAX req existing user....
    $.ajax({
      url: 'user_exists',
      // crossDomain: true,
      type: 'get',
      dataType: 'json',
      data: {
        email: email,
        password: password
      },
      success: function(data) {
        console.log(data);
        if (data.educator == false) {
          // $('body').css("padding-right", '15px');
          $("body").addClass("hide-scroll");
          $('#chooseRoleModal').modal('toggle');
          // show a different modal here....

        } else { 
          console.log(typeof(data));
          var signature = data.educator;
          var role      = data.role;
          console.log(signature);
          console.log(role);
          var input = $('<input>').attr('type', 'hidden').attr('name', 'signature').val(signature);
          $('#teacher-info').append($(input));

          var role = $('<input>').attr('type', 'hidden').attr('name', 'role').val(role);
          $('#teacher-info').append($(role));

          // $("#teacher-info input[name='signature']").val(data);
          $('#teacher-info').submit();
        } 
      },
      error: function(xhr) {
        d = xhr;
        console.log('hey fucker, it\'s an error');
        console.log(xhr);
      }
    });


    // if user exists, just log in


    // if not, ask for signature




    

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


});


// the demo form

  (function($,W,D)
              {
                  var JQUERY4U = {};

                  JQUERY4U.UTIL =
                  {

                      setupFormValidation: function()
                      {
                        // Setup form validation on the .table-input-body-row element
                        $("form#demo-form").each(function () {
                          $(this).validate({

                                // Specify the validation rules
                            rules: {
                            
                                  teacher_email: {
                                    required: true,
                                    email: true
                                  },

                                  demo_first_name: {
                                    required: true
                                  },

                                  demo_last_name: {
                                    required: true
                                  }



                            },

                            messages: {

                                  teacher_email: "Invalid email"                    

                            },

                             submitHandler: function(form) {
                                form.submit();
                            },

            invalidHandler: function(form, validator) {
              var errors = validator.numberOfInvalids();
              if (errors) {
                var message = errors == 1
                  ? 'Please correct the following error:\n'
                  : 'Please correct the following ' + errors + ' errors.\n';
                var errors = "";
                if (validator.errorList.length > 0) {
                    for (x=0;x<validator.errorList.length;x++) {
                        errors += "\n\u25CF " + validator.errorList[x].message;
                    }
                }

                // $('.submit-errors').show()
                // $("html, body").animate({ scrollTop: 0 }, "slow");

                // alert(message + errors);
              }
              validator.focusInvalid();
            }


                        });

                       });

                  }
                }


                  //when the dom has loaded setup form validation rules
                  $(D).ready(function($) {
                      JQUERY4U.UTIL.setupFormValidation();
                      // $('.Button-ready').hide()

                  });



              })(jQuery, window, document);