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
  def initialize
    @testing = PegSet.new(:code)
    # @guessing = PegSet.new(:guess)
    p convert_input(:guess, player_input)
  end

  # Should work for both code and guesses
  def player_input
    colors = []
    loop do
      puts "Enter the initial of the desired colors. Options are:\nOrange, Yellow, Green, Blue, Purple, Red"
      colors = [gets[0].upcase, gets[0].upcase, gets[0].upcase, gets[0].upcase]
      return colors if @testing.valid_code_set?(colors)

      puts "That's not a valid combination. Try again."
    end
  end

  # Expects symbol and array of single character identifiers
  def convert_input(type, colors = [])
    if type == :key
      colors.map { |color| KEY_COLORS.key(color) }
    else
      colors.map { |color| CODE_COLORS.key(color) }
    end
  end
end

# Pegs
# Start with defining the pegs themselves
class CodePeg
  attr_reader :color

  COLORS = %i[orange yellow green blue purple pink].freeze
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
    if colors.empty?
      @pegs.push(CodePeg.new) until @pegs.length == LENGTH
    else
      colors.each do |color|
        @pegs.push(CodePeg.new(color))
      end
    end
    @pegs.each { |c| puts c.color }
  end

  # Auto code generator
  def cpu_codemaker
    Array.new(4, CodePeg.new(:code))
  end

  # Modify key pegs
  def change_pegs(colors); end

  # Compare the two, and return a new set
  def check_guess(guess_set)
    # The guess set should be an array.
    # In a loop (each with index):
    # Compare the Guess Peg with every Code Peg
    # (Using a second each with index)
    # If the Guess Peg is present, check if it is in the same slot (index)
    # If it is, add one Black peg. If not, add one White peg.
    #
    # USE self.class.new to create a new instance of PegSet
  end
end

def main
  Mastermind.new
end

main
