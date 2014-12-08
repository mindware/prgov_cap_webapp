// Method that activates a form
function activate_form(active, previous) {
  // Find the current active class:
  // make it invisible
  console.log("Requesting to activate "+ active +" form. Replacing "+ previous +" form.");
  // Make the old form hidden.
  $("#"+ previous +"").addClass("hidden");
  // Find the specified form and make it visible
  // by removing the hidden class
  $("#"+ active +"").removeClass("hidden");
}

function submit_active() {
  alert("The form that would be submitted would be "+ active_option())
  $("#"+ active_option() +"").submit();
}

// Returns the name of the current selected form
// the value of the option and the name of the form
// must match
function active_option() {
  return $("#option option:selected").val();
}


// This method adds on change events to the document
// ready defined in our main forms javascript file.
function early_checks() {
  // monitor any changes to the options menu
  option_check();
  // monitor if a user clicks on the continue button
  continue_check();
}

function option_check () {
    var selection = $("#option");
    selection.data("previous", active_option());
    // Store the value of the current option on change:
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

function continue_check () {
    var button = $("#continue");
    //
    button.click(function() {
      submit_active();
    });
}
