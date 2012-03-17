(function($) {
  var DEFAULT_REFRESH_INTERVAL = 5000; // milliseconds; set to 0 for no refresh
  var DataElement = function(options) {
    this.options = options || {};
    this.refreshInterval = (this.options.refresh == undefined) ? DEFAULT_REFRESH_INTERVAL : this.options.refresh;

    this.bindings_ = {};
    this.binding_id_num_ = 0;
    if (this.options.bindings) {
      var fieldname;
      for (fieldname in this.options.bindings) {
        this.bind_to(fieldname, this.options.bindings[fieldname]);
      }
    }
    if (this.options.on_create) { $.proxy(this.options.on_create, this)(); }

    if (this.refreshInterval > 0) {
      this.start_refresh();
    }
    this.fieldValues = this.options.default_values || {};
  };
  DataElement.prototype.stop_refresh = function() {
    clearTimeout(this.timer);
    this.timer = undefined;
    this.start_refresh(0);
  };
  DataElement.prototype.start_refresh = function(new_refresh) {
    if (new_refresh != undefined) {
      this.refreshInterval = new_refresh;
    } else if (this.timer == undefined && this.refreshInterval <= 0) {
      // Restart with defaults
      this.refreshInterval = (this.options.refresh == undefined) ? DEFAULT_REFRESH_INTERVAL : this.options.refresh;
    }
    if (this.refreshInterval <= 0) { return; }

    if (!this.timer && this.refreshInterval > 0) {
      // Start a new timer
      this.do_refresh();
      this.timer = setTimeout(
        $.proxy(
          function() {
            this.timer = undefined;
            this.start_refresh();
          },
          this
        ),
        this.refreshInterval
      );
    }
  };
  DataElement.prototype.do_refresh = function() {
    var uri = this.uri;
    DataLoader.get_json(uri, {
      success: $.proxy(function(result) {
        var field;
        for (field in result) {
          this.fieldValues[field] = result[field];
        }
        this.update();
      }, this)
    });
  };
  DataElement.prototype.bind_to = function(fieldname, binding_info) {
    var element_or_callback = binding_info;
    var mapping_callback;
    if ($.isArray(binding_info)) {
      element_or_callback = binding_info[0];
      mapping_callback = binding_info[1];
      if (mapping_callback) { mapping_callback = $.proxy(mapping_callback, this); }
    }
    this.bindings_[fieldname] = this.bindings_[fieldname] || [];
    var callback = element_or_callback;
    if (!$.isFunction(element_or_callback)) {
      var element = $(element_or_callback);
      if (element.attr('value') != undefined) {
        // form element with .val()
        callback = function(newval) { element.val(newval); };
      } else {
        // regular element, replace the contents
        callback = function(newval) { element.html(newval); }
      }
    }

    this.bindings_[fieldname].push([ this.binding_id_num_, callback, mapping_callback ]);
    this.binding_id_num_++;
    return this.binding_id_num_;
  };
  DataElement.prototype.unbind = function(fieldname, callback_or_id) {
    if (fieldname == undefined) {
      this.bindings_ = {};
      return true;
    }
    if (callback_or_id == undefined) {
      if (this.bindings_[fieldname]) {
        this.bindings_[fieldname] = [];
        return true;
      } else {
        return false;
      }
    } else {
      var match_field = $.isNumeric(callback_or_id) ? 0 : 1;
      var removed = false;
      this.bindings_[fieldname] = $.grep(this.bindings_[fieldname], function (e) {
        if (e[match_field] == callback_or_id) {
          removed = true;
          return false;
        } else { return true; }
      });
      return removed;
    }
  };
  DataElement.prototype.update = function() {
    var fieldname, i;
    for (fieldname in this.fieldValues) {
      if (this.bindings_[fieldname]) {
        for (i in this.bindings_[fieldname]) {
          var binding = this.bindings_[fieldname][i];
          var val = binding[2] ? binding[2](this.fieldValues[fieldname]) : this.fieldValues[fieldname] // mapping_callback
          binding[1](val);
        }
      }
    }
  };
  DataElement.prototype.destroy = function() {
    this.unbind();
    this.stop_refresh();
    if (this.options.on_destroy) { $.proxy(this.options.on_destroy, this)(); }
  };
  window.DataElement = DataElement;
})(jQuery);

(function($) {
  var DEVICE_URI_TEMPLATE = "/device/%d";
  var DEVICE_LIST_URI = "/device.json";
  var Device = function(id, options) {
    this.id = id;
    this.uri = DEVICE_URI_TEMPLATE.replace('%d', this.id);
    $.proxy(DataElement, this)(options);
  };
  Device.prototype = DataElement.prototype;
  Device.fieldNames = function() { return [
    { field: 'name', name: "Name" },
    { field: 'address', name: "Address" },
    { field: 'state', name: "State" }
  ]; };
  Device.list_uri = DEVICE_LIST_URI;
  Device.name = "device";
  window.Device = Device;
})(jQuery);

(function($) {
  var DEFAULT_REFRESH_INTERVAL = 10000; // 10 seconds
  var DataTable = function(container, klass, fieldNames) {
    this.fieldNames_ = fieldNames || klass.fieldNames();
    this.list_uri_ = klass.list_uri;
    this.elements_ = [];
    this.container = $(container);
    this.refreshInterval = DEFAULT_REFRESH_INTERVAL;
    this.klass_ = klass;

    this.table = $(document.createElement("table")).addClass("data_table " + klass.name);
    this.tbody = $(document.createElement("tbody")).appendTo(this.table);
    this.table.attr('border', '1'); // TODO DEBUG
    var row = $(document.createElement("tr")).addClass("header").appendTo(this.table);
    $.each(this.fieldNames_, function(i, e) {
      $(document.createElement("th")).html(e.name).appendTo(row);
    });

    this.container.html(this.table);

    this.start_refresh();
  };
  DataTable.prototype.addElement = function(id) {
    var fields = {};
    var row = $(document.createElement("tr"));
    $.each(this.fieldNames_, function(i, f) {
      fields[f.field] = [
        $(document.createElement("td")).addClass(f.field).appendTo(row),
        f.mappingCallback
      ]
    });
    var tbdy = this.tbody;
    var e = new this.klass_(id, {
      on_create: function() { tbdy.append(row); },
      on_destroy: function() { row.remove(); },
      bindings: fields
    });
    this.elements_.push(e);
  };
  DataTable.prototype.removeElement = function(id) {
    this.elements_ = $.grep(this.elements_, function(d) {
      if (d.id == id) {
        d.destroy(); return false;
      } else {
        return true;
      }
    });
  };
  DataTable.prototype.setElements = function(ids) {
    var currentIds = $.map(this.elements_, function(e) { return e.id; });
    var newIds = $.grep(ids, function(id) { return (currentIds.indexOf(id) < 0); }); // ids not in currentIds
    var removedIds = $.grep(currentIds, function(id) { return (ids.indexOf(id) < 0); }); // currentIds not in ids

    // for-loops make scoping 'this' easier
    var i;
    for (i in newIds) { this.addElement(newIds[i]); }
    for (i in removedIds) { this.removeElement(removedIds[i]); }
  };
  DataTable.prototype.do_refresh = function() {
    var me = this;
    DataLoader.get_json(
      this.list_uri_, {
        success: function(ids) { me.setElements(ids); }
      });
  };
  DataTable.prototype.stop_refresh = function() {
    clearTimeout(this.timer);
    this.timer = undefined;
    this.start_refresh(0);
  };
  DataTable.prototype.start_refresh = function(new_refresh) {
    if (new_refresh != undefined) {
      this.refreshInterval = new_refresh;
    } else if (this.timer == undefined && this.refreshInterval <= 0) {
      // Restart with defaults
      this.refreshInterval = (this.options.refresh == undefined) ? DEFAULT_REFRESH_INTERVAL : this.options.refresh;
    }
    if (this.refreshInterval <= 0) { return; }

    if (!this.timer && this.refreshInterval > 0) {
      // Start a new timer
      this.do_refresh();
      this.timer = setTimeout(
        $.proxy(
          function() {
            this.timer = undefined;
            this.start_refresh();
          },
          this
        ),
        this.refreshInterval
      );
    }
  };
  window.DataTable = DataTable;
})(jQuery);
