$(document).ready(function() {
  // early checks are used to add
  // on change event monitoring
  early_checks();
    $('#birthdate-datetimepicker').datetimepicker({
      pickTime: false
    });
});

// Useful JS methods for form1 - Andrés
// This method adds on change events to the document
// ready defined in our main forms javascript file.
function early_checks() {
  // monitor any changes to the options menu
  option_check();
  // monitor if a user clicks on the continue button
  continue_check();
  // on this multi-form page, lets allow users to
  // hit enter to submit the current form.
  press_enter_check();
}

// Method that activates a form
function activate_form(active, previous) {
  // Find the current active class:
  // make it invisible
  // console.log("Requesting to activate "+ active +" form. Replacing "+ previous +" form.");
  $("#"+ active +"").removeClass("hidden");
  // Find the specified form and make it visible
  // by removing the hidden class. We check to see
  // if active and previous are the same, which means
  // this is the first time reloading the page.
  if(active != previous) {
    // Make the old form hidden.
    $("#"+ previous +"").addClass("hidden");
  }
}

function submit_active() {
  console.log("The form that would be submitted would be "+ active_option())
  $("#"+ active_option() +"").submit();
}

// Returns the name of the current selected form
// the value of the option and the name of the form
// must match
function active_option() {
  return $("#option option:selected").val();
}

// Returns a list of the values of
// a dropdown selection menu.
function inactive_options(id) {
    var options = [];
    $(""+ id +" option:not(:selected)").each(function()
    {
        // append the names of the options to the array
        options[options.length] = $(this).val()
    });
    return options;
}

// This method hides all unselected forms.
function hide_unselected_forms(selection) {
  var options = inactive_options(selection);
  console.log("we're looking at "+ options)
  $.each(options, function(index, value)
  {
      console.log("value is "+ value);
      // Hide all unselected forms that are
      // missing the 'hidden' class.
      if(!$("#"+ value).hasClass("hidden")) {
          console.log("Hiding #"+ value);
          $("#"+ value).addClass("hidden");
      }
  });
}

// Detects if someone selects a new form
function option_check () {
    // get a jquery reference to selection menu
    var selection = $("#option");
    // get the id of the current selected form
    var active = active_option();
    // Store using jquery data, the current active
    // form's id for future reference.
    selection.data("previous", active);
    // When runing for the first time, always
    // clean up everything but the current active
    // option.
    hide_unselected_forms("#option");
    // Now show the active form at runtime.
    $("#"+active).removeClass("hidden");
    console.log("we should be showing "+ active);

    // Now let's add a monitor so that when things
    // change, we can update the forms accordingly:
    selection.change(function(data) {
      var _selection = $(this);
      var active = active_option();
      // now active the form based on the current and previous values
      activate_form(active, _selection.data("previous"));
      // update the new selection as the previous selection for
      // future selections.
      _selection.data("previous",active);
    });
}

// When hitting continue, activates
// the proper form.
function continue_check () {
    var button = $("#continue");
    //
    button.click(function() {
      submit_active();
    });
}

// Detects if instead of clicking the person
// hits enter on a field of the form.
function press_enter_check() {
  $("input[type=text]") // retrieve all inputs
    .keydown(function(e) { // bind keydown on all inputs
        if (e.keyCode == 13) // enter was pressed
            $(this).closest("form").submit(); // submit the current form
    });
}
