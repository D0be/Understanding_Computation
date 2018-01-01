require './NFA.rb'

module Pattern
    def bracket(outer_precedence)
        if precedence < outer_precedence
            '(' + to_s + ')'
        else
            to_s
        end
    end

    def inspect
        "/#{self}/"
    end
end

class Empty
    include Pattern

    def to_s
        ''
    end

    def precedence
        3
    end
end

class Literal < Struct.new(:character)
    include Pattern

    def to_s
        character
    end

    def precedence
        3
    end
end

class Concatenate < Struct.new(:first, :second)
    include Pattern

    def to_s
        [first, second].map { |pattern| pattern.bracket(precedence) }.join
    end

    def precedence
        1
    end
end

class Choose < Struct.new(:first, :second)
    include Pattern

    def to_s
        [first, second].map { |pattern| pattern.bracket(precedence) }.join('|')
    end

    def precedence
        0
    end
end

class Repeat < Struct.new(:pattern)
    include Pattern

    def to_s
        pattern.bracket(precedence) + '*'
    end

    def precedence
        2
    end
end

class Empty
    def to_nfa_design
        start_state = Object.new
        accept_states = [start_state]
        rulebook = NFARulebook.new([])
        NFADesign.new(start_state, accept_states, rulebook)
    end
end
class Literal
    def to_nfa_design
        start_state = Object.new
        accept_state = Object.new
        rule = FARule.new(start_state, character, accept_state)
        rulebook = NFARulebook.new([rule])
        NFADesign.new(start_state, [accept_state], rulebook)
    end
end

module Pattern
    def matches?(string)
        to_nfa_design.accepts?(string)
    end
end

class Concatenate
    def to_nfa_design
        first_nfa_design = first.to_nfa_design
        second_nfa_design = second.to_nfa_design
        start_state = first_nfa_design.start_state
        accept_states = second_nfa_design.accept_states
        rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
        extra_rules = first_nfa_design.accept_states.map { |state|
        FARule.new(state, nil, second_nfa_design.start_state)
        }
        rulebook = NFARulebook.new(rules + extra_rules)
        NFADesign.new(start_state, accept_states, rulebook)
    end
end

class Choose
    def to_nfa_design
        first_nfa_design = first.to_nfa_design
        second_nfa_design = second.to_nfa_design
        start_state = Object.new
        accept_states = first_nfa_design.accept_states + second_nfa_design.accept_states
        rules = first_nfa_design.rulebook.rules + second_nfa_design.rulebook.rules
        extra_rules = [first_nfa_design, second_nfa_design].map { |nfa_design|
        FARule.new(start_state, nil, nfa_design.start_state)
        }
        rulebook = NFARulebook.new(rules + extra_rules)
        NFADesign.new(start_state, accept_states, rulebook)
    end
end

class Repeat
    def to_nfa_design
        pattern_nfa_design = pattern.to_nfa_design
        start_state = Object.new
        accept_states = pattern_nfa_design.accept_states + [start_state]
        rules = pattern_nfa_design.rulebook.rules
        extra_rules =
        pattern_nfa_design.accept_states.map { |accept_state|
        FARule.new(accept_state, nil, pattern_nfa_design.start_state)
        } +
        [FARule.new(start_state, nil, pattern_nfa_design.start_state)]
        rulebook = NFARulebook.new(rules + extra_rules)
        NFADesign.new(start_state, accept_states, rulebook)
    end
end

# pattern =
#     Repeat.new(
#         Choose.new(
#             Concatenate.new(Literal.new('a'), Literal.new('b')),
#             Literal.new('a')
#         )
# )

# p pattern               # => /(ab|a)*/



# nfa_design = Empty.new.to_nfa_design
# p nfa_design.accepts?('')                   # => true
# p nfa_design.accepts?('a')                  # => false

# nfa_design = Literal.new('a').to_nfa_design
# p nfa_design.accepts?('')                   # => false
# p nfa_design.accepts?('a')                  # => true
# p nfa_design.accepts?('b')                  # => false

# p Empty.new.matches?('a')                     # => false
# p Empty.new.matches?('')                      # => true
# p Literal.new('a').matches?('a')              # => true
# p Literal.new('a').matches?('b')              # => false

# pattern = Concatenate.new(Literal.new('a'), Literal.new('b'))
# p pattern.matches?('a')                         # => false
# p pattern.matches?('ab')                        # => true
# p pattern.matches?('b')                         # => false

# pattern =
#     Concatenate.new(
#         Literal.new('a'),
#         Concatenate.new(Literal.new('b'), Literal.new('c'))
#     )
# p pattern.matches?('a')                 # => false
# p pattern.matches?('abc')               # => true

# pattern = Choose.new(Literal.new('a'), Literal.new('b'))
# p pattern                                  # => /a|b/
# p pattern.matches?('a')                    # => true
# p pattern.matches?('b')                    # => true
# p pattern.matches?('ab')                   # => false
# p pattern.matches?('c')                    # => false

# pattern = Repeat.new(Literal.new('a'))
# p pattern                                   # => /a*/
# p pattern.matches?('')                      # => true
# p pattern.matches?('a')                     #= > true
# p pattern.matches?('aa')                    # => true
# p pattern.matches?('b')                     # => false
pattern =
    Repeat.new(
        Concatenate.new(
            Literal.new('a'),
            Choose.new(Empty.new, Literal.new('b'))
    )
)
p pattern                                   # => /(a(|b))*/
p pattern.matches?('')                      # => true
p pattern.matches?('a')                     # => true
p pattern.matches?('ab')                    # => true
p pattern.matches?('aba')                   # => true
p pattern.matches?('abab')                  # => true
p pattern.matches?('abaab')                 # => true
p pattern.matches?('abba')                  # => false
