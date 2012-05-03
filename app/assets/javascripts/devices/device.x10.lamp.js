(function($) {
  if (typeof(Device) == "undefined") { throw("Device not defined"); }
  if (typeof(Device.X10) == "undefined") { throw("Device.X10 not defined"); }

  var lamp_image = function (val, klass) {
    var lamp_bg_div = $(document.createElement('div'))
      .css('display', 'inline-block')
      .addClass(klass).addClass("level_" + val);
    $(document.createElement('img'))
      .attr('src', Device.X10.Lamp.BULB_ICON)
      .attr('alt', val)
      .attr('title', val + "/" + Device.X10.Lamp.MAX_BRIGHT)
      .appendTo(lamp_bg_div);
    return lamp_bg_div;
  };

  Device.X10.Lamp = function(attributes) {
    this.parent = new Device.X10(attributes);
    this.parent.field_order.push([ "dim_level", "Brightness" ]);
    var orig_state = this.parent.renderers['state'];
    this.parent.renderers['state'] = $.proxy(function(container, d, val) {
      $.proxy(orig_state, this)(container, d, val);
      var btn_group = $(container.children('div.btn-group'));
      var btn_dropdown = btn_group.children('button.dropdown-toggle');

      if (btn_dropdown.length != 1) {
        btn_dropdown = $(document.createElement('button'))
          .addClass('btn btn-mini dropdown-toggle').attr('data-toggle', 'dropdown')
          .append( $(document.createElement('span')).addClass('caret') )
          .appendTo(btn_group);
        var dim_selector = $(document.createElement('ul')).addClass('dropdown-menu');
        for (var i = Device.X10.Lamp.MIN_BRIGHT; i <= Device.X10.Lamp.MAX_BRIGHT; i++) {
          $(document.createElement('li'))
            .append(
              $(document.createElement('a')).attr('href', '#').append(
                $(document.createElement('i')).addClass('icon-white').append(lamp_image(i, 'x10_lamp_brightness_icon'))
              ).append(
                "Dim to: " + i
              ).click(
                $.proxy(
                  (function(n) { return function() { this.set_dim(n); }; })(i)
                  , this)
              )
            )
            .appendTo(dim_selector);
        }
        dim_selector.appendTo(btn_group);
      }
      if (val == "off") {
        btn_dropdown.addClass('btn-success');
      } else {
        btn_dropdown.addClass('btn-danger');
      }
    }, this);
    this.parent.renderers['dim_level'] = function(container, d, val) {
      container.html(lamp_image(val, 'x10_lamp_brightness'));
    };
    $.extend(this, this.parent);
    $.extend(this, Device.X10.Lamp.prototype);
  };
  Device.X10.Lamp.prototype.subscribe = function(remote_event_proxy) {
    $.proxy(this.parent.subscribe, this)(remote_event_proxy);
    remote_event_proxy.subscribe(Device, 'dim_level_changed', this.fields.id, $.proxy(this.update, this));
  };
  Device.X10.Lamp.prototype.unsubscribe = function(remote_event_proxy) {
    $.proxy(this.parent.unsubscribe, this)(remote_event_proxy);
    remote_event_proxy.unsubscribe(Device, 'dim_level_changed', this.fields.id);
  };
  Device.X10.Lamp.prototype.set_dim = function(val) {
    $.ajax({
      url: "/device/" + this.fields.id + "/dim_to",
      data: { level: val },
      type: "POST"
    });
  };
  Device.X10.Lamp.MIN_BRIGHT = 1;
  Device.X10.Lamp.MAX_BRIGHT = 18;
  Device.X10.Lamp.namespace = "device";
})(jQuery);