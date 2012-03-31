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
      s = function(a, b) { return cmp(a[sort_by], b[sort_by]) };
    } else if (sort_by == '' || sort_by == undefined) {
      s = cmp;
    }
    return s;
  };

  var DataRow = function(fields, options) {
    this.fields = fields;
    this.field_order = options.field_order;
    this.primary_key_name = options.primary_key || 'id';
    this.renderers = options.renderers || {};
    this.primary_key = this.fields[this.primary_key_name];
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
    var i, name;
    for (i in this.field_order) {
      name = this.field_order[i][0];
      if (this.fields.hasOwnProperty(name)) {
        var col = (
          this._content.fields[name] || (this._content.fields[name] = $(document.createElement('td')).addClass(name))
          );
        col.html(this.renderers[name] ? this.renderers[name](this, this.fields[name]) : this.fields[name]);
      }
    }
    this._content.tr.html(""); // TODO maybe don't have to clear this out? (remove missing, append otherwise)
    for (i in this.field_order) {
      name = this.field_order[i][0];
      if (this.fields.hasOwnProperty(name)) { this._content.tr.append(this._content.fields[name]); }
    }

    return this._content.tr;
  };
  DataRow.prototype.equal = function(other) {
    if (this.primary_key != undefined || other.primary_key != undefined) {
      return this.primary_key == other.primary_key;
    } else {
      var k, seen = {};
      for (k in this) {
        seen[k] = true;
        if (other[k] != this[k]) { return false; }
      }
      for (k in other) {
        if (!seen[k]) { return false; }
      }
      return true;
    }
  };
  DataRow.prototype.setTable = function(data_table) {
    if (this.data_table) { data_table.removeRow(this.data_table); }
    if (data_table) { data_table.addRow(this); }
  };
  DataRow.prototype.refresh = function() {
    this.content(); // TODO: Smarter redraw
  }

  var DataTable = function(container, options) {
    options = options || {};
    this.container = container;
    this.data = [];

    this.sort_key = options.sort_key || 'primary_key';
    this.sort_func = sort_cmp(this.sort_key);
    this.sorted = options.sorted == undefined ? true : options.sorted;

    $(this.container).html(this.content());
  };
  DataTable.prototype.content = function() {
    if (!this._content) {
      var t = $(document.createElement("table")).addClass('data_table');
      this._content = {
        table: t,
        header: $(document.createElement("thead")).append($(document.createElement("tr")).addClass('header_row')).appendTo(t),
        body: $(document.createElement("tbody")).appendTo(t)
      };

    }
    return this._content.table;
  };
  DataTable.prototype.refresh = function() {
    if (this.sorted) { this.data.sort(this.sort_func); }
    var i;
    if (this.data.length > 0) {
      this._content.header.html("");
      for (i in this.data[0].field_order) {
        $(document.createElement('th'))
          .html(this.data[0].field_order[i][1])
          .appendTo(this._content.header);
      }
    }
    this._content.header
    this._content.body.html(""); // TODO maybe don't have to clear this out? (remove missing, append otherwise)
    for (i in this.data) {
      this._content.body.append(this.data[i].content());
    }
  };
  DataTable.prototype.addRow = function(data_row, maintain_unique) {
    if (maintain_unique == undefined) { maintain_unique = true; }
    if (maintain_unique && data_row.primary_key != undefined) {
      var i;
      for (i in this.data) {
        if (this.data[i].primary_key === data_row.primary_key) { return; }
      }
    }
    this.data.splice(i, 0, data_row);
    this.refresh();
  };
  DataTable.prototype.removeRow = function(data_row) {
    for (var i in this.data) {
      if (this.data[i].equal(data_row)) {
        this.data.splice(i, i);
      }
    }
    this.refresh();
  }

  window.DataTable = DataTable;
  window.DataRow = DataRow;
})(jQuery);
