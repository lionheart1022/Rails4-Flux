if (typeof cargoflux === 'undefined') {
  cargoflux = new Object({});
}

cargoflux.waitFor = function (script, callback) {
  if (window[script])
    return callback();
  else
    setTimeout(function() { cargoflux.waitFor(script, callback) }, 500);
}
