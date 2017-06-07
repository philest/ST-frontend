/**
 * JS for the user registration page. 
 */

$(document).ready(function () {

  var timezone = getUserTimezone();

  var tz = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'time_zone')
            .val(timezone);
  $('#register').append($(tz));


  var os = getMobileOperatingSystem();

  // console.log(os);

  var operating_system = $('<input>')
            .attr('type', 'hidden')
            .attr('name', 'mobile_os')
            .val(os);
  $('#register').append($(operating_system));


  if (os.toLowerCase() == 'android') {
    $('#app-link').attr('href', 'https://play.google.com/store/apps/details?id=com.mcesterwahl.storytime');
  }

  if (os.toLowerCase() == 'ios') {
    $('#app-link').attr('href', 'https://itunes.apple.com/us/app/storytime-literacy/id1201886605?mt=8');
    // $('#page3link').attr('href', '#page5');
  }

   // Trigger on first sign up button tap
   function IdentifyUser() { 
       // TODO: phone_num = grab the user's phone number (string)
       // TDOO: full_name = grab the user's full name
      // TODO: teacher_name = grab the teacher name
       var username = $('#register input[name=username]').val();
       console.log(username);

       var full_name = $('#register input[name=name]').val();
       console.log(full_name);

       var teacher_name = $('#hidden-inputs input[name=teacher_sig]').val();
       console.log(teacher_name);

       mixpanel.people.append({
         "full_name": full_name,
         "username": username
         // "teacher_name": teacher_name
       });

   }


   // Trigger when the first signup button is Tapped. 
   function SignupButtonClicked() {
     console.log('signup button clicked');
     mixpanel.track("Signup Button Clicked");
   }

   // Trigger when the Password button is tapped. 
   function PasswordButtonClicked() {
     console.log('password button clicked');
     mixpanel.track("Password Button Clicked");
   }

   // Trigger when the app download prompt is tapped.
   function AppPromptClicked() {
     console.log('app prompt clicked');
     mixpanel.track("App Download Prompt Clicked");
   }



  $('#app-link').click(function(event) {
     AppPromptClicked();
  });

  $('#page3link').click(function(event) {
     // get name/email
     var signupInfo = $("#register").serializeArray();

     for (var i = 0; i < signupInfo.length; i++) {
       var input = $('<input>')
                     .attr('type', 'hidden')
                     .attr('name', signupInfo[i]['name'])
                     .val(signupInfo[i]['value']);
       $('#password-form').append($(input));
     }

     // get role
     // already gotten from earlier script
     // submit password form using AJAX request
     console.log($('#password-form').serialize());
     $.post('/register/user-finish-registration', $('#password-form').serialize());

     PasswordButtonClicked();

  });


   $(document).on('click', '#page1link',function(event){


     $('#register').validate({
       rules: {
         usernameDisplay: {
           required: true,
           validateContactId: true 
         }
       }
     });

     var ValidStatus = $("#register").valid();


     // console.log(ValidStatus);
     if (ValidStatus == false) {
         event.preventDefault();
         event.stopPropagation();
         return false;
     }

     var username = $('form#register input[name=usernameDisplay]').val();
     if (validatePhone(username)) {
       console.log(validatePhone(username));
       var phone = username; 

       phone = phone.replace(/[\(\)\.\-\ ]/g, '');


       $('form#register input[name=username]').val(phone);

     }

     // get name/email
     console.log($('#register').serialize());
     $.post('/register/user-start-registration', $('#register').serialize());

     // first identify user
     IdentifyUser();
     // then do other stuff
     SignupButtonClicked();


   });

   $(document).on('click', '#page3link',function(event){

     var ValidStatus = $("#password-form").valid();
     // console.log(ValidStatus);
     if (ValidStatus == false) {
         event.preventDefault();
         event.stopPropagation();
         return false;
     }
   });
   
   function SignupPageVisited() {
       var teacher_name = $('#hidden-inputs input[name=teacher_sig]').val();
       var class_code = $('#hidden-inputs input[name=class_code]').val();
       var teacher_id = $('#hidden-inputs input[name=teacher_id]').val();
       var locale = $('#hidden-inputs input[name=locale]').val();
       mixpanel.people.append({
         "teacher_name": teacher_name,
         "class_code": class_code,
         "teacher_id": teacher_id,
         "locale": locale
       });
       mixpanel.track("First Signup Page Visited");
   }

   $(document).ready(function() {
     SignupPageVisited();

     // console.log('distinct_id = ' +distinct_id);
   });

});