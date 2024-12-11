class ColorBlender
  class << self
    def blend_colors(colors, steps)
      raise ArgumentError, "Colors array must have at least two colors" if colors.size < 2
      raise ArgumentError, "Steps must be a non-negative integer" unless steps.is_a?(Integer) && steps >= 0

      blended_colors = []

      colors.each_cons(2) do |start_color, end_color|
        blended_colors << start_color
        blended_colors.concat(interpolate_colors(start_color, end_color, steps))
      end

      blended_colors << colors.last unless colors.empty?
      blended_colors.map(&:upcase)
    end

    def exclusive_triple_blend(colors, steps)
      raise ArgumentError, "Colors array must have exactly three colors" if colors.size != 3

      blended_colors = []
      # we want to get the midway color between the first two colors and the last two colors
      # then we toss the first and last colors and replace them with the midway colors
      blended_colors[0] = midway_color(colors[0], colors[1])
      blended_colors[1] = colors[1]
      blended_colors[2] = midway_color(colors[1], colors[2])
      blend_colors(blended_colors, steps)
    end


    def midway_color(color1, color2)
      start_rgb = hex_to_rgb(color1)
      end_rgb = hex_to_rgb(color2)

      midway_rgb = start_rgb.zip(end_rgb).map do |start, stop|
        ((start + stop) / 2.0).round
      end

      rgb_to_hex(midway_rgb).upcase
    end

    private

    def interpolate_colors(start_color, end_color, steps)
      start_rgb = hex_to_rgb(start_color)
      end_rgb = hex_to_rgb(end_color)

      (1..steps).map do |step|
        interpolated_rgb = start_rgb.zip(end_rgb).map do |start, stop|
          (start + ((stop - start) * step.to_f / (steps + 1))).round
        end
        rgb_to_hex(interpolated_rgb)
      end
    end

    def hex_to_rgb(hex)
      hex.match(/^#(..)(..)(..)$/) do |match|
        match.captures.map { |component| component.to_i(16) }
      end
    end

    def rgb_to_hex(rgb)
      "##{rgb.map { |value| value.to_s(16).rjust(2, '0') }.join}"
    end
  end
end
