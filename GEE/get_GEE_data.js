// Setup
var s2mask = require('users/fitoprincipe/geetools:cloud_masks').sentinel2;
var cloud_threshold = 80; // Filter image from collection to have cloud less than 80 percent
var rgb_threshold = 0.23; // Cut-off, Probably unmasked cloud
var rgb_percentile = 35; // Select RGB at 35th percentile
var ndvi_percentile = 90; // Select NDVI at 90th percentile

// Define helpers
function get_collection(start_date, end_date) {  
    var collection = ee.ImageCollection("COPERNICUS/S2")
        .filterDate(start_date, end_date)
        .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', cloud_threshold))
        .map(s2mask())
        .map(function (image) {
            return image.divide(10000);
        });
    return collection.map(function(image) {
        var ndvi = image.normalizedDifference(['B8', 'B4']).rename('NDVI');
        image = image.addBands(ndvi.toFloat());
        return image.toFloat();
    })
}

function get_final(collection) {
    var final = collection.max(); // Baseline value
    // Select value
    collection = collection.map(function(img) {
        return img.updateMask(
            img.select("B2").lt(rgb_threshold)
            .bitwiseAnd(img.select("B3").lt(rgb_threshold))
            .bitwiseAnd(img.select("B4").lt(rgb_threshold)))
    });
    var rgb_p = collection.select(["B2", "B3", "B4"])
                              .reduce(ee.Reducer.percentile([rgb_percentile]))
    rgb_p = rgb_p.select([
                            "B2_p" + rgb_percentile,
                            "B3_p" + rgb_percentile,
                            "B4_p" + rgb_percentile,
                        ], ["B2", "B3", "B4"])
    var ndvi_p = collection.select(["NDVI"])
                                .reduce(ee.Reducer.percentile([ndvi_percentile]))
                                .select([
                                    "NDVI_p" + ndvi_percentile
                                ], ["NDVI"])
    // Replace old bands
    final = final.addBands({
        srcImg: rgb_p.select("B2").toFloat().rename("B2"),
        overwrite: true
    });
    final = final.addBands({
        srcImg: rgb_p.select("B3").toFloat().rename("B3"),
        overwrite: true
    });
    final = final.addBands({
        srcImg: rgb_p.select("B4").toFloat().rename("B4"),
        overwrite: true
    });
    final = final.addBands({
        srcImg: ndvi_p.select("NDVI").toFloat().rename("NDVI"),
        overwrite: true
    });
    return final.toFloat();
}

// area of interest
var geometry = ee.Geometry.Rectangle([[0, 0],[ 700000, 1300000]],'EPSG:27700',true,false);
//Map.addLayer(geometry, {palette: 'FF0000'}, "Study Area");

// Operation
var collection = get_collection("2019-01-01", "2020-01-01");
var final = get_final(collection).toFloat().reproject({crs: 'EPSG:27700',scale: 100}).clip(geometry);

// export
var projection = final.select('NDVI').projection().getInfo();

var selected_layers = final.select(["B4", "B3", "B2", "NDVI"]);
//took about 30 mins to do 1 band at scale:1000
Export.image.toDrive({
  image: selected_layers,
  folder: "GEE",
  description: 'sentinel2_bands',
  crs: projection.crs,
  scale: 100
});



// Visualize
Map.addLayer(final.select(["B4", "B3", "B2"]), {
    min: 0,
    max: 0.3
}, "RGB");
// Map.addLayer(final.select(["NDVI"]), {
//     min: -1,
//     max: 1,
//     palette: ['blue', 'white', 'green']
// }, "NDVI");

