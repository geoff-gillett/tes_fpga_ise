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
use ieee.math_real.all;

use work.boolean_vector.all;

package logic is
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
-- shift registers
--------------------------------------------------------------------------------
function shift(arg:std_logic;pipe:std_logic_vector) return std_logic_vector;
function shift(arg:boolean;pipe:boolean_vector) return boolean_vector;
	
--------------------------------------------------------------------------------
-- Conversions to std_logic_vector
--------------------------------------------------------------------------------
function to_std_logic(u:unsigned) return std_logic_vector;
function to_std_logic(s:signed) return std_logic_vector;
function to_std_logic(i,w:integer) return std_logic_vector;
	
--------------------------------------------------------------------------------
-- Miscellaneous functions
--------------------------------------------------------------------------------
-- to_0IfX is used to suppress warnings from numeric_std during simulation
function to_0IfX(slv:std_logic_vector) return std_logic_vector;
function to_0IfX(u:unsigned) return unsigned;
function to_0IfX(s:signed) return signed;
function ceilLog2(a:natural) return natural;
function minbits(a:natural) return natural;
-- reshape shifts and resizes to output width and frac
function reshape(u:unsigned;in_frac,width,frac:integer) return unsigned;
function reshape(s:signed;in_frac,width,frac:integer) return signed;

function resize(slv:std_logic_vector;w:natural) return std_logic_vector;
function resize(s:signed;w:natural) return std_logic_vector;
function resize(u:unsigned;w:natural) return std_logic_vector;
	
function swapEndian(data:std_logic_vector) return std_logic_vector;
function swapEndian(data:unsigned) return std_logic_vector;
function swapEndian(data:signed) return std_logic_vector;
function setEndian(d:std_logic_vector;e:string) return std_logic_vector;
function setEndian(u:unsigned;e:string) return std_logic_vector;
function setEndian(s:signed;e:string) return std_logic_vector;
  
end package logic;

package body logic is

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
-- Shift register functions
--------------------------------------------------------------------------------
function shift(arg:std_logic;pipe:std_logic_vector) 
return std_logic_vector is
begin
  return arg & pipe(pipe'low to pipe'high-1);
end function;

function shift(arg:boolean;pipe:boolean_vector) return boolean_vector is
begin
  return arg & pipe(pipe'low to pipe'high-1);
end function;

--------------------------------------------------------------------------------
-- Conversions to std_logic_vector
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Miscellaneous functions
--------------------------------------------------------------------------------
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

function ceilLog2(a:natural) return natural is
begin
  if a<=1 then return 1;
  else return integer(ceil(log2(real(a))));
  end if;
end function ceilLog2;

--minimum bits needed to represent a ie 2 takes 3 bits
function minbits(a:natural) return natural is
variable l:real;
begin
  l:=log2(real(a+1));
  return natural(ceil(l));
end function minbits;

function reshape(u:unsigned;in_frac,width,frac:integer) return unsigned is
begin
	if IN_FRAC > FRAC then
		return resize(shift_right(u,in_frac-frac),width);
	else
		return resize(shift_left(u,frac-in_frac),width);
	end if;
end function;
	
function reshape(s:signed;in_frac,width,frac:integer) return signed is
begin
	if IN_FRAC > FRAC then
		return shift_right(resize(s,width),in_frac-frac);
	else
		return shift_left(resize(s,width),frac-in_frac);
	end if;
end function;

-- FIXME remove this?
function resize(slv:std_logic_vector;w:natural) return std_logic_vector is
begin
  return resize(unsigned(slv),w);
end function;

function resize(s:signed;w:natural) return std_logic_vector is
  variable o:signed(w-1 downto 0);
begin
  o:=resize(s,w);
  return std_logic_vector(o);
end function;

function resize(u:unsigned;w:natural) return std_logic_vector is
  variable o:unsigned(w-1 downto 0);
begin
  o:=resize(u,w);
  return std_logic_vector(o);
end function;
--function resize(slv:std_logic_vector;w:natural) return std_logic_vector is
--variable o:std_logic_vector(w-1 downto 0) := (others => '0');
--begin
--  
--	if slv'length >= w then
--		o := slv(w-1 downto 0); --FIXME this fails, why?
--	else
--		o(slv'length-1 downto 0) := slv;
--	end if;
--	return o;
--end function;

--function resize(slv:std_logic_vector;w:natural) return std_logic_vector is
--variable o:std_logic_vector(w-1 downto 0) := (others => '0');
--begin
--	if slv'length >= w then
--		o := slv(w-1 downto 0);
--	else
--		o(slv'length-1 downto 0) := slv;
--	end if;
--	return o;
--end function;
	
-- assumes data is a multiple of 8 bits and big endian and downto 
function swapEndian(data:std_logic_vector) return std_logic_vector is
variable rev:std_logic_vector(data'range);
constant BYTES:integer:=(data'high-data'low+1)/8;
begin
  assert data'length mod 8 = 0 
    report "data must be multiple of 8 bits" severity FAILURE;
  for i in 0 to BYTES-1 loop
    rev(data'high-i*8 downto data'high-(i+1)*8+1)
    	:=data((i+1)*8+data'low-1 downto i*8+data'low);
  end loop; 
  if (data'length>8*BYTES) then
    rev(data'length-8*BYTES-1 downto 0):=data(data'high downto 8*BYTES);
  end if;
  return rev;
end function;

-- assumes data is a multiple of 8 bits and big endian and downto
-- returns outlength-1 downto 0 

function SwapEndian(data:unsigned) return std_logic_vector is
begin
  return(SwapEndian(std_logic_vector(data)));
end function;

function SwapEndian(data:signed) return std_logic_vector is
begin
  return(SwapEndian(std_logic_vector(data)));
end function;

function setEndian(d:std_logic_vector;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndian(d);
	else
		return d;
	end if;
end function;

function setendian(u:unsigned;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndian(to_std_logic(u));
	else
		return to_std_logic(u);
	end if;
end function;

function setEndian(s:signed;e:string) return std_logic_vector is
begin
	if e="LITTLE" then
		return SwapEndian(to_std_logic(s));
	else
		return to_std_logic(s);
	end if;
end function;
end package body logic;
