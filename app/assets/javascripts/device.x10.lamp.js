(function($) {
  if (typeof(Device) == "undefined") { throw("Device not defined"); }
  if (typeof(Device.X10) == "undefined") { throw("Device.X10 not defined"); }
  Device.X10.Lamp = function(attributes) {
    var me = new Device(attributes);
    me.field_order.push([ "dim_level", "Brightness" ]);
    $.extend(this, me);
  };
  Device.X10.Lamp.namespace = "device";
})(jQuery);