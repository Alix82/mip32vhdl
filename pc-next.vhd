library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity PC_NEXT is 
    Port (clk : in std_logic;
          reset           : in std_logic;
          i_instrext      : in std_logic_vector(31 downto 0);
          i_alu_result    : in std_logic_vector(31 downto 0);
          pause           : in std_logic;
          aluzero         : in std_logic;
          jump            : in std_logic;
          branch          : in std_logic;
          jumptoreg       : in std_logic;
          discard         : out std_logic;
          pcnext          : out std_logic_vector(31 downto 0)
    );
End; 

Architecture rtl of PC_NEXT is
    
    signal pccounter             :  std_logic_vector(31 downto 0) := X"00000000";--X"00400580";
    signal debug_pcnext_alu_res  :  std_logic_vector(31 downto 0) := (others => '0');
    signal debug_jump            :  std_logic;
    signal debug_branch          :  std_logic;
    signal debug_jumptoreg       :  std_logic;
    signal debug_aluzero         :  std_logic;
    signal debug_pcnext_pause    :  std_logic;
          
begin
    
    pcnext <= pccounter;
    
    process (clk) 
    
    Variable tmp1 : std_logic_vector (31 downto 0);
    Variable tmp2 : std_logic_vector (31 downto 0);
    Variable pcplus4 : std_logic_vector (31 downto 0);
        
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pccounter <= (others => '0');
            else
                if pause = '0' then
                    tmp1 := "00000000000000000000000000000000";
                    tmp2 := "00000000000000000000000000000000";
                        
                    if jumptoreg = '1' then
                    
                        pccounter <= i_alu_result;
                    
                    elsif branch = '1' and aluzero = '1' then
                        
                        tmp1(31 downto 2) := i_instrext(29 downto 0);
                        tmp2 :=  tmp1 + pccounter;
                        pccounter <= tmp2 - 4;
                        
                    elsif jump = '1' then                        
                    
                        tmp1(25 downto 2) := i_instrext(23 downto 0);
                        pccounter <= ((pccounter and X"F0000000") or tmp1);
                    
                    else
                        pccounter <= pccounter + 4;
                    
                    end if;
                    
                    debug_jump <= jump;
                    debug_branch <= branch;
                    debug_jumptoreg <= jumptoreg;
                    debug_aluzero <= aluzero;
                    --debug_pcnext_alu_res <= i_alu_result;
                end if;
            end if;
        end if;        
        
    end process;
    
    process (branch, aluzero, jump, jumptoreg) 
    begin
        if jump = '1' then
            discard <= '1';
        elsif branch = '1' and aluzero ='1' then
            discard <= '1';
        elsif jumptoreg = '1' then
            discard <= '1';
        else
            discard <= '0';
        end if;
    end process;
    
end;

