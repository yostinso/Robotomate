(function($) {
  var singleton = undefined; // TODO

  var Subscriptions = function() {
    this.data = {};
  };
  Subscriptions.prototype.add = function(name, event, id) {
    this.data[name] = this.data[name] || [];
    this.data[name].push({ event: event, id: id })
  };
  Subscriptions.prototype.remove = function(name, event, id) {
    if (name != undefined && event != undefined && id != undefined && this.data[name]) {
      this.data[name] = $.grep(this.data[name], function(e) {
        return e.event == event && e.id == id;
      }, true); // 'true' argument inverts grep (it becomes reject)
    } else if (name != undefined && event != undefined) {
      this.data[name] = undefined;
    } else if (name == undefined) {
      this.data = {};
    }
  };
  Subscriptions.prototype.to_data = function() {
    var data_hash = {};
    var name, event, subs_list;
    for (name in this.data) {
      data_hash[name] = '';
      subs_list = [];
      for (event in this.data[name]) {
        subs_list.push(event.event + (event.id == undefined ? '' : ' ' + event.id));
      }
      data_hash[name] = subs_list.join(";");
    }
    return data_hash;
  }

  var RemoteEvent = function(name, options) {
    this.name = name;
    this.id = options.id; // optional
    this.data = $.clone(options);
    delete this.data[id];
  };
  RemoteEvent.prototype.raise = function(target) {
    target = $(target) || $(this);
    target.triggerHandler(this.name, this);
  };

  var RemoteEventManager = function(url, timeout) {
    this.url = url;
    this.subscriptions = new Subscriptions();
    this.timeout = timeout || 20000; // 20 second default timeout
    singleton = this;
  };
  /*
   * @param data [Array] from JSON, an array of hashes:
   *   [ { event: event_name, options: { id: optional_model_id, ... } } ]
  */
  RemoteEventManager.prototype.parseEvents = function(data, status, xhr) {
    var i, remote_event;

    for (i in data) {
      remote_event = new RemoteEvent(data[i].event, data[i].options);
      remote_event.raise(this);
    }
  };

  RemoteEventManager.prototype.waitForEvents = function() {
    $.ajax({
      url: this.url,
      cache: false,
      data: this.subscriptions.to_data(),
      dataType: 'json',
      global: false,
      timeout: this.timeout,
      type: 'POST',
      context: this,
      success: this.parseEvents,
      complete: this.waitForEvents
    });
  };




  };
})(jQuery);
