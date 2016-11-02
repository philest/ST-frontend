// script to append the first modal's field values to the form
$( document ).ready(function() {

  smoothScroll.init();
  
  $('button.demo-form-button').click(function(){
      $('form#demo-form').each(function(){
          $(this).submit();
      });
  });

  $('#login').on('submit', function(event) {
    // event.preventDefault();
    var teacherinfo = $("#teacher-info").serializeArray()
    console.log(teacherinfo);


    for (var i = 0; i < teacherinfo.length; i++) {
      console.log(teacherinfo[i])
      var input = $('<input>')
                    .attr('type', 'hidden')
                    .attr('name', teacherinfo[i]['name']).val(teacherinfo[i]['value']);
      $('#login').append($(input));
    }

    console.log($(this).serializeArray());

  });
});
