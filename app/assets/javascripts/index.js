$(document).on('change', '.filter-status', function (e) {
    var data = $(this).closest('form').serialize();

    $('.search-result').load(
      '/?' + data + ' .search-result > *'
    );

    history.pushState(null, null, '/?' + data);


    e.preventDefault();
});

$(function  () {
  $('#price_range').slider({
    formatter: function(value) {
      // return value + '%';
      if ( value == '1' ) return '$';
      if ( value == '2' ) return '$$';
      if ( value == '3' ) return '$$$';
      if ( value == '4' ) return '$$$$';
    }
  });
})
