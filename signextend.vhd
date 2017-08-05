library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

Entity signextend is 
        Port (
            clk   : in std_logic;
            in16  : in std_logic_vector(15 downto 0);
            out32 : out std_logic_vector(31 downto 0)
        );
End;

Architecture RTL of signextend is 
begin
    process (clk) begin
        if rising_edge(clk) then
            if in16(15)='0' then
                out32 <= X"0000" & in16;
            else 
                out32 <= X"ffff" & in16;
            end if;
        end if;
    end process;
end RTL;
