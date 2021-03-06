{
  var n = require('./nodes');
  var helpers = require('./grammar-helpers');
}

start
  = Program

ws "Whitespace"
   = [\t\v\f \u00A0\uFEFF]
_
  = ws*

__
  = ws+

_EOL
  = (ws / EndOfLine)*

Identifier "Identfier"
  = name:([a-zA-Z0-9+-] / '_')+
     { return name.join(""); }

VariableIdentifier "Variable Identfier"
  = head:'$'? tail:([a-zA-Z0-9+-] / '_')+
     { return head + tail.join(""); }

FunctionIdentifier "Function Identifier"
  = name:([a-zA-Z0-9+-:] / '_')+
     { return name.join(""); }

EndOfLine "End of Line"
  = '\n'
  / "\r\n"
  / "\r"

BooleanLiteral
  = "true" { return true; }
  / "false" { return false; }

Program
  = program:(Statement Comment? StatementSeperator)* StatementSeperator?
    { return new n.Block(helpers.filterProgram(program)).p(line, column); }

StatementSeperator
  = ( _ (EndOfLine / ';') _ )+

Block
  = _ "{" _ EndOfLine* _ program:Program _ "}"
     { return program; }

Statement
  = VariableAssignment
  / FunctionDeclaration
  / EnumerationDeclaration
  / FunctionCall
  / IfStatement
  / Command
  / Comment

VariableAssignment "Variable Assignment"
  = name:VariableIdentifier _ "=" _ expr:BooleanLiteral
    { return new n.VariableAssignment(name, expr).p(line, column); }

FunctionDeclaration "Function Declaration"
  = "function" __ name:FunctionIdentifier _ "()" _ expr:Block
    { return new n.FunctionDeclaration(name, expr).p(line, column); }

EnumerationDeclaration "Enumeration Declaration"
  = "enum" __ name:Identifier _ '{' _EOL content:BlockList _EOL '}'
    { return new n.EnumerationDeclaration(name, content).p(line, column); }

BlockList
  = head:Block tail:(',' _EOL Block)*
    { return [head].concat(helpers.every(2, tail)); }

FunctionCall "Function Call"
  = name:FunctionIdentifier _ "()"
     { return new n.FunctionCall(name).p(line, column); }

IfStatement "If Statement"
  = "if" __ condition:Condition _ yes:Block _ "else" _ no:Block
     { return new n.IfStatement(condition, yes, no).p(line, column); }
  / "if" __ condition:Condition _ yes:Block
     { return new n.IfStatement(condition, yes).p(line, column); }

Condition
  = negated:'!'? _ condition:VariableIdentifier
     { return new n.Condition(condition, negated != "").p(line, column); }

Command "Command"
  = name:Identifier args:(__ (CommandArgument _)*)?
     { return new n.Command(name, args == "" ? [] : helpers.every(0, args[1])).p(line, column); }

CommandArgument
  = '"' content:(!'"' .)* '"' { return helpers.every(1, content).join(""); }
  / content:(!(ws / EndOfLine / '{' / '#') .)+ { return helpers.every(1, content).join(""); }
  / Block

Comment "Comment"
  = '#' content:(!EndOfLine .)*
     { return new n.Comment(helpers.every(1, content).join("")); }
