// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require data_table
//= require remote_event_proxy
//= require device
//= require device.x10
//= require device.x10.lamp
//= require device.infrared
//
// Twitter Bootstrap via less-rails-bootstrap gem
//= require twitter/bootstrap

(function($) {
  $(document).ready(function() {
    //
    $('INPUT.single-char')
      .focus(function(e) { $(this).select(); }) // TODO: What's the right call here?
      .click(function(e) { $(this).select(); })
      .keyup(function(e) {
        var i = $(this);
        console.log(i.val());
        if (i.val().length == 1) {
          console.log(i.next('INPUT'));
        }
    })
  });
})(jQuery);