(function($) {
  var MAX_REQUESTS = 5;
  var ID_REQUESTS_EVERY = 1000;
  var Request = function(uri, options) {
    this.started = false;
    this.uri = uri;
    this.options = options || {};
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
        },
        context: this,
        data: this.options.params || '',
        dataType: 'json',
        error: this.options.error,
        success: this.options.success,
        type: this.options.type || "GET"
      }
    );
  };

  var IdRequest = function(uri, id, success) {
    this.uri = uri;
    this.id = id;
    this.success = success;
  };
  window.IdRequest = IdRequest;

  var DataLoader = function() {
    this.outstandingRequests = [];
    this.outstandingIdRequests = [];
    this.runningRequests = [];
  };
  DataLoader.prototype.get_json = function(uri, options) {
    var r = new Request(uri, options);
    this.add_request(r);
  };
  DataLoader.prototype.add_request = function(request) {
    if (request instanceof IdRequest) {
      if ($.grep(this.outstandingIdRequests, function(r) { return (r.id == request.id && r.uri == request.uri); }).length > 0) {
        return; // Don't add duplicates
      }
      this.outstandingIdRequests.push(request);
    } else {
      this.outstandingRequests.push(request);
    }
    this.run_requests();
  };
  DataLoader.prototype.merge_id_requests = function() {
    // Merge any outstanding IdRequests into a single Request
    var uri, merged = {};
    while (this.outstandingIdRequests.length > 0) {
      var r = this.outstandingIdRequests.pop();
      merged[r.uri] = merged[r.uri] || [];
      merged[r.uri].push(r);
    }
    for (uri in merged) {
      var i, ids = [], callbacks = [];
      for (i in merged[uri]) {
        var id = merged[uri][i].id;
        var original_callback = merged[uri][i].success;
        // Merged IdRequests should be given a JSON hash of { <id>: { field1: x, field2: x}, <id>: { ... } }
        // We make a Request for the json, the call the IdRequest.success for each hash by id
        var new_callback = function(full_result) { original_callback(full_result[id]); };
        ids.push(id);
        callbacks.push(new_callback);
        var r = new Request(uri, {
          params: { ids: ids.join(",") },
          type: "POST",
          success: function(result) { $.each(callbacks, function(i, c) { c(result); }); }
        });
        this.outstandingRequests.push(r);
      }
    }
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
