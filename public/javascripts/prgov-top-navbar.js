
(function() {
  var newbgt = document.createElement('div');
  newbgt.id = "prTopBanner";
  newbgt.style.width = "100%";
  newbgt.style.margin = "0 auto 5px auto";
  newbgt.className = "prTopBanner";

  var bg = document.createElement('script');
  bg.type = 'text/javascript'; bg.async = true;
  bg.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www2') + '.pr.gov/scripts/prGovTopBanner.js';

  var s = document.getElementById('tbs');
  s.parentNode.insertBefore(bg, s);
  s.parentNode.insertBefore(newbgt,s);

})();
