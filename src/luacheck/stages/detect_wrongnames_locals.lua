--local utils = require "luacheck.utils"

local stage = {}

stage.warnings = {
   ["701"] = {message_format = "local function {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["702"] = {message_format = "function argument {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["703"] = {message_format = "local variable {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["704"] = {message_format = "pair/ipair iterator {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["705"] = {message_format = "pair/ipair value {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["706"] = {message_format = "for loop variable {name!} should be in {case} camelcase", fields = {"name", "case"}},
   ["354"] = {message_format = "mutating pair/ipair iterator {name!}", fields = {"name"}},
   ["355"] = {message_format = "mutating pair/ipair value {name!}", fields = {"name"}},
   ["356"] = {message_format = "mutating for loop variable {name!}", fields = {"name"}}
}

local function detect_startcase_not_upper(chstate, value, code)
    if value.var.name:byte(1) < 65 or value.var.name:byte(1) > 90 then
      local warning = {}
      warning.case = "upper"
      chstate:warn_value(code, value, warning)
    end
end

local function detect_startcase_not_lower(chstate, value, code)
    if value.var.name:byte(1) < 97 or value.var.name:byte(1) > 122 then
      local warning = {}
      warning.case = "lower"
      chstate:warn_value(code, value, warning)
    end
end

local function is_function_var(var)
   return (#var.values == 1 and var.values[1].type == "func") or
            (#var.values == 2 and var.values[1].empty and var.values[2].type == "func")
end

local function is_variable_index(value)
  if #value.item.lhs == 2 then
    return (value.item.lhs[1].offset > value.var_node.offset) or
             (value.item.lhs[2].offset > value.var_node.offset )
  end
  return true
end

local function detect_unused_local(chstate, var)
   if is_function_var(var) then
      local value = var.values[2] or var.values[1]
      detect_startcase_not_upper(chstate, value, "701")
   elseif #var.values >= 1 then
      local value = var.values[1]
      if value.var.name ~= '_' and value.var.name ~= 'self' then
        if value.type == "var" then
          detect_startcase_not_lower(chstate, value, "703")
        elseif value.type == "arg" then
          detect_startcase_not_lower(chstate, value, "702")
        elseif value.type == "loop" then
          if is_variable_index(value) then
            detect_startcase_not_lower(chstate, value, "704")
          else
            detect_startcase_not_lower(chstate, value, "705")
          end
        elseif value.type == "loopi" then
          detect_startcase_not_lower(chstate, value, "706")
        else
          print(var.values.type)
        end
      end
   else
    print("WTF")
   end
 end

local function detect_wrongnames_locals_in_line(chstate, line)
   for _, item in ipairs(line.items) do
      if item.tag == "Local" then
         for var in pairs(item.set_variables) do
            -- Do not check the implicit top level vararg.
            if var.node.line then
               detect_unused_local(chstate, var)
            end
         end
      end
   end
end

local function detect_wrongnames_locals(chstate)
   for _, line in ipairs(chstate.lines) do
      detect_wrongnames_locals_in_line(chstate, line)
   end
end

local function detect_mutating_loop_variables_in_assignment(chstate, declaration, assignment)
   if #declaration.values == 0 then return end

   if assignment.var.type == "loopi" then
      chstate:warn_value("356", assignment, {})
   elseif assignment.var.type == "loop" then
      if is_variable_index(declaration.values[1]) then
        chstate:warn_value("354", assignment, {})
      else
        chstate:warn_value("355", assignment, {})
      end
   end
end

local function detect_mutating_loop_variables_in_statement(chstate, statement)
   if statement.tag ~= "Set" then return end

   for declaration, assignment in pairs(statement.set_variables) do
      detect_mutating_loop_variables_in_assignment(chstate, declaration, assignment)
   end
end

local function detect_mutating_loop_variables(chstate)
   for _, line in ipairs(chstate.lines) do
      for _, statement in ipairs(line.items) do
         detect_mutating_loop_variables_in_statement(chstate, statement)
      end
   end
end

function stage.run(chstate)
   detect_wrongnames_locals(chstate)
   detect_mutating_loop_variables(chstate)
end

return stage
