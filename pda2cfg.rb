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
    @valid_rules = []
  end

  def add_transition(initial_state, from_tape, from_stack)
    @transitions[[initial_state, from_tape, from_stack]] ||= []
    @transitions[[initial_state, from_tape, from_stack]].push( yield )
    yield
  end

  def cfg
    @cfg ||= create_cfg
  end

  def create_cfg
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




  def compute(str)
    a = compute_rec(@q_init, str, 0, [], cfg)
    a.map{|s| draw_result(s)}.join("\n")
  end

  def draw_result(arr)
    "$\\delta(q_{#{arr[0][1]}}, #{arr[1] || '\\epsilon'}, #{arr[2] || 'vazia'}) = (q_{#{arr[3][1]}}, #{arr[4].to_s.gsub("e", "\\epsilon")})$\\\\"
  end

  def compute_rec(q, tape, idx, stack, g, path=[])
    return path if stack.count==0 && q==@q_accept
    
    @x ||= nil
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
        pp = path.clone.push([q, symb, stack_head, new_q, stack_element])
        res = compute_rec(new_q, tape, (t_key[1]==:e ? idx : (idx + 1)), stk, g, pp)
        return res unless res.nil?
      end
    end
    return nil
  end

  def check_valid_rules()
    @valid_rules = []
    g = cfg
    
    same_length = -1
    past = 0
    
    while same_length!=past
      g.each do |rule|      
        rule.last.each do |symbol|
          symbol.each do |var_or_terminal|
            if ["0", "1", :e].include?(var_or_terminal)
              @valid_rules.push(rule.first).uniq!
            end
          end
        end      
      end
      past = same_length
      same_length = @valid_rules.count
    end    

  end

  def cfg_latex(g)
    #check_valid_rules if mark_valid_rules!=0
    
    # mark initial variable and set rule as first one
    initial_state = [@q_init, @q_accept]
    k = g.keys.select{|s| s==initial_state}.first
    str = rule_string(k, g[k])
    
    # draw other rules
    g.keys.reject{|k| k==initial_state}.each do |key|
      str += rule_string(key, g[key])
    end    
    
    str
  end

  def valid_rules_set
    g = cfg.clone
    check_valid_rules
    
    g.keys.each do |g_key|
      if @valid_rules.include? g_key
      else
        g.delete(g_key)
      end
    end

    g.keys.each do |g_key|
      if @valid_rules.include? g_key
        g[g_key].map! do |stmt|
          puts "- - #{stmt} - "
          if (stmt - [:e]).map{|s| @valid_rules.include? s}.all? || stmt.map{|s| [:e, "0", "1"].include? s}.all?
            stmt
          else
            nil
          end
        end.compact!
      end
    end    
    g
  end

  def invalid_rules_set
    g = cfg.clone
    check_valid_rules
    # g.keys.each do |g_key|
    #   if @valid_rules.include? g_key
    #   else
    #     g.delete(g_key)
    #   end
    # end

    g.keys.each do |g_key|
      if @valid_rules.include? g_key
        g[g_key].map! do |stmt|
          puts "- - #{stmt} - "
          if (stmt - [:e]).map{|s| @valid_rules.include? s}.all? || stmt.map{|s| [:e, "0", "1"].include? s}.all?
            nil
          else
            stmt
          end
        end.compact!
      end
    end    
    g
  end

  def rule_string(key, arr_terms)  
    terms = arr_terms.map do |r|
      r.map{|s| varstr(s)}.join("")
    end
    terms = terms.select{|s| s!= ""}.join(" ~|~ ")
    terms = terms.gsub("eA", "A").gsub("}e", "}")
    terms = terms.gsub("e", "\\epsilon ")
    
    return "$#{varstr(key)} \\rightarrow #{terms}$\\\\\n"
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





#puts pda2cfg.cfg_latex(pda2cfg.cfg)
puts "***********************"
puts pda2cfg.cfg_latex(pda2cfg.invalid_rules_set)
puts ""
#puts pda2cfg.compute("0110110110")