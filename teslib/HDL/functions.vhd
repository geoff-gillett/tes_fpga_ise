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

library extensions;
use extensions.boolean_vector.all;
use extensions.logic.all;

use work.dsptypes.all;

package functions is
function padLeft(slv:std_logic_vector;length:integer) return std_logic_vector;
--------------------------------------------------------------------------------
-- Conversions to string
--------------------------------------------------------------------------------
function to_string(arg:std_logic_vector) return string;
function to_string(u:unsigned) return string;
function to_string(arg:std_logic) return string;
function to_string(arg:integer) return string;
--------------------------------------------------------------------------------
-- Miscellaneous functions
--------------------------------------------------------------------------------
function to_onehot(u:unsigned;w:natural) return std_logic_vector;
function to_onehot(i,w:natural) return std_logic_vector;
function is_saturated(arg:unsigned) return boolean;
function is_saturated(arg:std_logic_vector) return boolean;
--function ceilLog2(a:integer) return integer;
function maximum(l,r:integer) return integer;
function minimum(l,r:integer) return integer;
function oneHotToInteger(oneHot:std_logic_vector) return integer;
--saturating addition r = a1+a2 
function saturatingAddition(a1,a2:signed) return signed;
end;
package body functions is  

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
-- Miscellaneous functions
--------------------------------------------------------------------------------
function to_onehot(u:unsigned;w:natural) return std_logic_vector is
begin
	return to_onehot(to_integer(u),w); 
end function;

function to_onehot(i,w:natural) return std_logic_vector is
variable slv:std_logic_vector(w-1 downto 0):=(others => '0');
begin
	slv(i):='1';
	return slv;
end function;

function is_saturated(arg:unsigned) return boolean is
begin
  return unaryAnd(std_logic_vector(arg));
end function;

function is_saturated(arg:std_logic_vector) return boolean is
begin
  return unaryAnd(arg);
end function;

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