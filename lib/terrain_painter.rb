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

    # Convert height map color to height value (1-10)
    def height_to_value(pixel_color)
      case pixel_color
      when '#000000ff' then 1
      when '#1c1c1cff' then 2
      when '#393939ff' then 3
      when '#555555ff' then 4
      when '#717171ff' then 5
      when '#8e8e8eff' then 6
      when '#aaaaaaff' then 7
      when '#c6c6c6ff' then 8
      when '#e3e3e3ff' then 9
      when '#ffffffff' then 10
      else 0 # Default value if color is not matched
      end
    end

    # Convert temperature map color to temperature value (1-5)
    def temperature_to_value(pixel_color)
      case pixel_color
      when '#00cdf9ff'.downcase then 1
      when '#1ab3a2ff'.downcase then 2
      when '#33984bff'.downcase then 3
      when '#7c5e3eff'.downcase then 4
      when '#c42430ff'.downcase then 5
      else 0 # Default value if color is not matched
      end
    end

    # Determine the final terrain color based on height and temperature values
    def determine_terrain_color(height_value, temperature_value)
      # Define specific colors for each combination of height and temperature

      cold_tint = '#ffffff'
      hot_tint = '#edab50'

      deep_ocean = ColorBlender.exclusive_triple_blend([cold_tint, '#124E89', hot_tint ], 1)
      water      = ColorBlender.exclusive_triple_blend([cold_tint, '#0099DB', hot_tint ], 1)
      sand       = ColorBlender.exclusive_triple_blend([cold_tint, '#EAD4AA', hot_tint ], 1)
      scrub_land = ColorBlender.exclusive_triple_blend([cold_tint, '#B86F50', hot_tint ], 1)
      grass_land = ColorBlender.exclusive_triple_blend([cold_tint, '#63C74D', hot_tint ], 1)
      forest     = ColorBlender.exclusive_triple_blend([cold_tint, '#3E8948', hot_tint ], 1)
      steppe     = ColorBlender.exclusive_triple_blend([cold_tint, '#193C3E', hot_tint ], 1)
      cliffs     = ColorBlender.exclusive_triple_blend([cold_tint, '#5A6988', hot_tint ], 1)
      mountain   = ColorBlender.exclusive_triple_blend([cold_tint, '#8B9BB4', hot_tint ], 1)
      peaks      = ColorBlender.exclusive_triple_blend([cold_tint, '#C0CBDC', hot_tint ], 1)

      terrain_colors = {
        # Deep Water
        [1, 1] => ChunkyPNG::Color.from_hex(deep_ocean[0]),  # Glacial Depths
        [1, 2] => ChunkyPNG::Color.from_hex(deep_ocean[1]),  # Frozen Abyss
        [1, 3] => ChunkyPNG::Color.from_hex(deep_ocean[2]),  # Midnight Deep
        [1, 4] => ChunkyPNG::Color.from_hex(deep_ocean[3]),  # Warm Waters
        [1, 5] => ChunkyPNG::Color.from_hex(deep_ocean[4]),  # Scalding Depths
        # Water
        [2, 1] => ChunkyPNG::Color.from_hex(water[0]),  # Glacial Sea
        [2, 2] => ChunkyPNG::Color.from_hex(water[1]),  # Ice-Cool Ocean
        [2, 3] => ChunkyPNG::Color.from_hex(water[2]),  # Deepwater
        [2, 4] => ChunkyPNG::Color.from_hex(water[3]),  # Tropical Ocean
        [2, 5] => ChunkyPNG::Color.from_hex(water[4]),  # Boiling Sea
        # Beach
        [3, 1] => ChunkyPNG::Color.from_hex(sand[0]),  # Frostbitten Shore
        [3, 2] => ChunkyPNG::Color.from_hex(sand[1]),  # Frost Coast
        [3, 3] => ChunkyPNG::Color.from_hex(sand[2]),  # Sandy Tides
        [3, 4] => ChunkyPNG::Color.from_hex(sand[3]),  # Coral Shores
        [3, 5] => ChunkyPNG::Color.from_hex(sand[4]),  # Scorched Beaches
        # Scrublands
        [4, 1] => ChunkyPNG::Color.from_hex(scrub_land[0]),  # Windswept Barrens
        [4, 2] => ChunkyPNG::Color.from_hex(scrub_land[1]),  # Dustbowl Flats
        [4, 3] => ChunkyPNG::Color.from_hex(scrub_land[2]),  # Thirsty Wilderness
        [4, 4] => ChunkyPNG::Color.from_hex(scrub_land[3]),  # Sunscorched Wilds
        [4, 5] => ChunkyPNG::Color.from_hex(scrub_land[4]),  # Embered Desert
        # Grassland
        [5, 1] => ChunkyPNG::Color.from_hex(grass_land[0]),  # Frozen Steppe
        [5, 2] => ChunkyPNG::Color.from_hex(grass_land[1]),  # Cool Meadow
        [5, 3] => ChunkyPNG::Color.from_hex(grass_land[2]),  # Verdant Plains
        [5, 4] => ChunkyPNG::Color.from_hex(grass_land[3]),  # Tropical Grassland
        [5, 5] => ChunkyPNG::Color.from_hex(grass_land[4]),  # Scorched Savannah
        # Forest
        [6, 1] => ChunkyPNG::Color.from_hex(forest[0]),  # Frostwood Grove
        [6, 2] => ChunkyPNG::Color.from_hex(forest[1]),  # Evergreen Forest
        [6, 3] => ChunkyPNG::Color.from_hex(forest[2]),  # Lushwood
        [6, 4] => ChunkyPNG::Color.from_hex(forest[3]),  # Jungle Grove
        [6, 5] => ChunkyPNG::Color.from_hex(forest[4]),  # Tropical Rainforest
        # Steppe
        [7, 1] => ChunkyPNG::Color.from_hex(steppe[0]),  # Frozen Steppe
        [7, 2] => ChunkyPNG::Color.from_hex(steppe[1]),  # Bitter Grasslands
        [7, 3] => ChunkyPNG::Color.from_hex(steppe[2]),  # Rolling Hills
        [7, 4] => ChunkyPNG::Color.from_hex(steppe[3]),  # Wild Steppe
        [7, 5] => ChunkyPNG::Color.from_hex(steppe[4]),  # Dry Plains
        # Cliffs
        [8, 1] => ChunkyPNG::Color.from_hex(cliffs[0]),  # Snowy Cliffside
        [8, 2] => ChunkyPNG::Color.from_hex(cliffs[1]),  # Frostcliff
        [8, 3] => ChunkyPNG::Color.from_hex(cliffs[2]),  # Highstone Cliffs
        [8, 4] => ChunkyPNG::Color.from_hex(cliffs[3]),  # Warmrock Cliffside
        [8, 5] => ChunkyPNG::Color.from_hex(cliffs[4]),  # Scorched Peaks
        # Mountain
        [9, 1] => ChunkyPNG::Color.from_hex(mountain[0]),  # Snowy Mountain
        [9, 2] => ChunkyPNG::Color.from_hex(mountain[1]),  # Frozen Ridge
        [9, 3] => ChunkyPNG::Color.from_hex(mountain[2]),  # Misty Mountain
        [9, 4] => ChunkyPNG::Color.from_hex(mountain[3]),  # Rugged Mountain
        [9, 5] => ChunkyPNG::Color.from_hex(mountain[4]),  # Volcanic Mountain
        # Peaks
       [10, 1] => ChunkyPNG::Color.from_hex(peaks[0]),  # Icepeak Summit
       [10, 2] => ChunkyPNG::Color.from_hex(peaks[1]),  # Frostspire
       [10, 3] => ChunkyPNG::Color.from_hex(peaks[2]),  # Cloudspire
       [10, 4] => ChunkyPNG::Color.from_hex(peaks[3]),  # Emberspire
       [10, 5] => ChunkyPNG::Color.from_hex(peaks[4]),  # Lavapeak Summit
      }

      # Return the terrain color based on the height and temperature values
      terrain_colors[[height_value, temperature_value]] || ChunkyPNG::Color.from_hex('#000000') # Default color if no match
    end
  end
end


















































