(function($) {
  var singleton = undefined; // TODO

  /**
   * Create a Subscriptions container for tracking subscribed events
   * @this {Subscriptions}
   */
  var Subscriptions = function() {
    this.data = {};
  };
  /**
   * Add a new subscription (duplicates are ignored)
   * @param {String} namespace the model name or namespace for the subscription, e.g. "user"
   * @param {String} event the name of the event to subscribe to
   * @param id (optional; required for some event types) an identifier or filter for the event subscription (e.g. a model ID)
   */
  Subscriptions.prototype.add = function(namespace, event, id) {
    if (!namespace) { throw("No namespace provided for " + event + "!"); }
    this.data[namespace] = this.data[namespace] || [];
    var exists = $.grep(this.data[namespace], function(e) {
      return e.event == event && e.id == id
    }).length > 0;
    if (!exists) {
      this.data[namespace].push({ event: event, id: id });
    }
  };
  /**
   * Remove a subscription (or set of subscriptions)
   * @param {String} namespace the model name or namespace for the subscription; removes all events if not specified
   * @param {String} event the name of the event to subscribe to (removes all events for the namespace if unspecfied)
   * @param id (optional) removes only the subscription for the specified identifier or filter if specified
   */
  Subscriptions.prototype.remove = function(namespace, event, id) {
    if (namespace != undefined && event != undefined && id != undefined && this.data[namespace]) {
      this.data[namespace] = $.grep(this.data[namespace], function(e) {
        return e.event == event && e.id == id;
      }, true); // 'true' argument inverts grep (it becomes reject)
    } else if (namespace != undefined && event != undefined) {
      this.data[namespace] = undefined;
    } else if (namespace == undefined) {
      this.data = {};
    }
  };
  /**
   * Returns true if there are any subscriptions to this event
   * @param {String} namespace the model name or namespace for the subscription
   * @param {String} event the name of the event potentially subscribed to
   * @return {Boolean} true if there are any subscriptions using this namespace/event regardless of identifier or filter
   */
  Subscriptions.prototype.subscribed_to = function(namespace, event) {
    return $.grep(this.data[namespace], function(e) { return e.event == event; }).length > 0;
  };
  Subscriptions.prototype.to_data = function() {
    var data_hash = {};
    var event, subs_list;
    for (var namespace in this.data) {
      subs_list = [];
      for (var i in this.data[namespace]) {
        event = this.data[namespace][i];
        subs_list.push(event.event + ((event.id == undefined || event.id == null) ? '' : ' ' + event.id));
      }
      data_hash[namespace] = subs_list.join(";");
    }
    return data_hash;
  };

  var RemoteEvent = function(namespace, name, options) {
    this.namespace = namespace;
    this.name = name;
    this.data = options;
  };
  RemoteEvent.prototype.raise = function(target) {
    target = $(target) || $(this);
    target.triggerHandler(this.name + "." + this.namespace, this.data);
  };

  var RemoteEventProxy = function(poll_url, subscription_url, timeout) {
    this.poll_url = poll_url;
    this.subscription_url = subscription_url;
    this.subscriptions = new Subscriptions();
    this.timeout = timeout || 60000; // 60 second default timeout
    this.min_wait = 3000; // wait 3 second minimum between queries
    this.min_subscription_wait = 1000; // wait 3 second minimum between queries
    singleton = this;
  };
  RemoteEventProxy.prototype.parseEvents = function(data) {
    var remote_event;

    for (var i in data) {
      remote_event = new RemoteEvent(data[i].namespace, data[i].event, data[i].options);
      remote_event.raise(this);
    }
  };
  RemoteEventProxy.prototype.start = function() {
    if (!this.running) {
      this.running = true;
      this.last_request = undefined;
      this.waitForEvents();
    }
  };
  RemoteEventProxy.prototype.stop = function() {
    this.running = false;
  };
  RemoteEventProxy.prototype.updateSubscriptions = function() {
    if (this.last_subscription_update && (Date.now() - this.last_subscription_update < this.min_subscription_wait)) {
      // We just ran one, so queue this to run soon
      if (this.outstanding_subscription_update) { return; } // Already queued up
      this.outstanding_subscription_update =  setTimeout($.proxy(this.updateSubscriptions, this), this.min_subscription_wait - (Date.now() - this.last_subscription_update) + 50);
      return;
    }
    this.last_subscription_update = Date.now();
    this.outstanding_subscription_update = false;

    $.ajax({
      url: this.subscription_url,
      data: this.subscriptions.to_data(),
      dataType: 'json',
      global: false,
      context: this,
      type: 'POST',
      error: function() { console.log("Unable to update subscriptions"); }
    });
  };
  RemoteEventProxy.prototype.waitForEvents = function() {
    if (!this.running) { return; }
    if (this.last_request && (Date.now() - this.last_request < this.min_wait)) {
      setTimeout($.proxy(this.waitForEvents, this), this.min_wait - (Date.now() - this.last_request) + 50);
      return;
    }
    this.last_request = Date.now();
    $.ajax({
      url: this.poll_url,
      cache: false,
      global: false,
      timeout: this.timeout,
      type: 'GET',
      context: this,
      success: this.parseEvents,
      complete: this.waitForEvents,
      error: function(xhr, status) {
        if (status != "parsererror") {
          if (console && console.log) { console.log("connection error; giving up on live updates.");
            this.stop();
          }
        }
      }
    });
  };
  /**
   *
   * @param namespace_or_model
   * @param {String} namespace_or_model the namespace for the subscription, or an object that responds to .namespace
   * @param {String} .delete(d.id)event the name of the event to subscribe to
   * @param id (optional; required for some event types) an identifier or filter for the event subscription (e.g. a model ID)
   * @param {Function} callback (optional) immediately set up a binding to call callback when the event fires, expect
   *        the callback will get the event as the first argument and any updated data as the second argument
   * @see Subscriptions.add
   */
  RemoteEventProxy.prototype.subscribe = function (namespace_or_model, event, id, callback) {
    var namespace = typeof(namespace_or_model) == "string" ? namespace_or_model : namespace_or_model.namespace;
    if (callback) {
      $(this).bind(event + "." + namespace, callback);
    }
    this.subscriptions.add(namespace, event, id);
    this.updateSubscriptions();
  };
  RemoteEventProxy.prototype.unsubscribe = function(namespace_or_model, event, id) {
    var namespace = typeof(namespace_or_model) == "string" ? namespace_or_model : namespace_or_model.namespace;
    this.subscriptions.remove(namespace, event, id);
    if (id == undefined || !this.subscriptions.subscribed_to(namespace, event)) {
      // Go ahead and remove any callbacks if we're unsubscribed to all events of this type
      $(this).unbind(event + "." + namespace);
    }
    this.updateSubscriptions();
  };
  RemoteEventProxy.start = function(url, timeout) {
    if (!singleton) {
      singleton = new RemoteEventProxy(url, timeout);
    }
    singleton.start();
    return singleton;
  };
  RemoteEventProxy.stop = function() {
    if (singleton) { singleton.stop(); }
  };
  RemoteEventProxy.subscribe = function(namespace_or_model, event, id, callback) {
    singleton.subscribe(namespace_or_model, event, id, callback);
  };
  RemoteEventProxy.unsubscribe = function(namespace_or_model, event, id) {
    singleton.unsubscribe(namespace_or_model, event, id);
  };

  window.RemoteEventProxy = RemoteEventProxy;
})(jQuery);
