import { d3 } from 'shared'

export const punchcard = (context, data, options = {}) => {
	// Markup has already a svg inside
	if ($(`${context} svg`).length !== 0) return

  // options
  let itemHeight = options.itemHeight || 50
  let gutter = options.gutter || 20
  let margin = options.margins || {
    top: gutter * 1.5,
    right: gutter,
    bottom: gutter * 1.5,
    left: gutter * 15
  }
  let xTickFormat = options.xTickFormat || (d => d)
  let yTickFormat = options.yTickFormat || (d => d)
  let title = options.title || ''

  // parse dates
  data.forEach((element, elementIndex) => {
    for (var dateIndex = 0; dateIndex < element.value.length; dateIndex++) {
      let dateString = element.value[dateIndex].key
      data[elementIndex].value[dateIndex].key = new Date(dateString)
    }
  })

  // dimensions
  let container = d3.select(context)
  let width = +container.node().getBoundingClientRect().width - margin.left - margin.right
  let height = (data.length * itemHeight) + margin.top + margin.bottom
  let svg = container.append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)

  // scales
  let x = d3.scaleTime().range([0, width]);
  let y = d3.scalePoint().range([height, 0]);
  let r = d3.scaleSqrt().range([1, 15]) // tamaño de las bolas

  // domains
  x.domain([
    d3.min(data.map(d => d3.min(d.value.map(v => v.key)))),
    d3.max(data.map(d => d3.max(d.value.map(v => v.key))))
  ]);
  y.domain(data.map(d => d.key)).padding(1);

  // chart title
  if (title) {
    svg.append("text")
      .attr("x", 0)
      .attr("y", (margin.top / 3) + (itemHeight / 2))
      .attr("class", "title")
      .attr("text-anchor", "start")
      .text(title);
  }

	let g = svg.append("g")
		.attr("transform", "translate(" + margin.left + "," + margin.top + ")")

	// Custom X-axis
	function xAxis(g) {
		g.call(d3.axisTop(x).ticks(d3.timeMonth.every(1)).tickSizeOuter(0).tickSizeInner(0).tickFormat(xTickFormat))
		g.selectAll(".domain").remove()
		g.selectAll(".tick line")
			.attr("y1", itemHeight / 2)
			.attr("y2", height - (itemHeight / 4))
		g.selectAll(".tick text")
			.attr("y", (-margin.top / 1.5) + (itemHeight / 2))
	}

	// Custom Y-axis
	function yAxis(g) {
		g.call(d3.axisLeft(y).tickSizeOuter(0).tickSizeInner(0).tickFormat(yTickFormat))
		g.selectAll(".domain").remove()
		g.selectAll(".tick")
			.on("click", function (d,i) {
				document.location.href = (data[i].properties || {}).url
			})
	}

	// axis
	g.append("g")
		.attr("class", "x axis")
		.call(xAxis)

	g.append("g")
		.attr("class", "y axis")
		.attr("transform", "translate(" + (-margin.left + gutter) + ",0)")
		.call(yAxis)

	// tooltip
	let tooltip = container.append("div")
		.attr("id", `${container.node().id}-tooltip`)
		.attr("class", "graph-tooltip")

  // circles
  for (var i = 0; i < data.length; i++) {

    svg.append("rect")
      .attr("x", 0)
      .attr("y", y(data[i].key) + margin.top - (itemHeight / 2))
      .attr("rx", 6)
      .attr("ry", 6)
      .attr("width", +container.node().getBoundingClientRect().width)
      .attr("height", itemHeight);

    let g = svg.append("g")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")")

    r.domain([
      d3.min(data[i].value, d => d.value),
      d3.max(data[i].value, d => d.value)
    ]);

    g.selectAll("circle")
      .data(data[i].value)
      .enter()
			.append("a")
			.attr("xlink:href", d => (d.properties || {}).url)
      .append("circle")
      .attr("class", "circle")
      .attr("cx", d => x(d.key))
      .attr("cy", () => y(data[i].key))
			.on("mousemove", function(d, j, arr) {
				let content = `
					<div class="tooltip-content bottom">
						${d.value.toLocaleString()}
					</div>`

				tooltip
					.style("opacity", "1")
					.style("left", `${x(d.key) + margin.left}px`)
					.style("top", `${d3.select(arr[j]).attr("cy")}px`)
					.html(content);
			})
			.on("mouseout", () => tooltip.style("opacity", "0"))
      .transition()
      .duration(800)
      .attr("r", d => r(d.value));
  }
};
