System.register([], function (_export, _context) {
  "use strict";

  return {
    setters: [],
    execute: function () {
      const [foo, bar = 2] = [];

      _export("foo", foo);

      _export("bar", bar);
    }
  };
});
