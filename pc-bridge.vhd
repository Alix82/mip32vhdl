library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity PC_BRIDGE is 
    Port (clk : in std_logic;
          i_operation     : in std_logic_vector(11 downto 0);
          i_instrext      : in std_logic_vector(31 downto 0);
          o_instrext      : out std_logic_vector(31 downto 0);
          jump            : out std_logic;
          branch          : out std_logic;
          jumptoreg       : out std_logic
    );
End; 

Architecture rtl of PC_BRIDGE is
begin

    process (clk) begin
    
        if rising_edge(clk) then
            jump <= i_operation(JUMP_BIT);
            branch <= i_operation(BRANCH_BIT);
            jumptoreg <= i_operation(JUMPTOREG_BIT);
            o_instrext <= i_instrext;
        end if;
        
    end process;
    
end;
