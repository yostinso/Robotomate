(function($) {
  if (typeof(Device) == "undefined") { throw("Device not defined"); }
  if (typeof(Device.X10) == "undefined") { throw("Device.X10 not defined"); }
  Device.X10.Lamp = function(attributes) {
    this.parent = new Device.X10(attributes);
    this.parent.field_order.push([ "dim_level", "Brightness" ]);
    this.parent.renderers['dim_level'] = function(d, val) {
      var container = $(document.createElement('div'))
        .addClass("x10_lamp_brightness").addClass("level_" + val);

      $(document.createElement('img'))
        .attr('src', Device.X10.Lamp.BULB_ICON)
        .attr('alt', val)
        .appendTo(container);
      return container;
    };
    $.extend(this, this.parent);
    $.extend(this, Device.X10.Lamp.prototype);
  };
  Device.X10.Lamp.prototype.subscribe = function(remote_event_proxy) {
    this.parent.subscribe(remote_event_proxy);
    remote_event_proxy.subscribe(Device, 'dim_level_changed', this.fields.id, $.proxy(this.update, this));
  };
  Device.X10.Lamp.prototype.unsubscribe = function(remote_event_proxy) {
    this.parent.unsubscribe(remote_event_proxy);
    remote_event_proxy.unsubscribe(Device, 'dim_level_changed', this.fields.id);
  };
  Device.X10.Lamp.MIN_BRIGHT = 1;
  Device.X10.Lamp.MAX_BRIGHT = 18;
  Device.X10.Lamp.namespace = "device";
})(jQuery);