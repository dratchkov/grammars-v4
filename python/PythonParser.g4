// Header included from Python site:
/*
 * Grammar for Python
 *
 * Note:  Changing the grammar specified in this file will most likely
 *        require corresponding changes in the parser module
 *        (../Modules/parsermodule.c).  If you can't make the changes to
 *        that module yourself, please co-ordinate the required changes
 *        with someone who can; ask around on python-dev for help.  Fred
 *        Drake <fdrake@acm.org> will probably be listening there.
 *
 * NOTE WELL: You should also follow all the steps listed in PEP 306,
 * "How to Change Python's Grammar"
 *
 * Start symbols for the grammar:
 *       single_input is a single interactive statement;
 *       file_input is a module or sequence of commands read from an input file;
 *       eval_input is the input for the eval() and input() functions.
 * NB: compound_stmt in single_input is followed by extra NEWLINE!
 */
parser grammar PythonParser;

options { tokenVocab=PythonLexer; }

root
    : (single_input
    | file_input
    | eval_input)? EOF
    ;

single_input
    : NEWLINE
    | simple_stmt
    | compound_stmt NEWLINE
    ;

file_input
    : (NEWLINE | stmt)+
    ;

eval_input
    : testlist NEWLINE*
    ;

decorator
    : AT dotted_name (OPEN_PAREN arglist? CLOSE_PAREN)? NEWLINE
    ;

//python 3 paramters
// parameters list may have a trailing comma
typedargslist
    : (def_parameters COMMA)? (args (COMMA def_parameters)? (COMMA kwargs)? | kwargs) COMMA?
    | def_parameters COMMA?
    ;

args
    : STAR named_parameter
    ;

kwargs
    : POWER named_parameter
    ;

def_parameters
    : def_parameter (COMMA def_parameter)*
    ;

def_parameter
    : named_parameter (ASSIGN test)?
    | STAR
    ;

named_parameter
    : name (COLON test)?
    ;

//python 2 paramteters
varargslist
    : (vardef_parameters COMMA)? varargs (COMMA vardef_parameters)? (COMMA varkwargs)
    | vardef_parameters
    ;

vardef_parameters
    : vardef_parameter (COMMA vardef_parameter)*
    ;

vardef_parameter
    : name (ASSIGN test)?
    ;

varargs
    : STAR name
    ;

varkwargs
    : POWER name
    ;

stmt
    : simple_stmt
    | compound_stmt
    ;

simple_stmt
    : small_stmt (SEMI_COLON small_stmt)* SEMI_COLON? (NEWLINE | EOF)
    ;

small_stmt
    : testlist_star_expr assign_part?                                                 #expr_stmt
    | PRINT ((test (COMMA test)* COMMA?) | RIGHT_SHIFT test ((COMMA test)+ COMMA?))   #print_stmt   // Python 2
    | DEL exprlist                                                                    #del_stmt
    | PASS                                                                            #pass_stmt
    | BREAK                                                                           #break_stmt
    | CONTINUE                                                                        #continue_stmt
    | RETURN testlist?                                                                #return_stmt
    | RAISE (test (COMMA test (COMMA test)?)?)? (FROM test)?                          #raise_stmt
    | yield_expr                                                                      #yield_stmt
    | IMPORT dotted_as_names                                                          #import_stmt
    | (FROM ((DOT | ELLIPSIS)* dotted_name | (DOT | ELLIPSIS)+)
       IMPORT (STAR | OPEN_PAREN import_as_names CLOSE_PAREN | import_as_names))      #from_stmt
    | GLOBAL name (COMMA name)*                                                       #global_stmt
    | EXEC expr (IN test (COMMA test)?)?                                              #exec_stmt
    | ASSERT test (COMMA test)?                                                       #assert_stmt
    | NONLOCAL name (COMMA name)*                                                     #nonlocal_stmt // Python 3
    ;

testlist_star_expr
    : (test | star_expr) (COMMA (test | star_expr))* COMMA?
    ;

assign_part
    : (ASSIGN (yield_expr | testlist_star_expr))+  // if left expression in assign is bool literal, it's mean that is Python 2 here
    | COLON test (ASSIGN (yield_expr | testlist))? // annassign Python3 rule
    | op=( ADD_ASSIGN
         | SUB_ASSIGN
         | MULT_ASSIGN
         | AT_ASSIGN
         | DIV_ASSIGN
         | MOD_ASSIGN
         | AND_ASSIGN
         | OR_ASSIGN
         | XOR_ASSIGN
         | LEFT_SHIFT_ASSIGN
         | RIGHT_SHIFT_ASSIGN
         | POWER_ASSIGN
         | IDIV_ASSIGN
         )
      (yield_expr | testlist)
    ;

import_as_names
    : import_as_name (COMMA import_as_name)* COMMA?
    ;

import_as_name
    : name (AS name)?
    ;

dotted_as_names
    : dotted_as_name (COMMA dotted_as_name)*
    ;

dotted_as_name
    : dotted_name (AS name)?
    ;

compound_stmt
    : IF cond=test COLON suite elif_clause* else_clause?                           #if_stmt
    | WHILE test COLON suite else_clause?                                          #while_stmt
    | ASYNC? FOR exprlist IN testlist COLON suite else_clause?                     #for_stmt
    | TRY COLON suite (except_clause+ else_clause? finaly_clause? | finaly_clause) #try_stmt
    | ASYNC? WITH with_item (COMMA with_item)* COLON suite                         #with_stmt
    | decorator* (classdef | funcdef)                                              #class_or_func_def_stmt
    ;

elif_clause
    : ELIF test COLON suite
    ;

else_clause
    : ELSE COLON suite
    ;

finaly_clause
    : FINALLY COLON suite
    ;

with_item
    // NB compile.c makes sure that the default except clause is last
    : test (AS expr)?
    ;

// Python 2 : EXCEPT test COMMA name
// Python 3 : EXCEPT test AS name
except_clause
    : EXCEPT (test (COMMA name | AS name)?)? COLON suite
    ;

suite
    : simple_stmt
    | NEWLINE INDENT stmt+ DEDENT
    ;

// https://docs.python.org/3/reference/expressions.html#operator-precedence
test
    : logical_test (IF logical_test ELSE test)?
    | LAMBDA varargslist? COLON test
    ;

logical_test
    : comparison
    | NOT logical_test
    | logical_test op=AND logical_test
    | logical_test op=OR logical_test
    ;

comparison
    : comparison (LESS_THAN | GREATER_THAN | EQUALS | GT_EQ | LT_EQ | NOT_EQ_1 | NOT_EQ_2 | IN | IS optional=NOT? | NOT optional=IN?) comparison
    | expr
    ;

expr
    : AWAIT? atom trailer*
    | <assoc=right> expr op=POWER expr
    | op=(ADD | MINUS | NOT_OP) expr
    | expr op=(STAR | DIV | MOD | IDIV | AT) expr
    | expr op=(ADD | MINUS) expr
    | expr op=(LEFT_SHIFT | RIGHT_SHIFT) expr
    | expr op=AND_OP expr
    | expr op=XOR expr
    | expr op=OR_OP expr
    ;

atom
    : OPEN_PAREN (yield_expr | testlist_comp)? CLOSE_PAREN
    | OPEN_BRACKET testlist_comp? CLOSE_BRACKET
    | OPEN_BRACE dictorsetmaker? CLOSE_BRACE
    | REVERSE_QUOTE testlist COMMA? REVERSE_QUOTE
    | dotted_name
    | ELLIPSIS
    | name
    | PRINT
    | EXEC
    | MINUS? number
    | NONE
    | STRING+
    ;

dotted_name
    : dotted_name DOT name
    | name
    ;

yield_expr
    : YIELD yield_arg?
    ;

testlist_comp
    : (test | star_expr) (comp_for | (COMMA (test | star_expr))* COMMA?)
    ;

name
    : NAME
    | TRUE
    | FALSE
    ;

number
    : integer
    | IMAG_NUMBER
    | FLOAT_NUMBER
    ;

integer
    : DECIMAL_INTEGER
    | OCT_INTEGER
    | HEX_INTEGER
    | BIN_INTEGER
    ;

trailer
    : OPEN_PAREN arglist? CLOSE_PAREN
    | OPEN_BRACKET subscriptlist CLOSE_BRACKET
    | DOT name
    ;

subscriptlist
    : subscript (COMMA subscript)* COMMA?
    ;

subscript
    : ELLIPSIS
    | test
    | test? COLON test? sliceop?
    ;

sliceop
    : COLON test?
    ;

exprlist
    : expr (COMMA expr)* COMMA?
    ;

testlist
    : test (COMMA test)* COMMA?
    ;

dictorsetmaker
    : (test COLON test | POWER expr) (comp_for | (COMMA (test COLON test | POWER expr))* COMMA?)
    | (test | star_expr) (comp_for | (COMMA (test | star_expr))* COMMA?)
    ;

star_expr
    : STAR expr
    ;

classdef
    : CLASS name (OPEN_PAREN arglist? CLOSE_PAREN)? COLON suite
    ;

funcdef
    : ASYNC? DEF name OPEN_PAREN typedargslist? CLOSE_PAREN (ARROW test)? COLON suite
    ;

arglist
    // The reason that keywords are test nodes instead of name is that using name
    // results in an ambiguity. ast.c makes sure it's a name.
    : argument (COMMA argument)* COMMA?
    ;

argument
    : test (comp_for | ASSIGN test)?
    | (POWER | STAR) test
    ;

list_iter
    : FOR exprlist IN testlist_safe list_iter?
    | IF test list_iter?
    ;

// Backward compatibility cruft to support:
// [ x for x in lambda: True, lambda: False if x() ]
// even while also allowing:
// lambda x: 5 if x else 2
// (But not a mix of the two)
testlist_safe
    : test ((COMMA test)+ COMMA?)?
    ;

comp_iter
    : comp_for
    | IF test comp_iter?
    ;

comp_for
    : FOR exprlist IN logical_test comp_iter?
    ;

yield_arg
    : FROM test
    | testlist
    ;