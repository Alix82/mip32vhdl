library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity decoder is
    port(clk         : in std_logic;
         instruction : in std_logic_vector(31 downto 0);
         pcD         : in  std_logic_vector(31 downto 0);
         discard     : in std_logic;
         decoded     : out std_logic_vector(11 downto 0);
         opcode      : out std_logic_vector(5 downto 0);
         func        : out std_logic_vector(5 downto 0);
         shamt       : out std_logic_vector(4 downto 0);
         pcF         : out  std_logic_vector(31 downto 0);
         Reg1        : out std_logic_vector(4 downto 0);
         Reg2        : out std_logic_vector(4 downto 0);
         Reg3        : out std_logic_vector(4 downto 0);
         Fetch       : out std_logic
    );
End decoder;

Architecture rtl of decoder is

    signal n_decoded : integer := 0;
    
begin
    process (clk) 
    
    Variable decoded_o : std_logic_vector (7 downto 0);
    Variable op : std_logic_vector(5 downto 0);
    Variable lfunc : std_logic_vector(5 downto 0);
    Variable control_o : std_logic_vector(11 downto 0);
    Variable read_reg: std_logic;
    Variable instructionlocal : std_logic_vector(31 downto 0);
    
    begin
        
        if rising_edge(clk)  then

            instructionlocal := X"00000000";
        
            Fetch <= not discard;
            instructionlocal := Instruction;
            
            lfunc := instructionlocal(5 downto 0);
            op := instructionlocal(31 downto 26);
            
            control_o := "000000000000";
            
            read_reg := '0';
            -- linkbit := '0'; 
            
            case op is
                when "000010" => control_o := "010000000000";  -- J label
                when "000011" => control_o := "010000000010"; read_reg := '1'; -- JAL label
                when "000000" => 
                    case lfunc is 
                        when "001000" => control_o := "010000000001"; -- JR
                        when "010000" => control_o := "000001001000"; -- MFHI
                        when "010010" => control_o := "000001001000"; -- MFLO
                        when "100100" => control_o := "100001001000"; read_reg:='1'; -- add/addu,  and/andu
                        when "100000" => control_o := "100001001000"; read_reg:='1'; -- add/addu,  and/andu
                        when "100001" => control_o := "100001001000"; read_reg:='1'; -- add/addu,  and/andu
                        when others => control_o := "000000000000";
                    end case;
                    
                when "001000" => control_o := "100001011000"; read_reg:='1'; -- addi
                when "001001" => control_o := "000001011000"; read_reg:='1'; -- addiu
                when "101011" => control_o := "000001110000"; read_reg:='1'; -- SW
                when "100011" => control_o := "000111011000"; read_reg:='1'; -- LW
                
                when "101000" => control_o := "000001110000"; read_reg:='1'; -- SB
                when "100000" => control_o := "000111011000"; read_reg:='1'; -- LB
                
                when "001111" => control_o := "000001011000"; read_reg:='1'; -- LUI
                when "001110" => control_o := "000001011000"; read_reg:='1'; -- XORI
                when "001101" => control_o := "000001011000"; read_reg:='1'; -- ORI
                
                when "000101" => control_o := "001001000000"; read_reg:='1'; -- BNE
                when "000100" => control_o := "001001000000"; read_reg:='1'; -- BEQ
                
                when "000001" => 
                    if instructionlocal(20) = '1' then
                        control_o := "001001000110"; read_reg:='1'; --  BGEZAL/BLTZAL
                    else
                        control_o := "001001000100"; read_reg:='1'; -- BGEZ/BLTZ
                    end if;
                when "000111" => control_o := "001001000100"; read_reg:='1';-- BGTZ
                when "000110" => control_o := "001001000100"; read_reg:='1';-- BGTZ
                
                when others  => control_o := "000000000000"; --error := '1';
            end case;
            
            --prevregwrite <= control_o(3);
            decoded <= control_o;
            
            n_decoded <= n_decoded + 1;
            
            opcode <= op;
            func <= lfunc;

            shamt <= instructionlocal(10 downto 6);
            
            reg1 <= instructionlocal(25 downto 21);
            reg2 <= instructionlocal(20 downto 16);
            reg3 <= instructionlocal(15 downto 11);
            pcF <= pcD;
            
        end if;
        
    end process;
    
end;
