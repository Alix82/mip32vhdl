library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- use IEEE.std_logic_arith.all;
use STD.textio.all; 

-----------------------------------------------------------
-- TB
use WORK.mips;

entity testbench is
end entity testbench;

architecture TB of testbench is 
    component mips is
    generic(nbits : positive :=32);
    port(inInstruction : in std_logic_vector(nbits -1 downto 0);
         clk        : in std_logic;
         reset      : in std_logic;
         O_Fetch        : out std_logic;
         O_PCNext       : out std_logic_vector(nbits -1 downto 0);
         
         outMemAddr      : out std_logic_vector(nbits -1 downto 0);
         outMemRead      : out std_logic;
         inMemReadData   : in std_logic_vector(nbits -1 downto 0);
         inMemRead       : in std_logic;
         outMemWrite     : out std_logic;
         outMemWriteData : out std_logic_vector(nbits -1 downto 0)
         
       --  error_control : out std_logic
    );
    end component;
    
    -- for mips0: mipspipe use entity work.mipspipe;
    signal erro : boolean := false;
    constant clk_period : time := 10 ns;
    signal instr : std_logic_vector(31 downto 0) := (others => '0');
    signal pcfetch : std_logic;
    signal pcnext : std_logic_vector(31 downto 0) := X"00000000";
    signal pc : std_logic_vector(31 downto 0) := X"00000000";
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    
    signal do_reset : std_logic := '0';
    
    signal memaddr      : std_logic_vector(31 downto 0) := (others => '0');
    signal memreaddata  : std_logic_vector(31 downto 0) := (others => '0');
    signal memwritedata : std_logic_vector(31 downto 0) := (others => '0');
    signal memwrite     : std_logic := '0';
    signal memread      : std_logic := '0';
    signal memreadack   : std_logic := '0';
    
    --
    constant mem_size : Integer := 1024;
    constant stack_size : Integer := 128;
    
    type memory_array is array(0 to mem_size) of std_logic_vector(31 downto 0);
    type stack_array is array(0 to stack_size) of std_logic_vector(31 downto 0);
     
    signal stack_segment : stack_array := (
    others => X"00000000"
    );

    
    signal memory : memory_array := (
-- DATA_SECTION
 X"00000005", --      0x5             00000000
 -- TEXT_SECTION
 X"3c080000", --   lui t0,0x0             00000000
 X"8d080000", --   lw t0,0(t0)             00000001
 X"24090005", --   addiu t1,zero,5             00000002
 X"00000000",
 X"01094820", --   add t1,t0,t1             00000003
 X"3c010000", --   lui at,0x0             00000004
 X"ac290000", --   sw t1,0(at)             00000005
 X"00000000",
 X"00000000",
 X"00000000",
 X"00000000",
 X"00000000",
 X"00000000",
 
        others=>X"00000000"
    );
begin
    mips0: mips port map(instr, clk, reset, pcfetch, pcnext, memaddr, memread, memreaddata, memreadack, memwrite, memwritedata);
    
        process begin
        clk <= not clk;
        wait for 10 ns;
    end process;
    
    
    process(clk) 
    
    
    file log : text;
    variable line_num : line;
    variable line_content : string(1 to 32);
    variable i : integer := 0;
    Variable pctmp : std_logic_vector (31 downto 0) := (others => '0');
    Variable memaddrlocal : std_logic_vector (31 downto 0) := (others => '0');
    
    begin
        if(falling_edge(clk)) then
            if do_reset = '1' then
                reset <= '1';
                do_reset <= '0';
            else
                reset <= '0';
                if pcfetch = '1' then
                    pctmp := pcnext;
                    pctmp(29 downto 0) := pctmp(31 downto 2);
                        
                    instr <= memory(to_integer(unsigned(pctmp)));
                end if;
                
                if memread = '1' then
                    if memaddr >= X"10010000" then
                        memaddrlocal := X"7FFFFFFF" - memaddr;
                        memaddrlocal(29 downto 0) := memaddrlocal(31 downto 2);
                        memreaddata <= stack_segment(to_integer(unsigned(memaddrlocal)));
                        
                    else
                        memaddrlocal := memaddr;
                        memaddrlocal(29 downto 0) := memaddrlocal(31 downto 2);
                        
                        memreaddata <= memory(to_integer(unsigned(memaddrlocal)));
                        --
                    end if;
                    
                    memreadack <= '1';
                    
                elsif memwrite = '1' then
                    if memaddr >= X"10010000" then
                        memaddrlocal := X"7FFFFFFF" - memaddr;
                        memaddrlocal(29 downto 0) := memaddrlocal(31 downto 2);
                        stack_segment(to_integer(unsigned(memaddrlocal))) <= memwritedata;
                    else
                        memaddrlocal := memaddr;
                        memaddrlocal(29 downto 0) := memaddrlocal(31 downto 2);
                        memory(to_integer(unsigned(memaddrlocal))) <= memwritedata;
                    end if;
                    memreadack <= '0';
                else
                    memreadack <= '0';
                end if;
            end if;
        end if;
    end process;
    
    
    stop_simulation :process
        --file file_pointer : text;
    begin
        wait for 300 ns;
        assert true
            report "simulation ended"
            severity failure;
    end process ;

end TB;
