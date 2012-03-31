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
  window.Device = Device;
})();
