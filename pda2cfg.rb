# Arthur Tofani - 3339712

require 'pry'

class Pda2Cfg


  def initialize(states, alphabet, stack_alphabet, q_init, q_accept)
    @states = states
    @alphabet = alphabet
    @stack_alphabet = stack_alphabet
    @transitions = {}
    @q_init = q_init
    @q_accept = q_accept
    @rules = {}
  end

  def add_transition(initial_state, from_tape, from_stack)
    @transitions[[initial_state, from_tape, from_stack]] ||= []
    @transitions[[initial_state, from_tape, from_stack]].push( yield )
    yield
  end

  def cfg
    @states.each do |p|
      @states.each do |q|
        @states.each do |r|          
          @states.each do |s|
            @stack_alphabet.each do |t| # TODO: remove ε
              @alphabet.each do |a|
                @alphabet.each do |b|
                  tr1 = (@transitions[[p, a, :e]] || [])
                  tr2 = (@transitions[[s, b, t]] || [])
                  tr1.each do |tpl1|
                    tr2.each do |tpl2|
                      if tpl1==[r, t] && tpl2==[q, :e]
                        add_rule([p, q], [a, [r, s], b])
                      end                                    
                    end
                  end

                end
              end
            end

          end

          add_rule([p, q], [[p, r], [r, q]])
        end
      end      

      add_rule([p, p], [:e])
    end

    @rules
  end

  # var is a pair of start and end states; statement is an array of symbols U vars
  def add_rule(var, statement)
    @rules[var] ||= []
    @rules[var].push(statement)
  end

  def cfg_latex
    g = cfg
    
    # mark initial variable and set rule as first one
    initial_state = [@q_init, @q_accept]
    str = rule_string(g.keys.select{|s| s==initial_state}.first)
    
    # draw other rules
    g.keys.reject{|k| k==initial_state}.each do |key|
      str += rule_string(key)
    end    
    
    str
  end




  def compute(str)
    compute_rec(@q_init, str, 0, [], cfg)
  end

  def compute_rec(q, tape, idx, stack, g, path=nil)
    return path if stack.count==0 && q==@q_accept
    
    @x ||= nil
    path ||= q.to_s    
    symb = tape[idx]
    stack_head = stack.last
    
    transitions_keys = @transitions.keys.select{|s| s[0]==q && [:e, symb].include?(s[1]) && [:e, stack_head].include?(s[2])}
    transitions_keys.each do |t_key|      
      @transitions[t_key].each do |transition|
        new_q = transition[0]
        stack_element = transition[1]
        stk = stack.clone
        if stack_element==:e
          stk.pop()
        else
          stk.push(stack_element)
        end
        res = compute_rec(new_q, tape, (t_key[1]==:e ? idx : (idx + 1)), stk, g, "#{path}_#{new_q.to_s}")  
        return res unless res.nil?
      end
    end
    return nil
  end




  def rule_string(key)
      str = "#{varstr(key)} \\rightarrow " + @rules[key].map{|r| r.map{|s| varstr(s)}.join("")}.join(" ~|~ ").gsub("e", "\\epsilon ")
      "$#{str}$\\\\\n"
  end

  def varstr(var)    
    if var.class==Array
      "A_{#{var.first.to_s.tr('q', '')}#{var.last.to_s.tr('q', '')}}"
    else
      return var.to_s
    end
  end

end





states = [:q1, :q2, :q3, :q4, :q5, :q6]
pda2cfg = Pda2Cfg.new(states, ["0", "1", :e], ["0", "1", "$", "@"], :q1, :q4)

pda2cfg.add_transition(:q1, :e, :e){[:q2, "$"]}
pda2cfg.add_transition(:q2, "1", :e){[:q2, "1"]}
pda2cfg.add_transition(:q2, "0", :e){[:q2, "0"]}
pda2cfg.add_transition(:q2, :e, :e){[:q5, "@"]}
pda2cfg.add_transition(:q5, :e, "@"){[:q3, :e]}
pda2cfg.add_transition(:q3, "0", "0"){[:q3, :e]}
pda2cfg.add_transition(:q3, "1", "1"){[:q3, :e]}
pda2cfg.add_transition(:q3, :e, "$"){[:q4, :e]}

#adapting q4 to be the only acceptance state
pda2cfg.add_transition(:q1, :e, :e){[:q6, "$"]}
pda2cfg.add_transition(:q6, :e, "$"){[:q4, :e]}

puts pda2cfg.cfg_latex
puts ""
puts pda2cfg.compute("0110110110")