(function($) {
  var is_numeric = function(n) { return !isNaN(parseFloat(n)) && isFinite(n); };
  var cmp = function(x, y) {
    if (x == undefined) { x = 0; }
    if (y == undefined) { y = 0; }
    if (is_numeric(x) && is_numeric(y)) {
      return x - y;
    } else {
      return x > y? 1 : x < y ? -1 : 0;
    }
  };
  var sort_cmp = function(sort_by) {
    var s = sort_by;
    if (typeof(sort_by) == "string") {
      s = function(a, b) { return cmp(a[sort_key], b[sort_key]) };
    } else if (sort_key == '' || sort_key == undefined) {
      s = cmp;
    }
    return s;
  };

  var DataRow = function(fields, options) {
    this.id = options.primary_key;
    this.fields = fields;
    this.field_order = options.field_order;
    if (!this.field_order) {
      for (var name in this.fields) {
        if(options.hasOwnProperty(name)) {  keys.push(name); }
      }
    }
  };
  DataRow.prototype.content = function() {
    if (!this._content) {
      this._content = {
        tr: $(document.createElement('tr')),
        fields: {}
      };
    }
    var name;
    for (name in this.field_order) {
      if (this.fields.hasOwnProperty(name)) {
        var col = (
          this._content.fields[name] || (this._content.fields[name] = $(document.createElement('td')).addClass(name))
          );
        col.html(this.fields[name]);
      }
    }
    this._content.tr.html(""); // TODO maybe don't have to clear this out? (remove missing, append otherwise)
    for (name in this.field_order) {
      if (this.fields.hasOwnProperty(name)) { this._content.append(this._content.fields[name]); }
    }

    return this._content.tr;
  };

  var DataTable = function(container, options) {
    options = options || {};
    this.container = container;
    this.data = [];

    this.sort_key = options.sort_key || 'primary_key';
    this.sort_func = sort_cmp(this.sort_key);
    this.sorted = options.sorted == undefined ? true : options.sorted;

    $(this.container).append(this.content());
  };
  DataTable.prototype.content = function() {
    if (!this._content) {
      this._content = {
        table: $(document.createElement("table")).addClass('data_table'),
        header: $(document.createElement("thead")).append($(document.createElement("tr")).addClass('header_row')),
        body: $(document.createElement("tbody"))
      };
    }
    return this._content.table;
  };
  DataTable.prototype.refresh = function() {
    if (this.sorted) { this.data.sort(this.sort_func); }
    this._content.body.html(""); // TODO maybe don't have to clear this out? (remove missing, append otherwise)
    for (var i in this.data) {
      this._content.body.append(this.data[i].content());
    }
  };
  DataTable.prototype.addRow = function(data_row, maintain_unique) {
    if (maintain_unique == undefined) { maintain_unique = true; }
    if (maintain_unique && data_row.primary_key != undefined) {
      var i;
      for (i in this.data) {
        if (this.data[i].primary_key === primary_key) { return; }
      }
    }
    this.data[i].push(data_row);
    this.refresh();
  };
})(jQuery);
