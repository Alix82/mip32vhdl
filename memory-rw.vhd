library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity memory_rw is 
    Port (clk : in std_logic;
          inaluresult    : in std_logic_vector(31 downto 0);
          memwritedata   : in std_logic_vector(31 downto 0);
          memtoreg       : in std_logic;
          memread        : in std_logic;
          memwrite       : in std_logic;
          o_memaddr      : out std_logic_vector(31 downto 0);
          o_read         : out std_logic;
          o_write        : out std_logic;
          o_writedata    : out std_logic_vector(31 downto 0)
    );
End; 

Architecture rtl of memory_rw is
    signal debug_addr   :  std_logic_vector(31 downto 0);
begin
    process(clk) 
    begin
        if rising_edge(clk) then
            if memread = '1' then
                debug_addr <= inaluresult;
                o_memaddr <= inaluresult;
                o_read <= '1';
            else
                --o_memaddr <= (others => '0');
                o_read <= '0';
            end if;
            
            if memwrite = '1' then
                o_memaddr <= inaluresult;
                o_writedata <= memwritedata;
                o_write <= '1';
            else
                --o_memaddr <= (others => '0');
                o_writedata <= (others => '0');
                o_write <= '0';
            end if;
        end if;
    end process;
end;
