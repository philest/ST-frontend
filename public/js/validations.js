// script to validate the signature, email, and password fields for login
$(document).ready(function () {
  $("#join").on('click', function(event) {
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
    console.log(ValidStatus);
    if (ValidStatus == false) {
        return false;
    }
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