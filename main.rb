require 'perlin_noise'
require 'chunky_png'

require './lib/noise_map'
require './lib/terrain_painter'
require './lib/color_blender'


#  color_spectrum = [
#  %w[#B9F7FC #124e89 #3e2731],
#  %w[#B9F7FC #0099db #3e2731],
#  %w[#B9F7FC #EAD4AA #3e2731],
#  %w[#B9F7FC #B86F50 #3e2731],
#  %w[#B9F7FC #63C74D #3e2731],
#  %w[#B9F7FC #3E8948 #3e2731],
#  %w[#B9F7FC #193C3E #3e2731],
#  %w[#B9F7FC #5A6988 #3e2731],
#  %w[#B9F7FC #8B9BB4 #3e2731],
#  %w[#B9F7FC #C0CBDC #3e2731],
#  ]
#
#  color_spectrum.each do |colors|
#    blended = ColorBlender.exclusive_triple_blend(colors, 1)
#    blended.each do |color|
#      puts color
#    end
#  end
#  binding.pry

MAP_WIDTH = 150
MAP_HEIGHT = 100
SEED = 12345


# Define color mapping (height ranges and their corresponding colors)
# color_map = {
#   0.2 => ChunkyPNG::Color.from_hex('#00396d'), # Dark blue for deep water
#   0.4 => ChunkyPNG::Color.from_hex('#0069aa'), # blue for water
#   0.42 => ChunkyPNG::Color.from_hex('#f9e6cf'), # sandy beach
#   0.45 => ChunkyPNG::Color.from_hex('#96BF8D'), # scrub
#   0.63 => ChunkyPNG::Color.from_hex('#33984b'),  # green for grass
#   0.73 => ChunkyPNG::Color.from_hex('#1e6f50'),  # forest green
#   0.78 => ChunkyPNG::Color.from_hex('#3d3d3d'),  # steppe
#   0.85 => ChunkyPNG::Color.from_hex('#5d5d5d'),  # light grey for mountains
#   0.9 => ChunkyPNG::Color.from_hex('#858585'),  # white for snow
#   1.0 => ChunkyPNG::Color.from_hex('#ffffff')   # white for snow
# }

color_map = {
 0.25 => ChunkyPNG::Color.from_hex( '#000000'),  # deep water
 0.4 => ChunkyPNG::Color.from_hex( '#1C1C1C'),  # water
 0.45 => ChunkyPNG::Color.from_hex('#393939'),  # sand
 0.49 => ChunkyPNG::Color.from_hex('#555555'),  # scrub
 0.63 => ChunkyPNG::Color.from_hex('#717171'),  # grassland
 0.73 => ChunkyPNG::Color.from_hex('#8E8E8E'),  # forest
 0.78 => ChunkyPNG::Color.from_hex('#AAAAAA'),  # steppe
 0.85 => ChunkyPNG::Color.from_hex('#C6C6C6'),  # cliffs
 0.9 => ChunkyPNG::Color.from_hex( '#E3E3E3'),  # mountain
 1.0 => ChunkyPNG::Color.from_hex( '#ffffff')   # peaks
}

temperature_color_map = {
  0.005 => ChunkyPNG::Color.from_hex('#00CDF9'), # arctic
  0.075 => ChunkyPNG::Color.from_hex('#1AB3A2'), # cold
  0.7 => ChunkyPNG::Color.from_hex('#33984B'), # goldilocks zone
  0.8 => ChunkyPNG::Color.from_hex('#7C5E3E'), # warm
  1.0 => ChunkyPNG::Color.from_hex('#C42430') # hot
}

ore_types = [
  { 0.22 => ChunkyPNG::Color.from_hex('#2a2f4e')}, # lead
  { 0.22 => ChunkyPNG::Color.from_hex('#c7cfdd')}, # tin
  { 0.2 => ChunkyPNG::Color.from_hex('#8e251d')}, # copper
  { 0.2 => ChunkyPNG::Color.from_hex('#1c121c')}, # iron
  { 0.18 => ChunkyPNG::Color.from_hex('#92a1b9')}, # silver
  { 0.15 => ChunkyPNG::Color.from_hex('#ffa214')} # gold
]

# Create a new NoiseMap
height_map = NoiseMap.new(MAP_WIDTH, MAP_HEIGHT)
height_map.add_layer(frequency: 4.0, amplitude: 0.5, seed: SEED)
height_map.add_layer(frequency: 6.0, amplitude: 0.5, seed: SEED + 1)
height_map.add_layer(frequency: 12.0, amplitude: 0.5, seed: SEED + 2)
noise_map = height_map.generate_map

fade_width = 30
faded_map = height_map.apply_border_fade(noise_map, fade_width)
height_map.write_to_bitmap('height_map.png', faded_map, color_map)


temperature_map  = NoiseMap.new(MAP_WIDTH, MAP_HEIGHT)
temperature_map.add_layer(frequency: 6.0, amplitude: 0.125, seed: SEED * 2, center_amplified: true)
temperature_map.add_layer(frequency: 8.0, amplitude: 0.125, seed: (SEED * 2) + 1, center_amplified: true)
temperature_noise = temperature_map.generate_map
# blended_temps = temperature_map.blend_layers(temperature_noise, faded_map, weight: 2)
temperature_map.write_to_bitmap('temperature_map.png', temperature_noise, temperature_color_map)

TerrainPainter.paint_terrain('./height_map.png', './temperature_map.png', 'painted_map.png')
# TerrainPainter.paint_terrain('./height_map.png', './empty_temp.png', 'painted_map.png')

ore_types.each_with_index do |ore_type, i|
   ore_map = NoiseMap.new(MAP_WIDTH, MAP_HEIGHT)
   ore_map.add_layer(frequency: 50.0, amplitude: 0.125, seed: SEED + i)
   ore_noise_map = ore_map.generate_map
   ore_map.write_to_bitmap("ore_map_#{i}.png", ore_noise_map, ore_type)
end

