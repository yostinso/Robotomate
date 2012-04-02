(function() {
  var Device = function(attributes) {
    var me = new DataRow(attributes, {
      primary_key: 'id',
      field_order: [
        [ 'id', "" ],
        [ 'name', "Name" ],
        [ 'state', "Status" ]
      ],
      renderers: {
        'state': function(d, val) {
          var other_val = (val == "on" ? "off" : "on");
          return '<a class="device_toggle ' + val + '" href="/device/' + d.fields.id + '/' + other_val + '">' + val + '</a>';
        }
      }
    });
    $.extend(this, me); // Device inherits from DataRow
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
