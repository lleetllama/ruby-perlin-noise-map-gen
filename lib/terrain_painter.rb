require 'chunky_png'
require 'pry'

require './lib/color_blender'

class TerrainPainter
  class << self



    # Paints terrain based on height and temperature maps
    def paint_terrain(height_map, temperature_map, output_filename)
      # Load the height map and temperature map PNG files
      height_image = ChunkyPNG::Image.from_file(height_map)
      temperature_image = ChunkyPNG::Image.from_file(temperature_map)


      @height_codes = []
      @temperature_codes = []

      # Get the dimensions of the images
      width = height_image.width
      height = height_image.height

      # Create a new image with the same dimensions
      painted_image = ChunkyPNG::Image.new(width, height)

      # Iterate over each pixel in the height and temperature maps
      height.times do |y|
        width.times do |x|
          # Get height value from the height map

          pixel_value = height_image[x, y]
          hex_value = ChunkyPNG::Color.to_hex(pixel_value)

          height_value = height_to_value(hex_value)
          @height_codes << hex_value


          temperature_value = temperature_image[x, y]
          temperature_hex = ChunkyPNG::Color.to_hex(temperature_value)

          # Get temperature value from the temperature map
          temperature_value = temperature_to_value(temperature_hex)
          @temperature_codes << temperature_hex

          # Determine the final color based on height and temperature
          final_color = determine_terrain_color(height_value, temperature_value)

          # Set the pixel color in the new image
          painted_image[x, y] = final_color
        end
      end

      # dump the height and temperature codes to a file
      File.open('height_codes.txt', 'w') { |f| f.write(@height_codes.uniq) }
      File.open('temperature_codes.txt', 'w') { |f| f.write(@temperature_codes.uniq) }
      #

      # Save the painted image to a file
      painted_image.save(output_filename)
    end

    private

    HEIGHT_VALUES = {
      '#000000ff' => 1,
      '#1c1c1cff' => 2,
      '#393939ff' => 3,
      '#555555ff' => 4,
      '#717171ff' => 5,
      '#8e8e8eff' => 6,
      '#aaaaaaff' => 7,
      '#c6c6c6ff' => 8,
      '#e3e3e3ff' => 9,
      '#ffffffff' => 10
    }.freeze

    # Convert height map color to height value (1-10)
    def height_to_value(pixel_color)
      HEIGHT_VALUES.fetch(pixel_color, 0)
    end

    TEMPERATURE_VALUES = {
      '#00cdf9ff' => 1,
      '#1ab3a2ff' => 2,
      '#33984bff' => 3,
      '#7c5e3eff' => 4,
      '#c42430ff' => 5
    }.freeze

    # Convert temperature map color to temperature value (1-5)
    def temperature_to_value(pixel_color)
      TEMPERATURE_VALUES.fetch(pixel_color.downcase, 0)
    end

    # Determine the final terrain color based on height and temperature values
    def determine_terrain_color(height_value, temperature_value)
      terrain_color_map[[height_value, temperature_value]] || ChunkyPNG::Color.from_hex('#000000')
    end

    # Build a lookup table of terrain colors keyed by [height, temperature].
    # The color blending is expensive, so memoize the table to avoid
    # recalculating it for every pixel in the map.
    def terrain_color_map
      @terrain_color_map ||= begin
        cold_tint = '#ffffff'
        hot_tint = '#edab50'

        deep_ocean = ColorBlender.exclusive_triple_blend([cold_tint, '#124E89', hot_tint], 1)
        water      = ColorBlender.exclusive_triple_blend([cold_tint, '#0099DB', hot_tint], 1)
        sand       = ColorBlender.exclusive_triple_blend([cold_tint, '#EAD4AA', hot_tint], 1)
        scrub_land = ColorBlender.exclusive_triple_blend([cold_tint, '#B86F50', hot_tint], 1)
        grass_land = ColorBlender.exclusive_triple_blend([cold_tint, '#63C74D', hot_tint], 1)
        forest     = ColorBlender.exclusive_triple_blend([cold_tint, '#3E8948', hot_tint], 1)
        steppe     = ColorBlender.exclusive_triple_blend([cold_tint, '#193C3E', hot_tint], 1)
        cliffs     = ColorBlender.exclusive_triple_blend([cold_tint, '#5A6988', hot_tint], 1)
        mountain   = ColorBlender.exclusive_triple_blend([cold_tint, '#8B9BB4', hot_tint], 1)
        peaks      = ColorBlender.exclusive_triple_blend([cold_tint, '#C0CBDC', hot_tint], 1)

        {
          # Deep Water
          [1, 1] => ChunkyPNG::Color.from_hex(deep_ocean[0]),
          [1, 2] => ChunkyPNG::Color.from_hex(deep_ocean[1]),
          [1, 3] => ChunkyPNG::Color.from_hex(deep_ocean[2]),
          [1, 4] => ChunkyPNG::Color.from_hex(deep_ocean[3]),
          [1, 5] => ChunkyPNG::Color.from_hex(deep_ocean[4]),
          # Water
          [2, 1] => ChunkyPNG::Color.from_hex(water[0]),
          [2, 2] => ChunkyPNG::Color.from_hex(water[1]),
          [2, 3] => ChunkyPNG::Color.from_hex(water[2]),
          [2, 4] => ChunkyPNG::Color.from_hex(water[3]),
          [2, 5] => ChunkyPNG::Color.from_hex(water[4]),
          # Beach
          [3, 1] => ChunkyPNG::Color.from_hex(sand[0]),
          [3, 2] => ChunkyPNG::Color.from_hex(sand[1]),
          [3, 3] => ChunkyPNG::Color.from_hex(sand[2]),
          [3, 4] => ChunkyPNG::Color.from_hex(sand[3]),
          [3, 5] => ChunkyPNG::Color.from_hex(sand[4]),
          # Scrublands
          [4, 1] => ChunkyPNG::Color.from_hex(scrub_land[0]),
          [4, 2] => ChunkyPNG::Color.from_hex(scrub_land[1]),
          [4, 3] => ChunkyPNG::Color.from_hex(scrub_land[2]),
          [4, 4] => ChunkyPNG::Color.from_hex(scrub_land[3]),
          [4, 5] => ChunkyPNG::Color.from_hex(scrub_land[4]),
          # Grassland
          [5, 1] => ChunkyPNG::Color.from_hex(grass_land[0]),
          [5, 2] => ChunkyPNG::Color.from_hex(grass_land[1]),
          [5, 3] => ChunkyPNG::Color.from_hex(grass_land[2]),
          [5, 4] => ChunkyPNG::Color.from_hex(grass_land[3]),
          [5, 5] => ChunkyPNG::Color.from_hex(grass_land[4]),
          # Forest
          [6, 1] => ChunkyPNG::Color.from_hex(forest[0]),
          [6, 2] => ChunkyPNG::Color.from_hex(forest[1]),
          [6, 3] => ChunkyPNG::Color.from_hex(forest[2]),
          [6, 4] => ChunkyPNG::Color.from_hex(forest[3]),
          [6, 5] => ChunkyPNG::Color.from_hex(forest[4]),
          # Steppe
          [7, 1] => ChunkyPNG::Color.from_hex(steppe[0]),
          [7, 2] => ChunkyPNG::Color.from_hex(steppe[1]),
          [7, 3] => ChunkyPNG::Color.from_hex(steppe[2]),
          [7, 4] => ChunkyPNG::Color.from_hex(steppe[3]),
          [7, 5] => ChunkyPNG::Color.from_hex(steppe[4]),
          # Cliffs
          [8, 1] => ChunkyPNG::Color.from_hex(cliffs[0]),
          [8, 2] => ChunkyPNG::Color.from_hex(cliffs[1]),
          [8, 3] => ChunkyPNG::Color.from_hex(cliffs[2]),
          [8, 4] => ChunkyPNG::Color.from_hex(cliffs[3]),
          [8, 5] => ChunkyPNG::Color.from_hex(cliffs[4]),
          # Mountain
          [9, 1] => ChunkyPNG::Color.from_hex(mountain[0]),
          [9, 2] => ChunkyPNG::Color.from_hex(mountain[1]),
          [9, 3] => ChunkyPNG::Color.from_hex(mountain[2]),
          [9, 4] => ChunkyPNG::Color.from_hex(mountain[3]),
          [9, 5] => ChunkyPNG::Color.from_hex(mountain[4]),
          # Peaks
          [10, 1] => ChunkyPNG::Color.from_hex(peaks[0]),
          [10, 2] => ChunkyPNG::Color.from_hex(peaks[1]),
          [10, 3] => ChunkyPNG::Color.from_hex(peaks[2]),
          [10, 4] => ChunkyPNG::Color.from_hex(peaks[3]),
          [10, 5] => ChunkyPNG::Color.from_hex(peaks[4])
        }
      end
    end
  end
end


















































