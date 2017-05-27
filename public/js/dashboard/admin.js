// hover effect for right arrow
$(document).ready(function () {
  $('.the-whole-teacher-thing').mouseenter(function() {
    $('.right-arrow').animate({
      opacity: 1.0
    }, 200);
  });

  $('.the-whole-teacher-thing').mouseleave(function() {
    $('.right-arrow').animate({
      opacity: 0.3
    }, 200);
  });
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
  $('#top-button.signup-button').click(function() {
    $.ajax({
      url: 'teacher/visited_page',
      type: 'get',
      dataType: 'text',
      success: function(data) {
      },
      error: function(xhr) {
        console.log(xhr);
      }
    })
  }); 
});

$(document).ready(function () {
  $('.the-whole-teacher-thing').first().css('display', 'block');
  $('.teacher-info:first-child').addClass('user-spotlight first-row');
  $('.teacher-info').slice(1).addClass('user-info-first-box');
  $('.user-info:first-child').addClass('user-spotlight first-row');
  $('.teacherModal').each(function(index, value) {
  
    $(this).find('.the-whole-user-thing').first().css('display', 'block');
    $(this).find('.user-info').slice(1).addClass('user-info-first-box');
  });

});

// clicking rows, selecting users and teachers
$(document).ready(function () {
  // teachers
  $('.teacher-info').click(function(event) {
    $('.teacher-info').not(this).removeClass('user-spotlight');
    $(this).addClass('user-spotlight');

    if ($(this).is(':first-child')) {
      $('.teacher-info').not(this).addClass('user-info-first-box');
      $(this).addClass('first-row');
    } else {
      $('.teacher-info').not(this).removeClass('user-info-first-box');
      $('.teacher-info:first-child').removeClass('first-row');
    }

    var id = $(this).attr('id');
    var infoBox = $('#' + id + '.the-whole-teacher-thing'); 
    $('.the-whole-teacher-thing').not(infoBox).css('display', 'none');
    infoBox.css('display', 'block');
    // $('.default-teacher-info').css('display', 'none');
  });

  // users
  $('.user-info').click(function(event) {
    var parent = $(this).parent();
    $(parent).find('.user-info').not(this).removeClass('user-spotlight');
    $(this).addClass('user-spotlight');

    if ($(this).is(':first-child')) {
      $(parent).find('.user-info').not(this).addClass('user-info-first-box');
      $(this).addClass('first-row');
    } else {
      $(parent).find('.user-info').not(this).removeClass('user-info-first-box');
      $(parent).find('.user-info:first-child').removeClass('first-row');
    }

    var id = $(this).attr('id');
    var infoBox = $('#' + id + '.the-whole-user-thing'); 
    // hide the other guys
    $(this).closest('.teacherModal').find('.the-whole-user-thing').not(infoBox).css('display', 'none');
    infoBox.css('display', 'block');
    // $('.default-user-info').css('display', 'none');
  });


  // get a border on the bottom of the left table panel
  var rows_height = $('.teacher-table').height();
  // check if this is greater than the height of the table, 27.5em
  var table_height = $('.teacher-table-responsive').height();

  var leftover_height;

  if (rows_height > table_height) {
    leftover_height = 0;
  } else {
    leftover_height = table_height - rows_height;
  }


  $('.leftover-space').css('height', leftover_height);

  $('.user-info:last-child').css('border-bottom', 'solid rgb(210, 218, 224) 0.5px')
  $('.teacher-info:last-child').css('border-bottom', 'solid rgb(210, 218, 224) 0.5px')

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



// for going straight to teacher-invite
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

  var invite = getParameterByName('invite'); // "lorem"

  if (invite == '1') {
      // activate the invite portion
      $('#inviteTeachersModal').modal('toggle');
  }

});
