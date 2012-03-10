(function($) {
  var MAX_REQUESTS = 5;
  var Request = function(uri, options) {
    options = options || {};
    this.started = false;
    this.uri = uri;
    this.options = options;
  };
  Request.prototype.is_for = function(uri) { return (this.uri == uri); };
  Request.prototype.is_request_for = function(r) { return this.is_for(r.uri); };
  Request.prototype.start = function() {
    if (this.started) { return false; }
    this.started = true;

    $.ajax(
      this.uri,
      {
        cache: false,
        complete: function(xhr, status) {
          this.started = false;
          if (this.options.success_callback) {
            this.options.success_callback(xhr, status);
          }
        },
        context: this,
        data: this.options.params || '',
        dataType: 'json',
        error: this.options.error,
        success: this.options.success
      }
    );
  };

  var DataLoader = function() {
    this.outstandingRequests = [];
    this.runningRequests = [];
  };

  DataLoader.prototype.get_json = function(uri, options) {
    var r = new Request(uri, options);
    this.add_request(r);
  };

  DataLoader.prototype.add_request = function(request) {
    this.outstandingRequests.push(request);
    this.run_requests();
  };
  DataLoader.prototype.run_requests = function() {
    // Remove any expired requests
    this.runningRequests = $.grep(this.runningRequests, function(r) { return r.started; });
    while (this.outstandingRequests.length > 0 && this.runningRequests.length < MAX_REQUESTS) {
      var nextRequest = this.outstandingRequests.pop();
      // Ignore this request if there's already an outstanding one for the same data
      if ($.grep(this.runningRequests, function(r) { return r.is_request_for(nextRequest); }).length == 0) {
        this.runningRequests.push(nextRequest);
        nextRequest.start();
      }
      // Remove any more expired requests in case some expire in the middle of this loop
      // (Not sure this is totally necessary with single-threaded JS)
      this.runningRequests = $.grep(this.runningRequests, function(r) { return r.started; });
    }
  };

  var dataLoader = new DataLoader(); // Singleton
  
  // Static methods
  DataLoader.get_json = $.proxy(dataLoader.get_json, dataLoader);

  window.DataLoader = DataLoader;
})(jQuery);
