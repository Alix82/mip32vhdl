library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mips_constants is

constant ZERO          : std_logic_vector(31 downto 0):=
      "00000000000000000000000000000000";

constant LINK_RET      : integer := 1;
constant REG_DEST      : integer := 11;
constant REG2OPERATION : integer := 2;
constant ALUSRC        : integer := 4;
constant MEM_TO_REG    : integer := 7;
constant MEM_READ      : integer := 8;
constant MEM_WRITE     : integer := 5;
constant REG_WRITE     : integer := 3;
constant BRANCH_BIT    : integer := 9;
constant JUMP_BIT      : integer := 10;
constant JUMPTOREG_BIT : integer := 0;

subtype mult_function_type is std_logic_vector(3 downto 0);
constant MULT_NOTHING       : mult_function_type := "0000";
constant MULT_READ_LO       : mult_function_type := "0001";
constant MULT_READ_HI       : mult_function_type := "0010";
constant MULT_WRITE_LO      : mult_function_type := "0011";
constant MULT_WRITE_HI      : mult_function_type := "0100";
constant MULT_MULT          : mult_function_type := "0101";
constant MULT_SIGNED_MULT   : mult_function_type := "0110";
constant MULT_DIVIDE        : mult_function_type := "0111";
constant MULT_SIGNED_DIVIDE : mult_function_type := "1000";

function bv_adder(a     : in std_logic_vector;
                  b     : in std_logic_vector;
                  do_add: in std_logic) return std_logic_vector;

function bv_negate(a : in std_logic_vector) return std_logic_vector;
   
end mips_constants;

package body mips_constants is
    
function bv_adder(a     : in std_logic_vector;
                  b     : in std_logic_vector;
                  do_add: in std_logic) return std_logic_vector is
   variable carry_in : std_logic;
   variable bb       : std_logic_vector(a'length-1 downto 0);
   variable result   : std_logic_vector(a'length downto 0);
begin
   if do_add = '1' then
      bb := b;
      carry_in := '0';
   else
      bb := not b;
      carry_in := '1';
   end if;
   for index in 0 to a'length-1 loop
      result(index) := a(index) xor bb(index) xor carry_in;
      carry_in := (carry_in and (a(index) or bb(index))) or
                  (a(index) and bb(index));
   end loop;
   result(a'length) := carry_in xnor do_add;
   return result;
end; --function


function bv_negate(a : in std_logic_vector) return std_logic_vector is
   variable carry_in : std_logic;
   variable not_a    : std_logic_vector(a'length-1 downto 0);
   variable result   : std_logic_vector(a'length-1 downto 0);
begin
   not_a := not a;
   carry_in := '1';
   for index in a'reverse_range loop
      result(index) := not_a(index) xor carry_in;
      carry_in := carry_in and not_a(index);
   end loop;
   return result;
end; --function

end;
