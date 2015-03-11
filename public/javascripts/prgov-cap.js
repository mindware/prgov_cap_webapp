function switchLanguage(value) {
  if(value == "en" || value == "es") {
    // Set the language. The only thing we use cookies for, and
    // let it live for a while.
    $.cookie('locale', value, { expires: 365 });
    // reload the page
    location.reload();
  }
}
