(function() {
  var toggle_on_off = function(e) {
    var btn = $(e.target);
    var btns = btn.parent().find('.btn');
    if (btn.hasClass('btn-danger')) {
      this.turn_off();
      btns.removeClass('btn-danger').addClass('btn-success');
      btn.html("Turn On");
    } else {
      this.turn_on();
      btns.removeClass('btn-success').addClass('btn-danger');
      btn.html("Turn Off");
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
          var btns = btn_group.children('button');
          var btn = btns.filter(":first");
          if (btn.length != 1) {
            btn = $(document.createElement("button")).appendTo(btn_group).addClass('btn btn-mini');
            btn.click($.proxy(toggle_on_off, this));
            btns = btn;
          }
          if (val == "off") {
            btns.removeClass('btn-danger').addClass('btn-success');
            btn.html("Turn On");
          } else {
            btns.removeClass('btn-success').addClass('btn-danger');
            btn.html("Turn Off");
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
