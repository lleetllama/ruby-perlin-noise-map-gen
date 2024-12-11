require 'perlin_noise'
require 'chunky_png'

# A class to generate and manipulate noise maps using Perlin noise.
class NoiseMap
  attr_reader :layers, :width, :height

  # Initialize a new NoiseMap object with the specified dimensions.
  # @param width [Integer] The width of the noise map.
  # @param height [Integer] The height of the noise map.
  def initialize(width, height)
    @width = width
    @height = height
    @layers = [] # Stores noise layers added to the map.
  end

  # Add a noise layer to the map with specified properties.
  # @param frequency [Float] The frequency of the noise pattern.
  # @param amplitude [Float] The amplitude of the noise layer.
  # @param seed [Integer, nil] The seed for random noise generation.
  # @param dimension [Integer] The dimensionality of the noise (default: 2).
  # @param center_amplified [Boolean] Whether to amplify noise near the center.
  # @param invert [Boolean] Whether to invert the noise values.
  # @param mask_range [Array<Float>, nil] Range of values to keep; others are masked to 0.
  def add_layer(frequency: 1.0, amplitude: 1.0, seed: nil, dimension: 2, center_amplified: false, invert: false, mask_range: nil)
    noise = Perlin::Noise.new(dimension, seed: seed || Random.new_seed)
    @layers << {
      noise: noise,
      frequency: frequency,
      amplitude: amplitude,
      center_amplified: center_amplified,
      invert: invert,
      mask_range: mask_range
    }
  end

  # Generate the combined noise map by layering added noise layers.
  # @return [Array<Array<Float>>] The generated noise map.
  def generate_map
    map = Array.new(@height) { Array.new(@width, 0.0) }
    @layers.each do |layer|
      noise = layer[:noise]
      frequency = layer[:frequency]
      amplitude = layer[:amplitude]
      invert = layer[:invert]
      center_amplified = layer[:center_amplified]
      mask_range = layer[:mask_range]

      @height.times do |y|
        amplification_factor = center_amplified ? vertical_amplification_factor(y) : 1.0

        @width.times do |x|
          value = noise[x * frequency / @width, y * frequency / @height] # Generate noise value.
          value = 1.0 - value if invert # Optionally invert the noise value.

          # Apply mask range if specified.
          if mask_range
            min, max = mask_range
            value = (value >= min && value <= max) ? value : 0.0
          end

          # Apply amplification and accumulate the layer's contribution.
          map[y][x] += value * amplitude * amplification_factor
        end
      end
    end
    normalize_map(map) # Normalize the map to ensure values are within [0.0, 1.0].
  end

  # Apply a fade effect near the edges of the map to blend borders.
  # @param map [Array<Array<Float>>] The noise map to fade.
  # @param fade_width [Integer] The width of the fade effect from the edges.
  # @return [Array<Array<Float>>] The faded noise map.
  def apply_border_fade(map, fade_width)
    faded_map = Array.new(@height) { Array.new(@width, 0.0) }

    @height.times do |y|
      @width.times do |x|
        fade_factor = [
          x / fade_width.to_f,
          (width - 1 - x) / fade_width.to_f,
          y / fade_width.to_f,
          (height - 1 - y) / fade_width.to_f
        ].min
        fade_factor = [fade_factor, 1.0].min # Clamp fade factor to [0.0, 1.0].
        faded_map[y][x] = map[y][x] * fade_factor
      end
    end

    faded_map
  end

  # Blend two noise maps based on a mask map and weight.
  # @param base_map [Array<Array<Float>>] The base map.
  # @param mask_map [Array<Array<Float>>] The mask map used for blending.
  # @param weight [Float] The blending weight.
  # @return [Array<Array<Float>>] The blended noise map.
  def blend_layers(base_map, mask_map, weight: 1.0)
    blended_map = Array.new(@height) { Array.new(@width, 0.0) }

    @height.times do |y|
      @width.times do |x|
        blended_map[y][x] = base_map[y][x] * (mask_map[y][x] * weight)
      end
    end

    blended_map
  end

  # Write the noise map to a bitmap file using a specified color map.
  # @param filename [String] The name of the output PNG file.
  # @param map [Array<Array<Float>>] The noise map to write.
  # @param color_map [Array<Array<Float, ChunkyPNG::Color>>] Mapping of height values to colors.
  def write_to_bitmap(filename, map, color_map)
    png = ChunkyPNG::Image.new(@width, @height, ChunkyPNG::Color::WHITE)

    @height.times do |y|
      @width.times do |x|
        height = map[y][x]
        png[x, y] = height_to_color(height, color_map)
      end
    end

    png.save(filename, interlace: true)
  end

  private

  # Calculate an amplification factor based on the distance from the vertical center.
  # @param y [Integer] The y-coordinate.
  # @return [Float] The amplification factor.
  def vertical_amplification_factor(y)
    center = @height / 2.0
    distance_from_center = (y - center).abs
    linear_factor = 1.0 - (distance_from_center / center)
    [linear_factor**2, 0.0].max # Nonlinear scaling with clamping.
  end

  # Normalize map values to the range [0.0, 1.0].
  # @param map [Array<Array<Float>>] The noise map to normalize.
  # @return [Array<Array<Float>>] The normalized noise map.
  def normalize_map(map)
    min = map.flatten.min
    max = map.flatten.max
    map.map { |row| row.map { |value| (value - min) / (max - min) } }
  end

  # Convert a normalized height value to a color based on the color map.
  # @param height [Float] The normalized height value.
  # @param color_map [Array<Array<Float, ChunkyPNG::Color>>] The color map for height-to-color conversion.
  # @return [ChunkyPNG::Color] The corresponding color.
  def height_to_color(height, color_map)
    color_map.each do |threshold, color|
      return color if height <= threshold
    end
    ChunkyPNG::Color::BLACK
  end
end
