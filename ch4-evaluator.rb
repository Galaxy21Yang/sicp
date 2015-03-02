#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

def _eval(exp, env)
  if self_evaluating?(exp)
    exp
  elsif variable?(exp)
    lookup_variable_value(exp, env)
  elsif quoted?(exp)
    text_of_quotation(exp)
  elsif assignment?(exp)
    eval_assignment(exp, env)
  elsif definition?(exp)
    eval_definition(exp, env)
  elsif if?(exp)
    eval_if(exp, env)
  elsif lambda?(exp)
    params = lambda_parameters(exp)
    body = lambda_body(exp)
    make_procedure(params, body, env)
  elsif begin?(exp)
    exps = begin_actions(exp)
    eval_sequence(exps, env)
  elsif cond?(exp)
    exp_if = cond_to_if(exp)
    eval_if(exp_if, env)
  elsif application?(exp)
    procedure = _eval(operator(exp) env)
    arguments = list_of_values(operands(exp) env)
    _apply(procedure, arguments)
  else
    raise "eval: unknown expression type: " + exp
  end
end

def _apply(procedure, arguments)
  if primitive_procedure?(procedure)
    apply_primitive_prodecure(procedure, arguments)
  elsif compound_procedure?(procedure)
    body = procedure_body(procedure)
    params = procedure_parameter(procedure)
    env = procedure_environment(procedure)
    eval_sequence(body, extend_environment(params, arguments, env))
  else
    raise "apply: unknown procedure type: " + procedure
  end
end

def cons(x, y)
  [a] + b
end

def car(list)
  list[0]
end

def cdr(list)
  list[1..-1]
end

def pair?(list)
  list.is_a?(Array) && list.length >= 2
end

# 手続きの引数
def list_of_values(exps, env)
  if no_operands?(exps)
    nil
  else
    cons(_eval(first_operand(exps), env),
         list_of_values(rest_operand(exps), env))
  end
end

# 条件文
def eval_if(exp, env)
  if true?(_eval(if_predicate(exp), env))
    _eval(if_consequent(exp), env)
  else
    _eval(if_alternative(exp), env)
  end
end

# シーケンス
def eval_sequence(exps, env)
  if last_exp?(exps)
    _eval(first_exp(exps), env)
  else
    _eval(first_exp(exps), env)
    eval_sequence(rest_exps(exps), env)
  end
end

# 代入
def eval_assignment(exp, env)
  var = assignment_variable(exp)
  value = _eval(assignment_value(exp), env)
  set_variable_value!(var, value, env)
end

# 定義
def eval_definition(exp, env)
  var = definition_variable(exp)
  value = _eval(definition_value(exp), env)
  definition_variable!(var, value, env)
end

# 数値/文字列
def self_evaluating?(exp)
  if number?(exp)
    true
  elsif string?(exp)
    true
  else
    false
  end
end

def number?(exp)
  exp.is_a?(Numeric)
end

def string?(exp)
  exp.is_a?(String)
end

# 変数
def variable?(exp)
  symbol?(exp)
end

def symbol?(exp)
  exp.is_a?(Symbol)
end

# クオート
def quoted?(exp)
  tagged_list?(exp, :quote)
end

def text_of_quotation(exp)
  car(cdr(exp))
end

def tagged_list?(exp, tag)
  if pair?(exp)
    car(exp) == tag
  else
    false
  end
end

# 代入
