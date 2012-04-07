(function($) {
  var is_numeric = function(n) { return !isNaN(parseFloat(n)) && isFinite(n); };
  var index_by = function(array, element, element_callback) {
    for (var i in array) {
      if (element[element_callback](array[i])) {
        return i;
      }
    }
    return -1;
  };
  var remove_by = function(array, element, element_callback) {
    var i = index_by(array, element, element_callback);
    if (i >= 0) {
      return array.splice(i, i);
    }
    return undefined;
  };
  var contains_by = function(array, element, element_callback) {
    if (index_by(array, element, element_callback) >= 0) { return true; }
    return false;
  }
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
  DataRow.prototype.content = function(expected_columns) {
    this.expected_columns = (expected_columns == undefined) ? this.expected_columns : expected_columns;
    var name;
    if (!this._content) {
      // Create the row and the data cells
      this._content = {
        tr: $(document.createElement('tr')),
        fields: {},
        blanks: []
      };
      for (var i in this.field_order) {
        name = this.field_order[i][0];
        if (this.fields.hasOwnProperty(name)) {
          i++;
          this._content.tr.append(
            this._content.fields[name] = $(document.createElement('td')).addClass(name)
          );
        }
      }
    }

    // Update content
    this.refresh();

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
    for (var name in this.fields) {
      if (this._content.fields.hasOwnProperty(name)) {
        if (this.renderers[name]) {
          this.renderers[name](this._content.fields[name], this, this.fields[name]);
        } else {
          this._content.fields[name].html(this.fields[name]);
        }
      }
    }

    // Add/remove any extra cells
    while (this.field_order.length+this._content.blanks.length < this.expected_columns) {
      this._content.blanks.push($(document.createElement('td')).addClass('empty').appendTo(this._content.tr));
    }
    while (this.field_order.length+this._content.blanks.length > this.expected_columns) {
      this._content.blanks.pop().remove();
    }

  }

  var DataTable = function(container, options) {
    this.options = options || {};
    this.container = container;
    this.data = [];

    this.sort_key = this.options.sort_key || 'primary_key';
    this.sort_func = sort_cmp(this.sort_key);
    this.sorted = this.options.sorted == undefined ? true : this.options.sorted;

    $(this.container).html(this.content());
  };
  DataTable.prototype.content = function() {
    if (!this._content) {
      var t = $(document.createElement("table")).addClass(this.options.classes || 'data_table');
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
    if (this.data.length > 0) {
      var i, j, k, headers = [], seen_headers = {};
      for (i in this.data) {
        for (j in this.data[i].field_order) {
          k = 0;
          j = parseInt(j);
          var header = this.data[i].field_order[j];
          if (seen_headers[header[0]]) { continue; }
          seen_headers[header[0]] = true;
          while (headers[j+k] != undefined) { k++; }
          headers[j+k] = header;
        }
      }
      this._content.header.html("");
      for (i in headers) {
        $(document.createElement('th'))
          .html(headers[i][1])
          .addClass(headers[i][0])
          .appendTo(this._content.header);
      }
    }
    this.displayed_data = this.displayed_data || [];
    for (i in this.data) {
      var d = this.data[i];
      if (!contains_by(this.displayed_data, d, 'equal')) {
        // Add this row
        this._content.body.append(this.data[i].content(headers.length));
        this.displayed_data.push(d);
      }
    }
    for (i in this.displayed_data) {
      var d = this.displayed_data[i];
      var idx = index_by(this.data, d, 'equal');
      if (!idx) {
        // Removed this row
        this.displayed_data.splice(idx, idx)[0].remove();
      }
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
