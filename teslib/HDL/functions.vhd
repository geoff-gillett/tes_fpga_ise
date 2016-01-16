--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:26/06/2014 
--
-- Design Name: TES_digitiser
-- Module Name: functions
-- Project Name: TES_library
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.types.all;

package functions is
--------------------------------------------------------------------------------
-- Conversions between std_logic_vector and boolean_vector
--------------------------------------------------------------------------------
function to_boolean(a:std_logic) return boolean; 
function to_boolean(sv:std_logic_vector) return boolean_vector;
--function to_boolean(u:unsigned) return boolean_vector;
function to_boolean(i,w:integer) return boolean_vector;
function to_std_logic(a:boolean) return std_logic;
function to_std_logic(b:boolean_vector) return std_logic_vector;
function to_std_logic(u:unsigned) return std_logic_vector;
function to_std_logic(s:signed) return std_logic_vector;
function to_std_logic(i,w:integer) return std_logic_vector;
function padLeft(slv:std_logic_vector;length:integer) return std_logic_vector;
--------------------------------------------------------------------------------
-- Conversions to string
--------------------------------------------------------------------------------
function to_string(arg:std_logic_vector) return string;
function to_string(u:unsigned) return string;
function to_string(arg:std_logic) return string;
function to_string(arg:integer) return string;
--------------------------------------------------------------------------------
-- unaryOr OR all bits in the argument
--------------------------------------------------------------------------------
function unaryOR(arg:boolean_vector) return boolean; 
function unaryOR(arg:std_logic_vector) return boolean; 
function unaryOR(arg:unsigned) return boolean; 
--------------------------------------------------------------------------------
-- unaryAnd AND all bits in the argument
--------------------------------------------------------------------------------
function unaryAND(arg:std_logic_vector) return boolean;
function unaryAND(arg:boolean_vector) return boolean;
function unaryAND(arg:unsigned) return boolean;
--------------------------------------------------------------------------------
-- Bitwise boolean logic on boolean_vector
--------------------------------------------------------------------------------
function "and" (l,r:boolean_vector) return boolean_vector;
function "or" (l,r:boolean_vector) return boolean_vector;
function "not" (a:boolean_vector) return boolean_vector;
--------------------------------------------------------------------------------
-- shift registers
--------------------------------------------------------------------------------
function shift(arg:boolean;pipe:boolean_vector) return boolean_vector;
function shift(arg:std_logic;pipe:std_logic_vector) return std_logic_vector;
--------------------------------------------------------------------------------
-- Miscellaneous functions
--------------------------------------------------------------------------------
function is_saturated(arg:unsigned) return boolean;
function is_saturated(arg:std_logic_vector) return boolean;
function ceilLog2(a:integer) return integer;
function maximum(l,r:integer) return integer;
function minimum(l,r:integer) return integer;
function oneHotToInteger(oneHot:std_logic_vector) return integer;
--used to suppress warnings from numeric_std
function to_0IfX(slv:std_logic_vector) return std_logic_vector;
--used to suppress warnings from numeric_std
function to_0IfX(u:unsigned) return unsigned;
--used to suppress warnings from numeric_std
function to_0IfX(s:signed) return signed;
--saturating addition r = a1+a2 
function saturatingAddition(a1,a2:signed) return signed;
end;
package body functions is  
--------------------------------------------------------------------------------
-- Conversions between std_logic_vector and boolean_vector
--------------------------------------------------------------------------------
function to_std_logic(a:boolean) return std_logic is
begin
  if a then return('1'); else return('0'); end if;
end function to_std_logic;
function to_std_logic(b:boolean_vector) return std_logic_vector is
variable out_vector:std_logic_vector(b'range);
begin
  for i in b'range loop
    out_vector(i):=to_std_logic(b(i));
  end loop;
  return out_vector;
end function to_std_logic;
function to_std_logic(u:unsigned) return std_logic_vector is
begin
return std_logic_vector(u);
end function;
function to_std_logic(s:signed) return std_logic_vector is
begin
return std_logic_vector(s);
end function;
function to_std_logic(i,w:integer) return std_logic_vector is
begin
	return std_logic_vector(to_unsigned(i,w));
end function to_std_logic;
function to_boolean(a:std_logic) return boolean is
begin
  if a='1' then return(TRUE); else return(FALSE); end if;
end function to_boolean;
function to_boolean(sv:std_logic_vector) return boolean_vector is
variable out_vector:boolean_vector(sv'range);
begin
  for i in sv'range loop
    out_vector(i):=to_boolean(sv(i));
  end loop;
  return out_vector;
end function to_boolean;
--function to_boolean(u:unsigned) return boolean_vector is
--begin
--	return to_boolean(std_logic_vector(u));
--end function to_boolean;
function to_boolean(i,w:integer) return boolean_vector is
begin
	return to_boolean(to_std_logic(i,w));
end function to_boolean;
function padLeft(slv:std_logic_vector;length:integer) return std_logic_vector is
begin
  if length<slv'length then
    return slv(length-1 downto 0);
  else 
    return to_std_logic(to_unsigned(0,length-slv'length)) & slv;
  end if;
end function;
--------------------------------------------------------------------------------
-- Conversions to string
--------------------------------------------------------------------------------
function to_string(arg:std_logic_vector) return string is
variable s:string(arg'range);
begin
  for i in arg'range loop
    if arg(i)='1' then
      s(i):='1';
    else
      s(i):='0';
    end if;
  end loop;
  return s;
end function;
function to_string(arg:std_logic) return string is
begin
  if arg='1' then
    return "1";
  else
    return "0";
  end if;
end function;
function to_string(u:unsigned) return string is
variable s:string(u'range);
begin
  for i in u'range loop
    if u(i)='1' then
      s(i):='1';
    else
      s(i):='0';
    end if;
  end loop;
  return s;
end function;
function to_string(arg:integer) return string is
begin
  return integer'image(arg);
end function;
--------------------------------------------------------------------------------
-- unaryOr OR all bits in the argument
--------------------------------------------------------------------------------
function unaryOr(arg:boolean_vector) return boolean is
begin
  return unaryOr(to_std_logic(arg));
end function unaryOr;
function unaryOr(arg:std_logic_vector) return boolean is
variable b:std_logic:='0';
begin 
  for i in arg'range loop
    b:=b or arg(i);
  end loop;
  return b='1';
end function;
function unaryOr(arg:unsigned) return boolean is
begin
  return unaryOr(std_logic_vector(arg));
end function;
--------------------------------------------------------------------------------
-- unaryAnd AND all bits in the argument
--------------------------------------------------------------------------------
function unaryAnd(arg:std_logic_vector) return boolean is
variable b:std_logic:='1';
begin 
  for i in arg'range loop
    b:=b and arg(i);
  end loop;
  return b='1';
end function;
function unaryAnd(arg:boolean_vector) return boolean is
begin
  return unaryAnd(to_std_logic(arg));
end function;
function unaryAnd(arg:unsigned) return boolean is
begin
  return unaryAnd(std_logic_vector(arg));
end function;
--------------------------------------------------------------------------------
-- Bitwise boolean logic on boolean_vector
--------------------------------------------------------------------------------
function "and"(l,r:boolean_vector) return boolean_vector is
begin
  return to_boolean(to_std_logic(l) and to_std_logic(r));
end function "and";
function "or" (l,r:boolean_vector) return boolean_vector is
begin
  return to_boolean(to_std_logic(l) or to_std_logic(r));
end function "or";
function "not" (a:boolean_vector) return boolean_vector is
begin
  return to_boolean(not to_std_logic(a));
end function "not";
--------------------------------------------------------------------------------
-- boolean_vector as shift register
--------------------------------------------------------------------------------
function shift(arg:std_logic;pipe:std_logic_vector) 
return std_logic_vector is
begin
  return arg & pipe(pipe'low to pipe'high-1);
end function;
function shift(arg:boolean;pipe:boolean_vector) return boolean_vector is
begin
  return to_boolean(shift(to_std_logic(arg),to_std_logic(pipe)));
end function;
--------------------------------------------------------------------------------
-- Miscellaneous functions
--------------------------------------------------------------------------------
function is_saturated(arg:unsigned) return boolean is
begin
  return unaryAnd(std_logic_vector(arg));
end function;
function is_saturated(arg:std_logic_vector) return boolean is
begin
  return unaryAnd(arg);
end function;
function ceilLog2(a:integer) return integer is
begin
  if a<=1 then return 1;
  else return integer(ceil(log2(real(a))));
  end if;
end function ceilLog2;
function maximum(l,r:integer) return integer is
begin
  if l>r then return l;
  else return r;
  end if;
end function maximum;
function minimum(l,r:integer) return integer is
begin
  if l<r then return l;
  else return r;
  end if;
end function minimum;
function oneHotToInteger(oneHot:std_logic_vector) return integer is
variable binary:integer range oneHot'range;
variable bin:std_logic_vector(ceilLog2(oneHot'high)-1 downto 0):=(others => '0');
begin 
  for i in oneHot'range loop
    if oneHot(i)='1' then
      bin:=bin or std_logic_vector(to_unsigned(i,ceilLog2(oneHot'high)));
    end if;
  end loop;
  binary:=to_integer(unsigned(bin));
  return binary;
end function;
function to_0IfX(slv:std_logic_vector) return std_logic_vector is
variable result:std_logic_vector(slv'range);
begin
  if (is_X(slv)) then
    result:=(others => '0');
  else
    result := slv;
  end if; 
  return result;
end function;
function to_0IfX(u:unsigned) return unsigned is
begin
  return unsigned(to_0Ifx(std_logic_vector(u)));
end function;
function to_0IfX(s:signed) return signed is
begin
  return signed(to_0Ifx(std_logic_vector(s)));
end function;
-- assumes that a1 is the longest argument
-- and that a1 and a2 are already sign extended
-- and that a1,a2 downto 
function saturatingAddition(a1,a2:signed) return signed is
variable temp:signed(a1'high downto 0);
variable flags:std_logic_vector(2 downto 0);
variable result:signed(a1'high downto 0);
begin
temp:=a1 + a2;
flags:=a1(a1'high) & a2(a2'high) & temp(temp'high);
case flags is
when "011" => --underflow
    result:=(others => '0');
	result(result'high):='1';
	return(result);
when "100" => --overflow
	result:=(others =>'1');
	result(result'high):='0';
	return(result);
when others => 
	return(temp);
end case;
end function saturatingAddition;
end;