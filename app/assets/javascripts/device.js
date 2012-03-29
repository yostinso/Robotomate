(function($) {
  var Device = function(id, attributes) {
    this.id = id;
    this.attributes = attributes;
  };
  Device.namespace = "device";

  window.Device = Device;
})(jQuery);
