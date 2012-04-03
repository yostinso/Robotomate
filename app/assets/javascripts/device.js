(function() {
  var toggle_on_off = function(e) {
    var on = $(e.target).parent().find('.btn-success');
    var off = $(e.target).parent().find('.btn-danger');
    if (on.hasClass('active')) {
      this.turn_off();
      on.removeClass('active');
      off.addClass('active');
    } else {
      this.turn_on();
      off.removeClass('active');
      on.addClass('active');
    }
  };

  var Device = function(attributes) {
    var me = new DataRow(attributes, {
      primary_key: 'id',
      field_order: [
        [ 'id', "" ],
        [ 'name', "Name" ],
        [ 'state', "Status" ]
      ],
      renderers: {
        'state': $.proxy(function(container, d, val) {
          var btn_group = $(container.children('div.btn-group'));
          if (btn_group.length != 1) { btn_group = $(document.createElement('div')).addClass('btn-group').appendTo(container); }
          var on = btn_group.children('.btn-success');
          if (on.length != 1) {
            on = $(document.createElement("button")).appendTo(btn_group).addClass('btn btn-mini btn-success').html("on");
            on.click($.proxy(toggle_on_off, this));
          }
          var off = btn_group.children('.btn-danger');
          if (off.length != 1) {
            off = $(document.createElement("button")).appendTo(btn_group).addClass('btn btn-mini btn-danger').html("off");
            off.click($.proxy(toggle_on_off, this));
          }
          if (val == "off") {
            on.removeClass('active'); off.addClass('active');
          } else {
             off.removeClass('active'); on.addClass('active');
          }
        }, this)
      }
    });
    $.extend(this, me); // Device inherits from DataRow
  };
  Device.prototype.turn_on = function() {
    $.ajax({
      url: "/device/" + this.fields.id + "/on",
      type: "POST"
    });
  };
  Device.prototype.turn_off = function() {
    $.ajax({
      url: "/device/" + this.fields.id + "/off",
      type: "POST"
    });
  };
  Device.namespace = "device";
  Device.prototype.update = function(e, attributes) {
    if (attributes.id == this.fields.id) {
      this.fields = attributes;
      this.refresh();
    }
  };
  Device.prototype.subscribe = function(remote_event_proxy) {
    remote_event_proxy.subscribe(Device, 'state_changed', this.fields.id, $.proxy(this.update, this));
  };
  Device.prototype.unsubscribe = function(remote_event_proxy) {
    remote_event_proxy.unsubscribe(Device, 'state_changed', this.fields.id);
  };
  Device.create = function(device_hash) {
    var klass = Device;
    if (device_hash.type) {
      var subklasses = device_hash.type.split(/\./);
      while (subklasses.length > 0) {
        var type_name = subklasses.join(".");
        try {
          klass = eval(type_name);
          if (typeof(klass) != "undefined") {
            break;
          } else {
          }
        } catch (e) {
          klass = Device;
        }
        subklasses.pop();
      }
    }
    return new klass(device_hash);
  };
  Device.addDevice = function(e, d, data_table) {
    var data_table = data_table || Device.default_data_table;
    var device = Device.create(d);
    window.debug_devices = window.debug_devices || [];
    window.debug_devices.push(device);
    device.setTable(data_table);
    device.subscribe(RemoteEventProxy);
  };
  Device.removeDevice = function(e, d, data_table) {
    var data_table = data_table || Device.default_data_table;
    var device = Device.create(d);
    data_table.removeRow(device);
    device.unsubscribe(RemoteEventProxy);
  };


  window.Device = Device;
})();
