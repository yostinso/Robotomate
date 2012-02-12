(function($) {
  var DEFAULT_REFRESH_INTERVAL = 5000; // milliseconds; set to 0 for no refresh
  var DEVICE_URI_TEMPLATE = "/device/%d";
  var Device = function(id, fieldElements, defaultValues, options) {
    options = options || {};
    
    this.id = id;
    this.fieldValues = defaultValues || {};
    this.fieldElements = fieldElements || {};
    this.refreshInterval = (options.refresh == undefined) ? DEFAULT_REFRESH_INTERVAL : options.refresh;

    if (this.refreshInterval > 0) {
      this.start_refresh();
    }
  };
  Device.prototype.stop_refresh = function() {
    this.start_refresh(0);
  }
  Device.prototype.start_refresh = function(new_refresh) {
    if (new_refresh != undefined) { this.refreshInterval = new_refresh; }
    if (this.refreshInterval <= 0) { 
      clearTimeout(this.timer);
      return;
    }

    if (!this.timer) {
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
  Device.prototype.do_refresh = function() {
    var uri = DEVICE_URI_TEMPLATE.replace('%d', this.id);
    DataLoader.get_json(uri, {
      success: $.proxy(function(result) {
        var field;
        for (field in result) {
          this.fieldValues[field] = result[field];
        }
        this.redraw();
      }, this)
    });
  };
  Device.prototype.redraw = function() {
    var field;
    for (field in this.fieldValues) {
      var value = this.fieldValues[field],
          elem = this.fieldElements[field];

      if (elem) {
        if (typeof(elem) == "function") {
          elem(value); // Callback
        } else {
          // Assume it's a jQuery collection of elements
          elem.each(function(i, e) {
            if (e.value != undefined) {
              $(e).val(value); // Form element
            } else {
              $(e).html(value); // Text element
            }
          });
        }
      }
    }
  };

  window.Device = Device;
})(jQuery);
