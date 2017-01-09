$(document).ready(function(){
          /* Get iframe src attribute value i.e. YouTube video url
          and store it in a variable */
          var url = $("#raynaVideo").attr('src');

          $("#videoExitButton").on('click', function(){
            $("#raynaVideo").attr("src", null);
          });

          $("#start-modal-button").click(function(){
            $("#raynaVideo").attr("src", url+"&autoplay=1");
          });

          $(document).click(function(event) {
            if(!$(event.target).closest('#start-modal-button').length) {
              $("#raynaVideo").attr("src", null);
            }
          });

          $('#raynaVideo').click(function(event){
              event.stopPropagation();
          });

      });