$(document).ready(function(){
  $(".block").click(function(){
    $.ajax({
      url: "/users/block/"+$(this).attr("rel")
    })
  })
})