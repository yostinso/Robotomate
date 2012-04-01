(function($) {
  if (typeof(Device) == "undefined") { throw("Device not defined"); }
  if (typeof(Device.X10) == "undefined") { throw("Device.X10 not defined"); }
  Device.X10.Lamp = function(attributes) {
    var me = new Device(attributes);
    me.field_order.push([ "dim_level", "Brightness" ]);
    me.renderers['dim_level'] = function(d, val) {
      return '<svg src="' + Device.X10.Lamp.BULB_ICON + '" class="x10_lamp_brightness ' + val + '" alt="' + val + '" />';
    };
    $.extend(this, me);
  };
  Device.X10.Lamp.MIN_BRIGHT = 1;
  Device.X10.Lamp.MAX_BRIGHT = 18;
  Device.X10.Lamp.namespace = "device";
})(jQuery);