--------------------------------------------------------------------------------
-- Engineer: Geoff Gillett
-- Date:15 Jan 2016
--
-- Design Name: TES_digitiser
-- Module Name: boolean_vector
-- Project Name: extensions
-- Target Devices: virtex6
-- Tool versions: ISE 14.7
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package boolean_vector is
type boolean_vector is array (natural range <>) of boolean;
	
--------------------------------------------------------------------------------
-- Conversions between boolean_vector and std_logic or unsigned
--------------------------------------------------------------------------------
function to_boolean(a:std_logic) return boolean; 
function to_boolean(sv:std_logic_vector) return boolean_vector;
function to_boolean(i,w:natural) return boolean_vector;
function to_boolean(u:unsigned) return boolean_vector;
function to_std_logic(a:boolean) return std_logic;
function to_std_logic(b:boolean_vector) return std_logic_vector;
function to_unsigned(b:boolean_vector) return unsigned;
function to_unsigned(b:boolean) return unsigned;
function to_integer(b:boolean) return integer;
function to_integer(b:boolean_vector) return integer;
function resize(b:boolean_vector;s:natural) return boolean_vector;
--------------------------------------------------------------------------------
-- Bitwise boolean logic on boolean_vector
--------------------------------------------------------------------------------
function "and" (l,r:boolean_vector) return boolean_vector;
function "or" (l,r:boolean_vector) return boolean_vector;
function "not" (a:boolean_vector) return boolean_vector;
	
end package boolean_vector;

package body boolean_vector is
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

function to_unsigned(b:boolean_vector) return unsigned is
begin
  return unsigned(to_std_logic(b));
end function;

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

function to_boolean(i,w:natural) return boolean_vector is
begin
	return to_boolean(std_logic_vector(to_unsigned(i,w)));
end function to_boolean;

function to_unsigned(b:boolean) return unsigned is
begin
	if b then 
		return to_unsigned(1,1);
	else 
		return to_unsigned(0,1);
	end if;
end function;

function to_boolean(u:unsigned) return boolean_vector is
begin
	return to_boolean(std_logic_vector(u));
end function;

function to_integer(b:boolean) return integer is
begin 
  return to_integer(to_unsigned(b));
end function;

function to_integer(b:boolean_vector) return integer is
begin 
  return to_integer(to_unsigned(b));
end function;

function resize(b:boolean_vector;s:natural) return boolean_vector is
begin
	return to_boolean(resize(to_unsigned(b),s));
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

end package body boolean_vector;
