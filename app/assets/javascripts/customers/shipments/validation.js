$(function() {

  // Define namespace if non-existant
  if (typeof cargoflux === 'undefined') {
    cargoflux = new Object();
  }

  var Regex = {
    email: /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/,
    phoneNumber: /^\+?\d+$/,
    timeHHMM: /^\d\d:\d\d$/
  };

  var Schema = {
    // sender
    'shipment[sender_attributes][company_name]': {
      maxLength: 50,
      required: true
    },
    'shipment[sender_attributes][attention]': {
      maxLength: 50,
      required: false
    },
    'shipment[sender_attributes][address_line1]': {
      maxLength: 30,
      required: true,
    },
    'shipment[sender_attributes][address_line2]': {
      maxLength: 30,
      required: false,
    },
    'shipment[sender_attributes][address_line3]': {
      maxLength: 30,
      required: false,
    },
    'shipment[sender_attributes][zip_code]': {
      maxLength: 9,
      required: false,
    },
    'shipment[sender_attributes][city]': {
      maxLength: 30,
      required: true,
    },
    'shipment[sender_attributes][country_code]': {
      maxLength: 10,
      required: true,
    },
    'shipment[sender_attributes][state_code]': {
      maxLength: 10,
      required: false,
    },
    'shipment[sender_attributes][phone_number]': {
      maxLength: 30,
      required: false,
      regex: Regex.phoneNumber,
      text: 'Phone number not formatted properly'
    },
    'shipment[sender_attributes][email]': {
      maxLength: 50,
      required: false,
      regex: Regex.email,
      text: 'Email not formatted properly'
    },

    // recipient
    'shipment[recipient_attributes][company_name]': {
      maxLength: 50,
      required: true,
    },
    'shipment[recipient_attributes][attention]': {
      maxLength: 50,
      required: true,
    },
    'shipment[recipient_attributes][address_line1]': {
      maxLength: 30,
      required: true,
    },
    'shipment[recipient_attributes][address_line2]': {
      maxLength: 30,
      required: false,
    },
    'shipment[recipient_attributes][address_line3]': {
      maxLength: 30,
      required: false,
    },
    'shipment[recipient_attributes][zip_code]': {
      maxLength: 9,
      required: false
    },
    'shipment[recipient_attributes][city]': {
      maxLength: 30,
      required: true,
    },
    'shipment[recipient_attributes][country_code]': {
      maxLength: 10,
      required: true,
    },
    'shipment[recipient_attributes][state_code]': {
      maxLength: 10,
      required: false,
    },
    'shipment[recipient_attributes][phone_number]': {
      maxLength: 30,
      required: false,
      regex: Regex.phoneNumber,
      text: 'Phone number not formated properly'
    },
    'shipment[recipient_attributes][email]': {
      maxLength: 50,
      required: false,
      regex: Regex.email,
      text: 'Email not formatted properly'
    },

    // shipment
    'shipment[description]': {
      maxLength: 30,
      required: false,
    },
    'shipment[customer_id]': {
      required: true,
    },
    'shipment[reference]': {
      maxLength: 18,
      required: false,
     },
     'shipment[remarks]': {
      required: false,
     }
   };

   var PickupSchema = {
     "shipment[pickup_options][from_time]": {
       regex: Regex.timeHHMM,
       text: 'Time not formatted properly (example 13:00)',
       required: true,
     },
     "shipment[pickup_options][to_time]": {
       regex: Regex.timeHHMM,
       text: 'Time not formatted properly (example 13:00)',
       required: true,
     },
     "shipment[pickup_options][contact_attributes][attention]": {
       maxLength: 22, // Limit for UPS PickupAddress/ContactName
       required: true,
     },
     "shipment[pickup_options][contact_attributes][company_name]": {
       maxLength: 27, // Limit for UPS PickupAddress/CompanyName
       required: true,
     },
     "shipment[pickup_options][description]": {
       maxLength: 11, // Limit for UPS PickupAddress/PickupPoint
       required: false,
     },
   };

  /* Listen on form submission and validate form
   */
  $('.validate-form').on('click', function(event) {
    event.preventDefault();
    var errors = cargoflux.validateForm();
    if (typeof errors === 'object') {
      var firstError = errors[0];
      var position   = firstError.topOffset - 50;

      $("html, body").animate({ scrollTop: position }, 'fast');
      return;
    }
    window.SubmitShipmentForm();
  });

  /* Listen for changes on fields marked for validation
   */
  $('.validate input, input.validate, textarea.validate, .validate select').on('input', function() {
    clearError(this);

    var name  = $(this).attr('name');
    var value = $(this).val();
    var schema = getSchemaForInput(name);

    if (value == undefined) {
      console.log('Field value is null [' + name + ']');
      return true;
    }

    if (schema[name] === undefined) {
      console.log('Field not specified in \'options\' [' + name + ']');
      return true;
    }

    var result = validateInput(name, value, schema);
    var error  = result.error;

    if (error) {
      showError(this, error);
    }

  });

  /* If valid returns true, else return an array of errors with their y-axis offset
   */
  cargoflux.validateForm = function() {
    var errors = [];

    $('.validate input, input.validate, textarea.validate, .validate select').each(function() {
      var name  = $(this).attr('name');
      var value = $(this).val();
      var schema = getSchemaForInput(name);

      if (value == undefined) {
        console.log('Field value is null [' + name + ']');
        return true; // same as 'continue', but required for $.each
      }

      if (schema[name] === undefined) {
        console.log('Field not specified in \'options\' [' + name + ']');
        return true; // same as 'continue', but required for $.each
      }

      var result = validateInput(name, value, schema);
      var error  = result.error;

      if (error !== undefined) {
        clearError(this);
        showError(this, error);

        errors.push({
          error: error,
          topOffset: $(this).offset().top
        });
      }
    });
    var valid = errors.length === 0;

    return valid ? true : errors;
  };

  /* Sets invalid class and appends error text to element
   */
  function showError(element, error) {
    $(element).addClass('invalid')
      .parent().addClass('field_with_errors')
      .append("<span class='error'>" + error + '</span>');
  }

  /* Clears invalid class and removes error text from element
   */
  function clearError(element) {
    $(element).parent()
      .removeClass('field_with_errors')
      .find('.error')
      .remove()
      .removeClass('invalid');
  }

  function getSchemaForInput(name) {
    if ($("input[name='shipment[request_pickup]']").is(":checked") && PickupSchema[name] !== undefined) {
      return PickupSchema;
    }

    return Schema;
  }

  /* Validates a single input field
   */
  function validateInput(name, value, schema) {
    try {
      options = getFieldOptions(name, schema);

      if (options !== undefined) {
        validatePresence(value, options);
        validateLength(value, options);
        validateRegex(value, options);
      }
    }
    catch (error) {
      return {
        field: name,
        error: error
      };
    }
    return true;
  }

  /* Validation helpers
   */

  function validatePresence(value, options) {
    if (options.required && isBlank(value)) {
      throw 'Field is required';
    }
  }

  function validateLength(value, options) {
    var maxLength = options.maxLength;
    if (maxLength && value.length > maxLength) {
      throw 'Field cannot exceed ' + maxLength + ' characters';
    }
  }

  function validateRegex(value, options) {
    var defaultText = options.text;
    var regex = options.regex;
    value = value.replace(/ /g,'');

    if (regex && value.length > 0 && !regex.test(value)) {
      throw defaultText || 'Field not formatted properly';
    }
  }

  /* Checks if the specified name exists in the validation object, return it if it does
   */
  function getFieldOptions(name, options) {
    options = options[name];
    if (options === undefined) {
      throw 'Field not specified in \'options\' [' + name + ']';
    }
    return options;
  }

  /* Helpers
   */

  function isBlank(str) {
    return (!str || /^\s*$/.test(str));
  }

});
