$(function() {

  // ============================================================
  // Maps
  // ============================================================

  var google_url = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyCDSljlhW1uYv-Uc_F-jmw8GAhHM3Jk4oM&callback=cargoflux.initMap';

  if (!cargoflux._mapLoaded) {
    $.getScript(google_url, function () {
      cargoflux._mapLoaded = true;
    })
  }
  var ESCAPE_KEY = 27;

  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object({});
  }

  cargoflux._isShowingMapBox = false;

  /**
   * Initializes map
   */
  cargoflux.initMap = function () {
    if (document.getElementById("map") === null) {
      // There is no map on this page
      return;
    }

    cargoflux._directionsDisplay = new google.maps.DirectionsRenderer;
    cargoflux._directionsService = new google.maps.DirectionsService();

    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 14,
      center: {lat: 37.77, lng: -122.447}
    });

    cargoflux._directionsDisplay.setMap(map);
  }

  /**
   * Renders a route
   * @param  [DirectionsRenderer] directionsService
   * @param  [DirectionsRenderer] directionsDisplay
   */
  cargoflux.fetchRoute = function (origin, destination, callback) {
    console.log(origin, destination)
    cargoflux.resetMap();

    if (typeof cargoflux._directionsService === "undefined") {
      // There is no map on this page and therefore also not a direction service
      return;
    }

    cargoflux._directionsService.route({
      origin: origin,
      destination: destination,
      travelMode: google.maps.TravelMode.DRIVING,
      avoidFerries: true,
      provideRouteAlternatives: true
    }, function(response, status) {
      if (status == google.maps.DirectionsStatus.OK) {
        cargoflux.showRouteLink();

        var shortestRouteIndex    = Number.MAX_VALUE;
        var shortestRouteDistance = Number.MAX_VALUE;
        var shortestRouteText     = null;

        _.forEach(response.routes, function (route, index) {
          var legs = route.legs
          var distance = legs[0].distance;

          if (distance.value <= shortestRouteDistance) {
            shortestRouteIndex    = index;
            shortestRouteDistance = distance.value;
            shortestRouteText     = distance.text;
          }
        })

        var totalDistance = shortestRouteText
        cargoflux.setMapStatus(totalDistance);
        cargoflux._directionsDisplay.setDirections(response)  ;
        cargoflux._directionsDisplay.setRouteIndex(shortestRouteIndex);

      } else {
        cargoflux.hideRouteLink();
        cargoflux.setMapStatus('Route not available');
      }
    });
  }

  cargoflux.resetMap = function () {
    cargoflux.hideMapBox();
    // cargoflux.clearMapStatus();
    cargoflux._isShowingMapBox = false;
  }

  cargoflux.showRouteLink = function () {
    $('.route_link').show();
  }

  cargoflux.hideRouteLink = function () {
    $('.route_link').hide();
  }

  cargoflux.setMapStatus = function (status) {
    $('.map_status').text(status);
  }

  cargoflux.clearMapStatus = function () {
    $('.map_status').text('');
  }

  /**
   * Renders the container for the map at the cursor's position
   */
  cargoflux.toggleMapBox = function (_class, left, top) {
    cargoflux._isShowingMapBox ? cargoflux.hideMapBox(_class, left, top) : cargoflux.showMapBox(_class, left, top);
  }

  cargoflux.hideMapSection = function () {
    $('.map_section').hide();
  }

  cargoflux.showMapSection = function () {
    $('.map_section').show();
  }

  cargoflux.hideMapBox = function (_class, left, top) {
    cargoflux._isShowingMapBox = false;
    var $map = $('#map');
    $map.css('top', -10000);
    $('.' + _class).text('Show Route');
  }

  cargoflux.showMapBox = function (_class, left, top) {
    cargoflux._isShowingMapBox = true;
    var $routeLink = $('.' + _class);
    var offset = $routeLink.offset();
    var $map = $('#map');

    $map
      .show()
      .css('left', offset.left - left)
      .css('top', offset.top - top - 5);

    $routeLink.text('Hide Route');
  }

  cargoflux.resetMap();
  cargoflux.hideMapSection();
  $('#map').css('top', -1000);

  // Listen on field input
  var selectors = ["input[name*='sender_attributes']", "input[name*='recipient_attributes']"];
  selectors.forEach(function(selector) {
    $(selector).on('input', cargoflux.resetMap);
  });

  // Listen on dropdown change
  selectors = ["select[name*='sender_attributes']", "select[name*='recipient_attributes']"];
  selectors.forEach(function(selector) {
    $(selector).on('change', cargoflux.resetMap);
  });

  // Close and reset map on escape press
  $(document).on('keydown', function (event) {
    if (event.which === ESCAPE_KEY) {
      cargoflux.resetMap();
    }
  })

});
