$(document).ready(function () {
  $('.the-whole-user-thing').first().css('display', 'block');
  $('.user-info').slice(1).addClass('user-info-first-box');
  $('.user-info:first-child').addClass('user-spotlight first-row');
});

$(document).ready(function() {
  var isSafari = Object.prototype.toString.call(window.HTMLElement).indexOf('Constructor') > 0 || (function (p) { return p.toString() === "[object SafariRemoteNotification]"; })(!window['safari'] || safari.pushNotification);

  if (isSafari) {
    // $('.table-responsive').css('direction', 'ltr');
    document.styleSheets[0].addRule('.table-responsive::-webkit-scrollbar','width: 0');
    $('th.teacher-name').css('padding-left', '2em');
    $('th.teacher-name').next('th').css('padding-left', '2em');
    $('th.user-name').css('padding-left', '2em');
    // $('-webkit-scrollbar').css('width', '0 !important');
  }
});

$(document).ready(function () {
  function getParameterByName(name, url) {
      if (!url) {
        url = window.location.href;
      }
      name = name.replace(/[\[\]]/g, "\\$&");
      var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
          results = regex.exec(url);
      if (!results) return null;
      if (!results[2]) return '';
      return decodeURIComponent(results[2].replace(/\+/g, " "));
  }

  var flyers = getParameterByName('flyers'); // "lorem"

  if (flyers == '1') {
      // get signup modal
      // activate the flyers portion
      var id = 'printer';
      $('#myModal').modal('toggle');
      var sidebar_options = ['easel', 'envelope', 'printer', 'spreadsheet']
      var arr = sidebar_options.filter(function(item) { 
          return item !== id;
      });

      for (var i = 0; i < arr.length; i++) {
          $('#main-' + arr[i]).css('display', 'none'); 
          $('#' + arr[i]).removeClass('active');
      }
      $('#main-' + id).css('display', 'block');
      $('#printer').addClass('active');
  }

});

$(document).ready(function(){
  $('#myModal').on('hidden.bs.modal', function(event) {
    $('#invite-parents-success').hide(); 
  });
});



$(document).ready(function () {
  $('#top-button.signup-button').click(function() {
    $.ajax({
      url: 'teacher/visited_page',
      type: 'get',
      dataType: 'text',
      success: function(data) {
      },
      error: function(xhr) {
      }
    })
  }); 
});

$(document).ready(function () {
  $('.user-info').click(function(event) {
    $('.user-info').not(this).removeClass('user-spotlight');
    $(this).addClass('user-spotlight');
    if ($(this).is(':first-child')) {
      $('.user-info').not(this).addClass('user-info-first-box');
      $(this).addClass('first-row');
    } else {
      $('.user-info').not(this).removeClass('user-info-first-box');
      $('.user-info:first-child').removeClass('first-row');
    }

    // $('.user-info').not(this).css('background-color', 'white');
    // $(this).css('background-color', 'rgba(255,240,208,0.35)');

    var id = $(this).attr('id');
    var infoBox = $('#' + id + '.the-whole-user-thing'); 
    $('.the-whole-user-thing').not(infoBox).css('display', 'none');
    infoBox.css('display', 'block');
    $('.default-user-info').css('display', 'none');
  });

  // $('.user-info').hover(function() {
  //   $(this).css('background-color', '#eceff1');
  // });
  // 
  // 
   // get a border on the bottom of the left table panel
  var rows_height = $('.users-table').height();
  // check if this is greater than the height of the table, 27.5em
  var table_height = $('.users-table-responsive').height();

  var leftover_height;

  if (rows_height > table_height) {
    leftover_height = 0;
  } else {
    leftover_height = table_height - rows_height;
  }


  $('.leftover-space').css('height', leftover_height);

  $('.user-info:last-child').css('border-bottom', 'solid rgb(210, 218, 224) 0.5px')
  // $('.teacher-info:last-child').css('border-bottom', 'solid rgb(210, 218, 224) 0.5px')


});

$(document).ready(function () {
  $('.tabs li').click(function() {
    var id = $(this).attr('id');
    var sidebar_options = ['easel', 'envelope', 'printer', 'spreadsheet']

    var arr = sidebar_options.filter(function(item) { 
        return item !== id;
    });


    for (var i = 0; i < arr.length; i++) {
        $('#main-' + arr[i]).css('display', 'none'); 
        $('#' + arr[i]).removeClass('active');
    }

    $(this).addClass('active');
    $('#main-' + id).css('display', 'block');

  });

});

$(document).ready(function () {

  document.getElementById("uploadBtn").onchange = function () {
    var string = this.value
    regex = 
    string = string.split(/[\\/]/);

    document.getElementById("uploadFile").value = string[string.length - 1];
  };

  // validate file upload
  // $('#fileInput').val()
});




$(document).ready(function() {
  $(".next-button").click( function() 
      { $("#shot-title").replaceWith( "<p id=\"shot-title\">Read books and get questions to ask</p>");
        $(".modal-screenshot").attr("src", "https://s3.amazonaws.com/st-webpage/assets/shot-2.png");
        $(".done-button").show();
        $(".next-button").hide();
      }
    );

  $(".done-button").click( function() 
      {
        $(".next-button").show();
        $(".done-button").hide();
        $("#shot-title").replaceWith( "<p id=\"shot-title\">Get books from you and reply</p>");
                    $(".modal-screenshot").attr("src", "https://s3.amazonaws.com/st-webpage/assets/shot-1.png");


      }
    );
    

});

$(document).ready(function() {

  function inviteFamilies() {

    $.post('/enroll_families_form_success', $('form#enroll-teacher-class').serialize());

    $('#invite-parents-success').hide();
    $('#invite-parents-success').slideDown(); 

  }

});


