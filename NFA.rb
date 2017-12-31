require 'set'


class FARule < Struct.new(:state, :character, :next_state)
    def applies_to?(state, character)
        self.state == state && self.character == character
    end

    def follow
        next_state
    end

    def inspect
        "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
    end
end


class NFARulebook < Struct.new(:rules)
    def next_states(states, character)
        states.flat_map { |state| follow_rules_for(state, character) }.to_set
    end

    def follow_rules_for(state, character)
        rules_for(state, character).map(&:follow)
    end

    def rules_for(state, character)
        rules.select { |rule| rule.applies_to?(state, character) }
    end

    def follow_free_moves(states)
        more_states = next_states(states, nil)
        if more_states.subset?(states)
            states
        else
            follow_free_moves(states + more_states)
        end
    end
end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
    def accepting?
        (current_states & accept_states).any?
    end

    def read_character(character)
        self.current_states = rulebook.next_states(current_states, character)
    end

    def read_string(string)
        string.chars.each do |character|
            read_character(character)
        end
    end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
    def accepts?(string)
        to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
    end

    def to_nfa
        NFA.new(Set[start_state], accept_states, rulebook)
    end
end

class NFA
    def current_states
        rulebook.follow_free_moves(super)
    end
end

# rulebook = NFARulebook.new([
#     FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
#     FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
#     FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
# ])

# p rulebook.next_states(Set[1], 'b')                 # => #<Set: {1, 2}>
# p rulebook.next_states(Set[1, 2], 'a')              # => #<Set: {1, 3}>
# p rulebook.next_states(Set[1, 3], 'b')              # => #<Set: {1, 2, 4}>

# p NFA.new(Set[1], [4], rulebook).accepting?             # => false
# p NFA.new(Set[1, 2, 4], [4], rulebook).accepting?       # => true
# nfa = NFA.new(Set[1], [4], rulebook)
# p nfa.accepting?                                          # => false
# nfa.read_character('b')
# p nfa.accepting?                                          # => false
# nfa.read_character('a')
# p nfa.accepting?                                          # => false
# nfa.read_character('b')
# p nfa.accepting?                                          # => true

# nfa = NFA.new(Set[1], [4], rulebook)
# p nfa.accepting?                                          # => false
# nfa.read_string('bbbbb')
# p nfa.accepting?                                          # => true

# nfa_design = NFADesign.new(1, [4], rulebook)
# p nfa_design.accepts?('bab')                                # => true
# p nfa_design.accepts?('bbbbb')                              # => true
# p nfa_design.accepts?('bbabb')                              # => false

# rulebook = NFARulebook.new([
#     FARule.new(1, nil, 2), FARule.new(1, nil, 4),
#     FARule.new(2, 'a', 3),
#     FARule.new(3, 'a', 2),
#     FARule.new(4, 'a', 5),
#     FARule.new(5, 'a', 6),
#     FARule.new(6, 'a', 4)
# ])

# p rulebook.next_states(Set[1], nil)                         # => #<Set: {2, 4}>

# p rulebook.follow_free_moves(Set[1])                          # => #<Set: {1, 2, 4}>

# nfa_design = NFADesign.new(1, [2, 4], rulebook)
# p nfa_design.accepts?('aa')                                     # => true
# p nfa_design.accepts?('aaa')                                    # => true
# p nfa_design.accepts?('aaaaa')                                  # => false
# p nfa_design.accepts?('aaaaaa')                                 # => true