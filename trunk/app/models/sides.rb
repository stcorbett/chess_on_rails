#Contains data on each side in Chess
class Sides
  Side = Struct.new("Side", :color, :back_rank, :front_rank, :advance_direction)

  White = Side.new(         :white, 1,          2,          1)
  Black = Side.new(         :black, 8,          7,          -1)
  
  def self.[](side)
    side==:white ? White : Black
  end
  
  #Used in at least one place - board initialization - to set up each side
  def self.each() # :yields: color, back_rank, front_rank, advance_direction
    yield White.values
    yield Black.values
  end
  
end