(function() {
  if (typeof window.d3 === "undefined") {
    return;
  }
  
  var chartSelector = "#dashboard_chart";
  var chartLabelsSelector = "#dashboard_chart_container .chart_labels"
  var parseDate = d3.timeParse("%Y-%m-%d");
  var formatMonth = d3.timeFormat("%b %y");
  var formatYValue = d3.format(".2s");

  var colorArray = d3.schemeCategory10.slice();
  colorArray[2] = colorArray[0]; // This 2-th second color is almost green so we'll use the 0-th one instead
  colorArray[0] = "#50d991"; // The first color will be overridden to be Cargoflux-green

  var x = d3.scaleTime();
  var y = d3.scaleLinear();
  var colors = d3.scaleOrdinal(colorArray);
  var zoom = d3.zoom().scaleExtent([1, 1]);
  var line = d3.line().x(function(d) { return x(d.date) }).y(function(d) { return y(d.value) });
  var area = d3.area().x(function(d) { return x(d.date) }).y1(function(d) { return y(d.value) });
  var xAxisLabelsGroup = null;
  var yAxisLinesGroup = null;
  var chartAreasGroup = null;
  var chartPathsGroup = null;
  var allPointsGroup = null;
  var yAxisBgShadow = null;
  var yAxisBg = null;
  var yAxisLabelsGroup = null;
  var initialized = false;

  var updateChart = function(lines, transition) {
    var chart = d3.select(chartSelector);
    var width = $(chartSelector).width();
    var height = $(chartSelector).height();
    var chartLines = lines.map(function(line) {
      return {
        label: line["label"] || null,
        points: line.points.map(function(point) {
          return { date: parseDate(point.timestamp), value: point.value };
        }),
      };
    });

    var x0 = 90;
    var x1 = width - 30;

    var xdMax = chartLines.length > 0 ? d3.max(chartLines[0].points, function(d) { return d.date }) : 0;
    var xdMin = chartLines.length > 0 ? d3.min(chartLines[0].points, function(d) { return d.date }) : 0;
    var xdMax1YearAgo = new Date(xdMax);
    xdMax1YearAgo.setFullYear(xdMax1YearAgo.getFullYear() - 1);
    var xd0 = Math.max(xdMin, xdMax1YearAgo);
    var xd1 = xdMax;

    var y0 = height - 30;
    var y1 = 20;

    x.range([x0, x1]).domain([xd0, xd1]);
    y.range([y0, y1]);
    y.domain([
      d3.min(chartLines, function(c) { return d3.min(c.points, function(d) { return d.value; }); }),
      d3.max(chartLines, function(c) { return d3.max(c.points, function(d) { return d.value; }); }),
    ]);

    var xTicks = (chartLines.length > 0 ? chartLines[0].points : []).map(function(d) { return d.date });
    var yTicks = y.ticks(5);

    zoom.translateExtent([[x(xdMin) - 90, 0], [x(xdMax) + 30, height]]);

    var chartLabels = d3.select(chartLabelsSelector).selectAll("div.chart_label").data(chartLines.length > 1 ? chartLines : []);
    var chartLabelsEnter = chartLabels.enter().append("div").attr("class", "chart_label");
    chartLabels.exit().remove();
    chartLabelsEnter.append("div").attr("class", "chart_color");
    chartLabelsEnter.append("div").attr("class", "chart_text_label");

    chartLabels.merge(chartLabelsEnter)
      .select(".chart_color").style("background-color", function(c, i) { return colors(i) });

    chartLabels.merge(chartLabelsEnter)
      .select(".chart_text_label").text(function(c) { return c.label });

    if (!xAxisLabelsGroup) {
      xAxisLabelsGroup = chart.append("g")
        .attr("class", "x-axis-labels")
        .attr("fill", "#0b1338")
        .attr("font-size", 12)
        .attr("text-anchor", "middle");
    }

    var xAxisLabels = xAxisLabelsGroup.selectAll("text").data(xTicks);
    xAxisLabels.enter().append("text")
      .attr("y", height - 10)
      .merge(xAxisLabels)
      .attr("x", function(d) { return x(d) })
      .text(function(d) { return formatMonth(d) })
    xAxisLabels.exit().remove();

    if (!yAxisLinesGroup) {
      yAxisLinesGroup = chart.append("g")
        .attr("class", "y-axis-lines")
        .attr("stroke-width", 1)
        .attr("stroke", "#eeeeee");
    }

    var yAxisLines = yAxisLinesGroup.selectAll("line").data(yTicks);
    yAxisLines.enter().append("line")
      .attr("x1", 0)
      .attr("x2", "100%")
      .merge(yAxisLines)
      .attr("y1", function(d) { return y(d) })
      .attr("y2", function(d) { return y(d) })
    yAxisLines.exit().remove();

    if (!chartAreasGroup) {
      chartAreasGroup = chart.append("g");
    }

    area.y0(y0);
    var chartAreas = chartAreasGroup.selectAll("path.chart_area").data(chartLines);
    (transition ? chartAreas.transition() : chartAreas).attr("d", function(d) { return area(d.points) });
    chartAreas.enter().append("path")
      .attr("class", "chart_area")
      .attr("fill", function(d, i) { return colors(i) })
      .attr("fill-opacity", 0.4)
      .attr("stroke-width", 0)
      .attr("d", function(d) { return area(d.points) });
    chartAreas.exit().remove();

    if (!chartPathsGroup) {
      chartPathsGroup = chart.append("g");
    }

    var chartPaths = chartPathsGroup.selectAll("path.chart").data(chartLines);
    (transition ? chartPaths.transition() : chartPaths).attr("d", function(d) { return line(d.points) });
    chartPaths.enter().append("path")
      .attr("class", "chart")
      .attr("fill", "none")
      .attr("stroke", function(d, i) { return colors(i) })
      .attr("stroke-width", 2)
      .attr("d", function(d) { return line(d.points) });
    chartPaths.exit().remove();

    if (!allPointsGroup) {
      allPointsGroup = chart.append("g");
    }

    var chartPointsGroups = allPointsGroup.selectAll("g.points").data(chartLines);
    var chartPointsGroups_ = chartPointsGroups.enter().append("g")
      .attr("class", "points")
      .attr("fill", function(d, i) { return colors(i) })
      .merge(chartPointsGroups);
    chartPointsGroups.exit().remove();

    var chartPoints = chartPointsGroups_.selectAll("circle").data(function(d) { return d.points });
    (transition ? chartPoints.transition() : chartPoints).attr("cx", function(d) { return x(d.date) }).attr("cy", function(d) { return y(d.value) });
    chartPoints.enter().append("circle")
      .attr("r", 6)
      .attr("cx", function(d) { return x(d.date) })
      .attr("cy", function(d) { return y(d.value) });
    chartPoints.exit().remove();

    if (!yAxisBgShadow) {
      yAxisBgShadow = chart.append("rect")
        .attr("x", 60)
        .attr("y", 0)
        .attr("width", 1)
        .attr("height", "100%")
        .attr("fill", "#0b1338");
    }

    if (!yAxisBg) {
      yAxisBg = chart.append("rect")
        .attr("x", 0)
        .attr("y", 0)
        .attr("width", 60)
        .attr("height", "100%")
        .attr("fill", "#ffffff");
    }

    if (!yAxisLabelsGroup) {
      yAxisLabelsGroup = chart.append("g")
        .attr("class", "y-axis-labels")
        .attr("fill", "#444444")
        .attr("font-size", 12)
        .attr("text-anchor", "end")
        .attr("dominant-baseline", "middle");
    }

    var yAxisLabels = yAxisLabelsGroup.selectAll("text").data(yTicks);
    yAxisLabels.enter().append("text")
      .attr("x", 50)
      .merge(yAxisLabels)
      .attr("y", function(d) { return y(d) })
      .text(function(d) { return formatYValue(d) });
    yAxisLabels.exit().remove();

    if (!initialized) {
      chart.call(zoom);

      zoom.on("zoom", function zoomed() {
        xAxisLabelsGroup.attr("transform", d3.event.transform);
        chartPathsGroup.attr("transform", d3.event.transform);
        chartAreasGroup.attr("transform", d3.event.transform);
        allPointsGroup.attr("transform", d3.event.transform);
      });

      initialized = true;
    }
  };

  $(document).on("dashboard_chart:update", chartSelector, function(event, lines) {
    updateChart(lines, true);
  });

  $(document).on("dashboard_chart:reset_and_update", chartSelector, function(event, lines) {
    var chart = d3.select(chartSelector);
    chart.call(zoom.transform, d3.zoomIdentity);

    updateChart(lines, false);
  });
})();
