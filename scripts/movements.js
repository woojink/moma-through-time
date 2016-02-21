// Set margins for each graph portion
var margin = {
  'top': 30,
  'right': 0,
  'bottom': 25,
  'left': 200
};

// Set dimensions
var svg_width=1500,
  svg_height=600,
  width = svg_width - (margin.left + margin.right),
  height = svg_height - (margin.top + margin.bottom);

var grid_size = Math.floor(width / 61);

// Append SVGs
var svg = d3.select("#chart1")
  .append('svg')
  .attr("viewBox", "0 0 " + svg_width + " " + svg_height)
  .style("max-width", svg_width + "px")
  .attr("preserveAspectRatio", "xMidYMid meet");

var map = svg.append("g")
  .attr('transform', "translate(" + margin.left + ", " + margin.top + ")");

queue()
.defer(d3.csv, "data/artists_movements.csv")
.await(function(error, data) {  
  var artists = d3.nest()
    .key(function(d){ return d.DisplayName; })
    .entries(data);

  artist_list = []
  artists.forEach(function(d,i){
    d['LifetimeExhibitionLength'] = d.values[0]['LifetimeExhibitionLength'];
    d['Movement'] = d.values[0]['Movement'];
    artist_list[i] = d.values[0]['DisplayName'];
  });

  var max_count = d3.max(data, function(d){ return +d.count; }),
      color_scale = d3.scale.linear().domain([0, max_count]).range(['#ffffff','#7f0000']),
      color_scale_days = d3.scale.linear().domain([0, 16869]).range(['#ffffff','#7f0000']),
      color_scale_movement = d3.scale.category20(),
      opacity_scale = d3.scale.pow().exponent(2).domain([0, 5]).range([0.0, 1]),
      opacity_scale2 = d3.scale.pow().exponent(2).domain([0, 16869]).range([0.3, 1]),
      x_scale = d3.scale.linear().domain([1929, 1989]).range([0, 61*grid_size]),
      x_scale_days = d3.scale.linear().domain([0, 16869]).range([0, 61*grid_size]),
      y_scale = d3.scale.ordinal().domain(artist_list).rangeBands([0, height], 0.7, 0);

  var x_axis = d3.svg.axis()
    .scale(x_scale)
    .orient("top")
    .tickFormat(d3.format('d'));
  var x_axis_days = d3.svg.axis()
    .scale(x_scale_days)
    .orient("top")
    .tickFormat(d3.format('d'));
  var y_axis = d3.svg.axis()
    .scale(y_scale)
    .orient('left');
  map.append('g')
    .attr('class', 'axis')
    .call(y_axis)
    .attr('transform', 'translate(-3, 0)');
  var x_axis_g = map.append('g')
    .attr('class', 'axis')
    .attr('id', 'x-axis-years')

  function show_by_years(){
    x_axis_g
      .call(x_axis)
      .attr('transform', 'translate('+ (grid_size/2+1) +', 0)');

    artist_level = map.selectAll('.artist')
      .data(artists)
      .enter()
      .append('g')
      .selectAll('rect')
      .data(function(d){ return d.values; })
      .enter()
      .append('rect')
      .attr('class', 'by-years-chart')
      .attr('width', grid_size*.7)
      .attr('height', grid_size*.7)
      .attr('x', function(d){
        return x_scale(d.StartYear);
      })
      .attr('y', function(d){
        return y_scale(d.DisplayName)
      })
      .style('fill', function(d){
        return color_scale_movement(d.Movement);
      })
      .style('opacity', function(d){
        return opacity_scale(d.count);
      })
      .on('mouseover', function(d){
        d3.select('#tt1')
          .style('visibility','visible')
          .style('top', d3.event.pageY+10 + 'px')
          .style('left', d3.event.pageX+10 + 'px')
          .html('<strong>'+d.DisplayName+'</strong><br>'+d.count+' exhibit(s) in ' + d.StartYear + 
            '<br>' + d.Movement)
          .transition().style('opacity', .9);
      })
      .on('mouseout', function(d){
        d3.select('#tt1')
          .style('visibility','hidden')
          .transition().style('opacity', 0);
      });
  };
  function show_by_days(){
    x_axis_g
      .call(x_axis_days)
      .attr('transform', 'translate(0, 0)');

    artist_level = map.selectAll('.artist')
      .data(artists)
      .enter()
      .append('rect')
      .attr('class', 'by-days-chart')
      .attr('width', function(d){
        return x_scale_days(d.LifetimeExhibitionLength);
      })
      .attr('height', grid_size*.7)
      .attr('x', function(d){
        return 0;
      })
      .attr('y', function(d){
        return y_scale(d.key)
      })
      .style('fill', function(d){
        return color_scale_movement(d.Movement);
      })
      .style('opacity', function(d){
        return opacity_scale2(d.LifetimeExhibitionLength);
      })
      .on('mouseover', function(d){
        d3.select('#tt1')
          .style('visibility','visible')
          .style('top', d3.event.pageY+10 + 'px')
          .style('left', d3.event.pageX+10 + 'px')
          .html('<strong>'+d.key+'</strong><br>'+d.LifetimeExhibitionLength+' days of exhibitions')
          .transition().style('opacity', .9);
      })
      .on('mouseout', function(d){
        d3.select('#tt1')
          .style('visibility','hidden')
          .transition().style('opacity', 0);
      });
    };

    show_by_years();

    d3.select('#days-button')
      .on('click', function(d){
        d3.selectAll('.by-years-chart')
          .style('visibility', 'hidden');
        d3.selectAll('.by-days-chart')
          .style('visibility', 'visible');
        show_by_days();
    });
      
    d3.select('#years-button')
      .on('click', function(d){
        d3.selectAll('.by-days-chart')
          .style('visibility', 'hidden');
        d3.selectAll('.by-years-chart')
          .style('visibility', 'visible');
        show_by_years();
    });
});