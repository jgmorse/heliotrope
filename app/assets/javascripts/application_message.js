$(document).ready(function () {
  if ($(".heb").length > 0 ) {
    closeMessage();
  }
});

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

function closeMessage() {
  $(".message button.dismiss").click(function() {
    $("div.message").hide();
  });
}
