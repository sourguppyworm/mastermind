# frozen_string_literal: true

# Fuck ok
# elements of mastermind:
#   2 players, a codemaker and codebreaker
#   6 colors of code pegs
#   2 colors of key pegs, which tell the codebreaker how close they are
#   one set of 4 code pegs, determined by the opponent
#   each turn, codebreaker guesses the code
#     and is shown red or white key pegs depending on how many code pegs are correct
#     notably this does not include which specific code pegs are correct, only how many
#   12 turns to guess
#
#
# == Focus on structure first ==
#

CODE_COLORS = {
  orange: 'O',
  yellow: 'Y',
  green: 'G',
  blue: 'B',
  purple: 'P',
  red: 'R'
}.freeze
KEY_COLORS = {
  black: 'B',
  white: 'W'
}.freeze

class Mastermind # rubocop:disable Style/Documentation
  TURNS = 12
  def initialize
    @code_pegs = PegSet.new(:code)
    puts @code_pegs.colors
    @key_pegs = Array.new(4, :empty)
    # @guessing = PegSet.new(:guess)
  end

  # Player turn, take input, make guess, return key PegSet
  def player_colors(type = :code)
    colors = []
    loop do
      puts "Enter color initials. Options are:\nOrange, Yellow, Green, Blue, Purple, Red"
      colors = player_input
      peg_set = PegSet.new(type, convert_input(type, colors))
      return peg_set if peg_set.valid_code_set?(colors)

      puts "That's not a valid combination. Try again."
    end
  end

  # Should work for both code and guesses
  def player_input
    [gets[0].upcase, gets[0].upcase, gets[0].upcase, gets[0].upcase]
  end

  # Converts input to arrays for usage in creating pegs
  # Expects symbol and array of single character identifiers
  def convert_input(type, colors = [])
    if type == :key
      colors.map { |color| KEY_COLORS.key(color) }
    else
      colors.map { |color| CODE_COLORS.key(color) }
    end
  end

  # Create new PegSet for guess, using the prior input functions
  # Expects a PegSet
  def make_guess
    @key_pegs = PegSet.new(:key, @code_pegs.check_guess(@guess_pegs))
    @key_pegs.show_colors
  end

  def check_win
    true if @key_pegs.colors.all?(:black)
  end

  def winner
    puts "You win! The code was #{@code_pegs.colors}"
  end

  def loser
    puts "You ran out of turns. The code was #{@code_pegs.colors}"
  end

  def guess_loop
    i = 0
    while i < TURNS
      @guess_pegs = player_colors
      make_guess
      i += 1
      if check_win
        winner
        break
      end
    end
  end

  def start_game
    puts 'Pick a role, guess or code'
    role = gets.chomp
    if role == 'guess'
      guess_loop
    elsif role == 'code'
      @code_pegs = player_colors(:code)
      cpu_loop
    end
  end

  def player_code
    player_input
    @code_pegs = PegSet.new(:code, convert_input(:code, colors))
  end

  def cpu_loop
    i = 0
    while i < TURNS
      guess = cpu_guess
      i += 1
      puts 'CPU guessed:'
      guess.colors
      make_guess
    end
  end

  def cpu_guess
    # Random guess if @key_pegs is all empty
    # If not, keep black pegs
    # And randomize positions of any white pegs
    return PegSet.new(:guess) if @key_pegs.all?(:empty)

    guess = Array.new(4, EMPTY)
    confirmed = check_cpu_guess
    guess.map!.with_index do |_peg, index|
      confirmed[0][index] unless confirmed[0][index] == EMPTY
    end
  end

  # IDGAF
  def check_cpu_guess # rubocop:disable Metrics/MethodLength
    black = Array.new(4)
    white = []
    cpu_guess = @guess_pegs.color_to_arr
    cpu_guess.each_with_index do |peg, index|
      if @key_pegs[index].color == :black
        black[index] = peg
      elsif @key_pegs[index].color == :white
        white[index] = peg
      end
    end
    [black, white]
  end
end

# Pegs
# Start with defining the pegs themselves
class CodePeg
  attr_reader :color

  COLORS = %i[orange yellow green blue purple red].freeze
  TYPES = %i[code guess].freeze

  def initialize(color = nil)
    # yauy i love ternary :)
    @color = color.nil? ? random_color : color
  end

  def random_color
    COLORS[rand(COLORS.length)]
  end
end

# For key pegs, the hint pegs
class KeyPeg
  COLORS = {
    red: 'R',
    white: 'W'
  }.freeze
  def initialize(color)
    @color = color
  end
end

# Then define sets of them
# This is basically a constructor for them for now...
# But it's where comparisons will go later
class PegSet
  attr_accessor :pegs

  LENGTH = 4
  TYPES = %i[code guess key].freeze
  EMPTY = :empty

  # Validity check for player input, expects array of 4 strings
  # Sanity checks are handled in the prior code for cleanliness -.-
  def valid_code_set?(input)
    input.all? { |color| CODE_COLORS.value?(color) }
  end

  def valid_key_set?(input)
    input.all? { |color| KEY_COLORS.value?(color) }
  end

  # Colors expects an array of 4 peg identifiers (symbols)
  def initialize(type, colors = [])
    @type = TYPES.include?(type) ? type : :guess
    @pegs = []
    # Randomize colors if empty
    if colors.empty? && type != :key
      @pegs.push(CodePeg.new) until @pegs.length == LENGTH
    else
      key_peg_set(colors)
    end
  end

  def key_peg_set(colors)
    colors.each do |color|
      @pegs.push(CodePeg.new(color))
    end
    @pegs.push(CodePeg.new(EMPTY)) while @pegs.length < LENGTH
  end

  # Auto code generator
  def cpu_codemaker
    Array.new(4, CodePeg.new(:code))
  end

  def colors
    [@pegs[0].color, @pegs[1].color, @pegs[2].color, @pegs[3].color]
  end

  # Default argument makes most calls cleaner
  def show_colors(guess = false) # rubocop:disable Style/OptionalBooleanParameter
    text = guess ? "You guessed: \n" : "Here is the current #{@type} set:\n"
    puts "#{text} #{@pegs[0].color} #{@pegs[1].color} #{@pegs[2].color} #{@pegs[3].color}"
    puts @code_pegs
  end

  # Compare the two, and return a new set
  def check_guess(guess_set) # rubocop:disable Metrics/MethodLength
    # The guess set should be an array of symbols,
    # Obtained using #convert_input.
    # In a loop (each with index):
    # Compare the Guess Peg with each Code Peg
    # (Using a second each with index)
    # If the Guess Peg is present, check if there is one in the same slot (index)
    #   If there is, add one black peg. If not, add one white peg.
    #   Then replace the identified Code Peg with a dummy
    #   To avoid false positives.
    keys = []
    code = color_to_arr
    guess = guess_set.color_to_arr
    changed = false
    # This is very inefficient and i know that
    # but ill be honest im tired of looking at this code
    guess.each_with_index do |guess_peg, guess_index|
      next unless code.include? guess_peg

      # Black pegs only
      code.each_with_index do |code_peg, code_index|
        changed = false
        next unless guess_peg == code_peg && guess_index == code_index

        # Add a black peg since it matches
        keys.push(:black)
        # Remove the peg in question from the list
        # So it doesn't give false positives
        code[guess_index] = EMPTY
        # Let the rest of the code know it changed
        changed = true
        break
      end
      next if changed

      # Add white
      keys.push(:white)
      # Then remove the matching peg
      code[code.find_index(guess_peg)] = EMPTY
    end
    keys
  end

  def color_to_arr
    result = []
    @pegs.each { |peg| result.push(peg.color) }
    result
  end
end

def main
  game = Mastermind.new
  game.start_game
end

main
