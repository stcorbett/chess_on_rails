
#An instance of a piece bound to a particular match
# (Currently not aware of matches in any tests)
class Piece < ActiveRecord::Base
	
	require 'Enumerable'
	
	#the allowed types for the type instance accessor (and their shorthand)
	@@types = {:kings_rook =>'R#{@file}', :kings_knight =>'N#{@file}',  :kings_bishop=>'B',  
		:queens_rook=>'R#{@file}', :queens_knight=>'N#{@file}',  :queens_bishop=>'B', 
		:king=>'K',  :queen=>'Q',  :pawn=>'#{@file}'}
	
	#the allowed sides for the side instance accessor (and their shorthand)
	@@sides = {:white=>"W", :black=>"B"}
	
	attr_accessor :type
	attr_accessor :side
	
	attr_accessor :file
	attr_accessor :rank
	
	attr_accessor :match_id, :int
	
	def initialize(side, type)
		@side = side
		@type = type
        #if !this.valid? { raise "Invalid side:#{side} or type:#{type} in piece creation" }
	end
	
	def advance_direction
		return 1 if @side == :white
		return -1 if @side == :black
	end
	
	#The part of the notation - with a piece disambiguator for pawns minors and rooks
	# It will be removed later if deemed unnecessary
	def notation
		#%Q{"#{f}"}
		type_text = @@types[@type]
		return eval( %Q{ "#{type_text}" } )
	end
	
	def position
		return "#{@file}#{@rank}"
	end
	
	def position=(pos)
		if pos.length == 2
			@file = pos[0].to_s
			@rank = pos[1].to_s
		end
	end
	
	#the moves a piece could move to on an empty board
	def theoretical_moves
		return @moves if @moves != nil 
		
		@moves = []
		
		if @type == :pawn
			calc_theoretical_moves_pawn
		elsif @type == :queen
			calc_theoretical_moves_queen
		elsif @type == :king
			calc_theoretical_moves_king
		elsif @type == :queens_knight || @type == :kings_knight
			calc_theoretical_moves_knight
		elsif @type == :queens_rook || @type == :kings_rook
			calc_theoretical_moves_rook
		elsif @type == :queens_bishop || @type == :kings_bishop
			calc_theoretical_moves_bishop
		end
		
		@moves.reject! { |pos| ! Chess.valid_position?( pos ) }
		return @moves
	end
	
	def calc_theoretical_moves_king
		
		one_moves = [1,0,-1].cartesian( [1,0,-1] ).reject! { |x| x==[0,0] }
		one_moves.each do |file_unit, rank_unit|
			@moves << (@file[0] + (file_unit) ).chr + (@rank.to_i + (rank_unit)).to_s
		end
	end
	
	def calc_theoretical_moves_queen
		
		one_moves = [1,0,-1].cartesian( [1,0,-1] ).reject! { |x| x==[0,0] }
		one_moves.each do |file_unit, rank_unit|
			(1..8).each do |length|
				@moves << (@file[0] + (file_unit*length) ).chr + (@rank.to_i + (rank_unit*length)).to_s
			end
		end
	end
	
	def calc_theoretical_moves_rook
		
		one_moves = [ [1,0], [-1,0], [0,1], [0,-1] ]
		one_moves.each do |file_unit, rank_unit|
			(1..8).each do |length|
				@moves << (@file[0] + (file_unit*length) ).chr + (@rank.to_i + (rank_unit*length)).to_s
			end
		end
	end
	
	def calc_theoretical_moves_bishop
		
		one_moves = [ [1,1], [-1,1], [1,-1], [-1,-1] ]
		one_moves.each do |file_unit, rank_unit|
			(1..8).each do |length|
				@moves << (@file[0] + (file_unit*length) ).chr + (@rank.to_i + (rank_unit*length)).to_s
			end
		end
	end
	
	
	def calc_theoretical_moves_knight
		
		[ [1,2], [1,-2], [-1,2], [-1,-2], [2,1], [2,-1], [-2,1], [-2,-1] ].each do | file_unit, rank_unit |
			@moves << (@file[0] + (file_unit) ).chr + (@rank.to_i + (rank_unit)).to_s
		end
	end
	
	def calc_theoretical_moves_pawn
		
		[ [:white,'2'], [:black,'7'] ].each do |side, front_rank|
			if @side == side
				
				#the single advance, and double from home rank
				@moves << @file.to_s + (@rank.to_i + advance_direction).to_s
				
				if @rank==front_rank
					@moves << @file.to_s + (@rank.to_i + 2 * advance_direction).to_s
				end
				
				#the diagonal captures
				@moves << (@file[0].to_i - 1).chr + (@rank.to_i + advance_direction).to_s
				@moves << (@file[0].to_i + 1).chr + (@rank.to_i + advance_direction).to_s
			end
			
		end
	end
	
	def validate
		
		#errors.add(:side, "I dont like that side " + @side.to_s)
		
		if ! @@types.has_key? @type
			errors.add(:type, "Unknown type " + @type.to_s + ". It may help to specify :queens_bishop instead of :bishop for example ")
		end
		
		if ! @@sides.has_key? @side
			errors.add(:side, "Unknown side " + @side.to_s + ". Valid sides are :black and :white")
		end
		
		#must be a known type
		#if !@@types.includes?(@type) 
		#	errors.add(:type, "Unknown type [${@type}]")
		#end
	end
end
