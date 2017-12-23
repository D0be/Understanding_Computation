class Number < Struct.new(:value)
end

class Add < Struct.new(:left, :right)
end

class Multiply < Struct.new(:left, :right)
end

class Number
    def reducible?
        false
    end

    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end
end

class Add
    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end

    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "<<#{self}>>"
    end
end

class Multiply
    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible?
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end

    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "<<#{self}>>"
    end
end

class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end
end

class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        environment[name]
    end

end

class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

class DoNothing
    def to_s
        'do-nothing'
    end

    def inspect
        "<<#{self}>>"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
end

class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)), environment]
        else
            [DoNothing.new, environment.merge({name => expression})]
        end
    end

end

class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end

    def inspect
        "#{self}"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end

end

class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end 

class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) { #{body} }"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end


#大步语义
#start
class Number
    def evaluate(environment)
        self
    end
end


class Boolean
    def evaluate(environment)
        self
    end
end

class Variable
    def evaluate(environment)
        environment[name]
    end
end

class Add
    def evaluate(environment)
        Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
    end
end

class Multiply
    def evaluate(environment)
        Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
    end
end

class LessThan
    def evaluate(environment)
        Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
    end
end

class Assign
    def evaluate(environment)
        environment.merge({ name => expression.evaluate(environment) })
    end
end

class DoNothing
    def evaluate(environment)
        environment
    end
end

class If
    def evaluate(environment)
        case condition.evaluate(environment)
        when Boolean.new(true)
            consequence.evaluate(environment)
        when Boolean.new(false)
            alternative.evaluate(environment)
        end
    end
end

class Sequence
    def evaluate(environment)
        second.evaluate(first.evaluate(environment))
    end
end

class While
    def evaluate(environment)
        case condition.evaluate(environment)
        when Boolean.new(true)
            evaluate(body.evaluate(environment))
        when Boolean.new(false)
            environment
        end
    end
end
#end


#指称语义
#start
class Number
    def to_ruby
        "-> e { #{value.inspect} }"
    end
end

class Boolean
    def to_ruby
        "-> e  { #{value.inspect} }"
    end
end

class Variable
    def to_ruby
        "-> e { e[#{name.inspect}] }"
    end
end

class Add
    def to_ruby
        "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
    end
end

class Multiply
    def to_ruby
        "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
    end
end
class LessThan
    def to_ruby
        "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
    end
end

class Assign
    def to_ruby
        "-> e { e.merge( { #{name.inspect} => (#{expression.to_ruby}).call(e) } ) }"
    end
end

class DoNothing
    def to_ruby
        "-> e { e }"
    end
end

class If
    def to_ruby
        "-> e { if (#{condition.to_ruby}).call(e)" + 
        " then (#{consequence.to_ruby}).call(e)" + 
        " else (#{alternative.to_ruby}).call(e)" +
        " end }"
    end
end

class Sequence
    def to_ruby
        "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
    end
end

class While
    def to_ruby
        "-> e {" + 
        " while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e); end;" + 
        " e" + 
        " }"
    end
end
#end

class Machine < Struct.new(:statement, :environment)
    def step
        self.statement, self.environment = statement.reduce(environment)
    end

    def run
        while statement.reducible?
            puts "#{statement}, #{environment}"
            step
        end
        puts "#{statement}, #{environment}"
    end
end

# expression = Add.new(
#     Multiply.new(Number.new(1), Number.new(2)),
#     Multiply.new(Number.new(3), Number.new(4))
# )





#Machine.new(LessThan.new(Number.new(5), Add.new(Number.new(2), Number.new(2)))).run
#Machine.new(Add.new(Variable.new(:x), Variable.new(:y)), { x: Number.new(3), y: Number.new(4)}).run
#Machine.new(Assign.new(:x, Add.new(Variable.new(:x), Number.new(1))), {x: Number.new(2)}).run
# Machine.new(
#     If.new(
#         Variable.new(:x),
#         Assign.new(:y, Number.new(1)),
#         Assign.new(:y, Number.new(2))
#     ),
#     {x: Boolean.new(true)}
# ).run
# Machine.new(
#     Sequence.new(
#         Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#         Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
#     ),
#     {}
# ).run          

# Machine.new(
#     While.new(
#         LessThan.new(Variable.new(:x), Number.new(5)),
#         Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
#     ),
#     { x: Number.new(1)}
# ).run

# LessThan.new(
#     Add.new(Variable.new(:x), Number.new(2)),
#     Variable.new(:y)
# ).evaluate({ x: Number.new(2), y: Number.new(5) })
# statement = 
#     Sequence.new(
#         Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
#         Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
#     )
# puts statement
# puts statement.evaluate({})

# statement = 
#     While.new(
#         LessThan.new(Variable.new(:x), Number.new(5)),
#         Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
#     )
# puts statement
# puts statement.evaluate({ x: Number.new(1) })

# p Number.new(5).to_ruby
# proc = eval(Number.new(5).to_ruby)
# p proc.call({})
# p Boolean.new(false).to_ruby
# proc = eval(Boolean.new(false).to_ruby)
# p proc.call({})
# p expression = Variable.new(:x)
# p expression.to_ruby
# proc = eval(expression.to_ruby)
# p proc.call({x: 7})
# p Add.new(Variable.new(:x), Number.new(1)).to_ruby
# p LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby
# environment = { x: 3 }
# p environment
# proc = eval(Add.new(Variable.new(:x), Number.new(1)).to_ruby)
# p proc.call(environment)
# proc = eval(LessThan.new(Add.new(Variable.new(:x), Number.new(1)), Number.new(3)).to_ruby)
# p proc.call(environment)

# statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
# p statement
# p statement.to_ruby
# proc = eval(statement.to_ruby)
# p proc.call({ x:3 })

statement =
    While.new(
    LessThan.new(Variable.new(:x), Number.new(5)),
    Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
    )
p statement
p statement.to_ruby
proc = eval(statement.to_ruby)
p proc.call({ x: 1})