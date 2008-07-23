
#An instance of a piece bound to a particular match
class Piece  

  #the allowed types and their shorthand
  Types = {:kings_rook =>'R', :kings_knight =>'N',  :kings_bishop=>'B',  
    :queens_rook=>'R', :queens_knight=>'N',  :queens_bishop=>'B', 
    :king=>'K',  :queen=>'Q',
    :a_pawn=>'a', :b_pawn=>'b', :c_pawn=>'c', :d_pawn=>'d',
    :e_pawn=>'e', :f_pawn=>'f', :g_pawn=>'g', :h_pawn=>'h'
  }
  
  attr_accessor :id        #uniquely identifies a piece throughout a match, generally a combination of side and type
  attr_accessor :side      #black or white
  attr_accessor :type      #ex. queens_bishop
  attr_accessor :position 
  
  def initialize(side, type, pos=nil)
    @side = side
    @type = type
    @position = pos
  end
  
  #when rendered the client id uniquely specifies an individual piece within a board
  #example: white_f_pawn
  def board_id
    @id || "#{@side}_#{@type}"
  end
  
  def file
    return @position[0].chr
  end
  def rank
    return @position[1].chr
  end
  
  def to_s
    return "Side: #{@side} type:#{@type} at #{position}"
  end
  
  def role
    return 'pawn' if @type.to_s.include?('pawn')
    if @type.to_s.include?('kings') || @type.to_s.include?('queens')
      return @type.to_s.split('_')[1] 
    else
      return @type.to_s
    end
  end
  
  def advance_direction
    @side == :white ? 1 : -1
  end
  
  #bishops and rooks (and the queen) have 'lines of attack', or directions which can be stopped by an intervening piece
  BISHOP_LINES = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
  ROOK_LINES = [[1,0], [-1,0], [0,1], [0,-1] ]  
  def lines_of_attack
    return  BISHOP_LINES               if role=='bishop'
    return  ROOK_LINES                 if role=='rook'
    return  BISHOP_LINES + ROOK_LINES  if role=='queen'
    @lines_of_attack || []
  end
  
  #The part of the notation - with a piece disambiguator for pawns minors and rooks
  # It will be removed later if deemed unnecessary
  def notation
    #Types contains the notation bases as values of the Hash
    return (role == 'pawn') ? file : Types[@type]
  end
  
  #eliminates theoretical moves that would not be applicable on a certain board
  # for reasons of: 1) would be on your own sides square
  # 2) would place your king in check
  def allowed_moves(board)
    moves = []

    #bishops queens and rooks have 'lines of attack' rules
    lines_of_attack.each do |line_of_attack|
      line_worth_following = true
      file_unit, rank_unit = line_of_attack
      
      (1..8).each do |length|
        pos = (file[0] + (file_unit*length) ).chr + (rank.to_i + (rank_unit*length)).to_s
        next unless line_worth_following
        next unless Chess.valid_position?( pos ) 
        
        side_occupying = board.side_occupying(pos)
        
        moves << pos unless side_occupying == @side
        
        # if a line of attack is blocked, remove it from the list
        line_worth_following = false unless side_occupying == nil
      end
      
    end
    return moves if lines_of_attack.length > 0 #thats it for this piece type
      
      #for knights pawns and kings..
      
      #start by excluding squares you occupy 
      moves = theoretical_moves.reject { |pos| @side == board.side_occupying(pos) }
      
      #pawns have some exclusions (cannot move diagonally unless capture or enpassant)
      if( role=='pawn' )

        # exclude non-forward moves unless captures or en_passant (6th and 3rd rank captures behind doubly advanced pawn)
        moves.reject! do |pos| 
          #diagonals are excluded if empty (unless en passant)
          if (pos[0] != @position[0]) 
            (board.side_occupying(pos) == nil) && ! board.is_en_passant_capture?( @position, pos )
          elsif (board.side_occupying(pos) != nil) 
            true
          else
            ((@position[1].chr=='2')&&(board.side_occupying(@position[0].chr+'3') != nil)) || ((@position[1].chr=='7')&&(board.side_occupying(@position[0].chr+'6') != nil))
          end
        end
        
      #kings may have additional moves for castling
      elsif ( role=='king')
        #castling
        castle_rank = (side==:white) ? '1' : '8'
        
        #TODO castling logic does not account for previous moves, or castling across check
        king_on_initial_square    = (position == ('e'+castle_rank) )
        
        [ ['h', ('f'..'g'), 'g'], ['a', ('b'..'d'), 'c'] ].each do |rook_file, intervening_files, castle_to_file|
          rook_on_initial_square  = board[rook_file + castle_rank] and board[rook_file + castle_rank].role=='rook'
          intervening_files_empty = intervening_files.inject(true){ |empty, file| empty and board[file+castle_rank] == nil}
          
          if king_on_initial_square and rook_on_initial_square and intervening_files_empty
            moves << castle_to_file + castle_rank
          end
        end
        
      end
      
      #knights have no additional special moves
    
    return moves
  end
  
  #the moves a piece could move to on an empty board
  def theoretical_moves
    @moves = []
    
    #call the method named for the role of the piece
    self.send( "calc_theoretical_moves_#{role}" )

    return @moves
  end
    
  def calc_theoretical_moves_king
    
    (BISHOP_LINES + ROOK_LINES).each do |file_unit, rank_unit|
      pos = (file[0] + (file_unit) ).chr + (rank.to_i + (rank_unit)).to_s
      @moves << pos if Chess.valid_position?( pos )
    end
  end
  
  # a knight has no lines of attack	
  def calc_theoretical_moves_knight
    
    [ [1,2], [1,-2], [-1,2], [-1,-2], [2,1], [2,-1], [-2,1], [-2,-1] ].each do | file_unit, rank_unit |
      pos = (file[0] + (file_unit) ).chr + (rank.to_i + (rank_unit)).to_s
      @moves << pos if Chess.valid_position?( pos )
    end
  end
  
  def calc_theoretical_moves_pawn
    
    [ [:white,'2'], [:black,'7'] ].each do |side, front_rank|
      if @side == side
        
        #the single advance, and double from home rank
        @moves << file.to_s + (rank.to_i + advance_direction).to_s
        
        if rank==front_rank
          @moves << file.to_s + (rank.to_i + 2 * advance_direction).to_s
        end
        
        #the diagonal captures
        @moves << (file[0].to_i - 1).chr + (rank.to_i + advance_direction).to_s
        @moves << (file[0].to_i + 1).chr + (rank.to_i + advance_direction).to_s
      end
      
    end

    @moves.reject! { |mv| ! Chess.valid_position?( mv ) }
  end

  def img_name
    ( (type.to_s.split('_').length==2) ? type.to_s.split('_')[1] : type.to_s) + '_' + side.to_s.slice(0,1)
  end

  def promote!( new_type = :queen )
    raise ArgumentError, 'You may only promote to queen (default), knight, bishop or rook' if (new_type == :king) || new_type.to_s.include?('pawn')

    Promotion_Criteria.each do | criteria, message |
      raise ArgumentError, message unless criteria.call(self)
    end

    #promote
    @type = new_type ? new_type : :queen
    @id = "#{@side}_promoted_#{@type}"
  end

  #the set of criteria and error messages to display unless criteria met
  Promotion_Criteria = [
    [ lambda{ |p| (p.side == :white && p.rank == '8')  || (p.side == :black && p.rank == '1') },
      'May only promote upon reaching the opposing back rank' ],

    [ lambda{ |p| p.type.to_s.include?('pawn') },
      'No piece other than pawn may promote' ]
  ]

  def promotable?
    all_true = Promotion_Criteria.inject(true){ |result, crit| result &= crit[0].call(self) }
  end

end

