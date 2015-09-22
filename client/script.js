
var width = 960,
    height = 960,
    speed = -1e-2,
    start = Date.now();

var sphere = {type: "Sphere"};

var projection = d3.geo.orthographic()
    .scale(width / 2.1)
    .translate([width / 2, height / 2])
    .precision(.5);

var graticule = d3.geo.graticule();

var canvas = d3.select("body").append("canvas")
    .attr("width", width)
    .attr("height", height);

var context = canvas.node().getContext("2d");

var path = d3.geo.path()
    .projection(projection)
    .context(context);

var g = canvas.append('g')

d3.json("us.json", function(error, topo) {
  if (error) throw error;
  data = [51.5033630,-0.1276250]

  var land = topojson.feature(topo, topo.objects.land),
      grid = graticule();

  d3.timer(function() {
    context.clearRect(0, 0, width, height);

    projection.rotate([speed * (Date.now() - start), -15]).clipAngle(90);

    context.beginPath();
    path(sphere);
    context.lineWidth = 3;
    context.strokeStyle = "#000";
    context.stroke();
    context.fillStyle = "#fff";
    context.fill();

    projection.clipAngle(180);

    context.beginPath();
    path(land);
    context.fillStyle = "#dadac4";
    context.fill();

    context.beginPath();
    path(grid);
    context.lineWidth = .5;
    context.strokeStyle = "rgba(119,119,119,.5)";
    context.stroke();

    projection.clipAngle(90);

    context.beginPath();
    path(land);
    context.fillStyle = "#737368";
    context.fill();
    context.lineWidth = .5;
    context.strokeStyle = "#000";
    context.stroke();
  });
});

d3.select(self.frameElement).style("height", height + "px");









// <!-- <canvas id="canvas"></canvas> -->
<!--     // <script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.2.10/angular.min.js"></script>
    // <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.5/d3.min.js"></script>
    // <script src="https://cdnjs.cloudflare.com/ajax/libs/topojson/1.6.19/topojson.min.js"></script> -->
  <!-- // <script type="text/javascript" src="script.js"></script> -->