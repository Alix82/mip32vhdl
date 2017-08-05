library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity alu is
    port(clk            : in std_logic;
         reset          : in std_logic;
         pcF            : in  std_logic_vector(31 downto 0);
         opcode         : in std_logic_vector(5 downto 0);
         func           : in std_logic_vector(5 downto 0);
         shamt          : in std_logic_vector(4 downto 0);
         InstReg1       : in std_logic_vector(4 downto 0);
         InstReg2       : in std_logic_vector(4 downto 0);
         InstReg3       : in std_logic_vector(4 downto 0);
         instructionExt : in std_logic_vector(31 downto 0); 
         control        : in std_logic_vector(11 downto 0);
         fetch          : in std_logic;
         inwriteregdata : in std_logic_vector(31 downto 0);
         inwritereg     : in std_logic;
         memtoreg       : out std_logic;
         memread        : out std_logic;
         memwrite       : out std_logic;
         outZero        : out std_logic;
         outAluResult   : out std_logic_vector(31 downto 0);
         outwriteData   : out std_logic_vector(31 downto 0);
         alu_pause      : out std_logic
    );    
End alu;

Architecture rtl of alu is

component  mult is
        port(clk       : in std_logic;
        reset_in  : in std_logic;
        a, b      : in std_logic_vector(31 downto 0);
        mult_func : in mult_function_type;
        c_mult    : out std_logic_vector(31 downto 0);
        pause_out : out std_logic);
end component mult;
    

type register_array is array(0 to 31) of std_logic_vector(31 downto 0);

signal register_memory: register_array := (
    X"00000000", -- $zero                       0
    X"00000000", -- $at Reserved for Assembler  1
    X"00000000", -- $v0 First return value      2
    X"00000000", -- $v1 Second return value     3
    X"00000000", -- $a0 Function arguments      4
    X"00000000", -- $a1 ...                     5
    X"00000000", -- $a2 ...                     6
    X"00000000", -- $a3 ...                     7
    X"00000000", -- $t0 Temp Registers          8
    X"00000000", -- $t1                         9
    X"00000000", -- $t2                         10
    X"00000000", -- $t3                         11
    X"00000000", -- $t4                         12
    X"00000000", -- $t5                         13
    X"00000000", -- $t6                         14
    X"00000000", -- $t7                         15
    X"00000000", -- $s0  Save Registers         16
    X"00000000", -- $s1                         17
    X"00000000", -- $s2                         18
    X"00000000", -- $s3                         19
    X"00000000", -- $s4                         20
    X"00000000", -- $s5                         21
    X"00000000", -- $s6                         22
    X"00000000", -- $s7                         23
    X"00000000", -- $t8  Temp Registers         24
    X"00000000", -- $t9                         25
    X"00000000", -- $k0  Reserved for OS        26
    X"00000000", -- $k1  Reserved for OS        27
    X"00000000", -- $gp  Global Pointer         28
    X"7FFFFFFF", -- $sp  Stack Pointer          29
    X"00000000", -- $fp  Frame pointer          30
    X"00000000");-- $ra  Return address         31
    

signal alu_actual_func : std_logic_vector(5 downto 0) := (others => '0');
signal alu_actual_op : std_logic_vector(5 downto 0) := (others => '0');
signal debug_nreg1 :  std_logic_vector(4 downto 0) := (others => '0');
signal debug_nreg2 :  std_logic_vector(4 downto 0) := (others => '0');
signal debug_reg1data : std_logic_vector(31 downto 0) := (others => '0');
signal debug_reg2data : std_logic_vector(31 downto 0) := (others => '0');
signal debug_write_res : std_logic_vector(31 downto 0) := (others => '0');
signal debug_write_reg : std_logic_vector(4 downto 0) := (others => '0');
signal debug_control : std_logic_vector(11 downto 0) := (others => '0');
signal debug_alu_pc : std_logic_vector(31 downto 0) := (others => '0');

signal req_bit  : std_logic := '0';

signal alu_counter : integer := 0;
    
signal write_reg_save : std_logic_vector(4 downto 0) := (others => '0');
signal alu_a, alu_b   : std_logic_vector(31 downto 0):= (others => '0');
signal alu_mult_func  : mult_function_type := (others => '0');
signal alu_mult_res   : std_logic_vector(31 downto 0):= (others => '0');

signal alu_mult_pause : std_logic := '0';

begin

    MULT0: mult port map (clk, reset, alu_a, alu_b, alu_mult_func, alu_mult_res, alu_mult_pause);
    
    alu_pause <= alu_mult_pause;
    
    process(clk) 
    
    Variable Res : std_logic_vector (31 downto 0);
    Variable inReg1 : std_logic_vector (31 downto 0);
    Variable inReg2 : std_logic_vector (31 downto 0);
    Variable Res64 : std_logic_vector (63 downto 0);
    
    Variable Zero : std_logic;
    
    Variable Write_Reg : std_logic_vector(4 downto 0);
    Variable Read1 : std_logic_vector(4 downto 0);
    Variable Read2 : std_logic_vector(4 downto 0);
    
    begin
        
        if rising_edge(clk) then
            
            debug_alu_pc <= pcF;
            
            if inwritereg = '1' then
                register_memory(to_integer(unsigned(write_reg_save))) <= inwriteregdata;
            end if;
                
            if alu_mult_pause = '1' then
                alu_mult_func <= MULT_NOTHING;
            elsif fetch = '1' then
                
                Read1 := "00000";
                Read2 := "00000";
                
                inReg1 := X"00000000";
                inReg2 := X"00000000";
                    
                debug_control <= control;
                
                inReg1 := inwriteregdata;
                Read1 := InstReg1;
                
                if inwritereg = '1' and Read1 = write_reg_save then
                    inReg1 := inwriteregdata;
                else
                    inReg1 := register_memory(to_integer(unsigned(Read1)));
                end if;
        
                if control(REG2OPERATION) = '0' then
                    if control(ALUSRC) = '1' then
                        inReg2 := instructionExt;
                    else
                        Read2 := InstReg2;
                        if inwritereg = '1' and Read2 = write_reg_save then
                            inReg2 := inwriteregdata;
                        else
                            inReg2 := register_memory(to_integer(unsigned(Read2)));
                        end if;
                    end if;
                else
                    inReg2(4 downto 0) := InstReg2;
                    inReg2(31 downto 5) := ( others => '0');
                end if;

                --inReg2 := inReg1;
                Res := "00000000000000000000000000000000";
                Res64 := "0000000000000000000000000000000000000000000000000000000000000000";
                Zero := '0';
                
                debug_nreg1 <= Read1;
                debug_nreg2 <= Read2;
                
                
                debug_reg1data <= inReg1;
                debug_reg2data <= inReg2;
                
                alu_actual_func <= func;
                alu_actual_op <= opcode;
                
                case opcode is 
                    when "000000" =>
                        case func is
                            when "001000" => Res := inReg1;
                        -- R-TYPE
                            when "100000" => Res := inReg1 + inReg2;  -- add FIXME_ Trap
                            when "100001" => Res := inReg1 + inReg2;  -- addu
                            when "100100" => Res := inReg1 and inReg2; -- and
                            when "100010" => Res := inReg1 - inReg2; -- sub
                            when "100011" => Res := inReg1 - inReg2; -- subu
                            when "100110" => Res := inReg1 xor inReg2;
                            -- SHIFTS
                            -- SLL
                            when "000000" => Res(31 downto to_integer(unsigned(shamt))) := inReg2(31 - to_integer(unsigned(shamt)) downto 0);
                            -- SRL
                            when "000010" => Res(31 - to_integer(unsigned(shamt)) downto 0) := inReg2(31 downto to_integer(unsigned(shamt)));
                            -- SLLV
                            when "000100" => Res(31 downto to_integer(unsigned(inReg1))) := inReg2(31 - to_integer(unsigned(inReg1)) downto 0);
                            -- SRLV
                            when "000110" => Res(31 - to_integer(unsigned(inReg1)) downto 0) := inReg2(31 downto to_integer(unsigned(inReg1)));
                            -- SRA
                            when "000011" => 
                                Res(31 - to_integer(unsigned(shamt)) downto 0) := inReg2(31 downto to_integer(unsigned(shamt)));
                                Res(0) := inReg2(31);
                                
                            when "011011" => 
                                alu_a <= inReg1;
                                alu_b <= inReg2;
                                
                                alu_mult_func <= MULT_DIVIDE;
                                
                            when "011010" => 
                                alu_a <= inReg1;
                                alu_b <= inReg2;
                                
                                alu_mult_func <= MULT_SIGNED_DIVIDE;
                                
                            when "011000" => 
                                alu_a <= inReg1;
                                alu_b <= inReg2;
                                
                                alu_mult_func <= MULT_SIGNED_MULT;
                                
                            when "011001" =>
                                alu_a <= inReg1;
                                alu_b <= inReg2;
                                
                                alu_mult_func <= MULT_MULT;
            
                            when "010000" =>
                                alu_mult_func <= MULT_READ_HI;
                                Res := alu_mult_res;
                            when "010010" =>
                                alu_mult_func <= MULT_READ_LO;
                                Res := alu_mult_res;
                            when others  => null; 
                            
                        end case;
                    
                    -- I-TYPE
                    when "001000" => Res := inReg1 + inReg2; -- ADDI
                    when "001001" => Res := inReg1 + inReg2; -- ADDIU
                    
                    when "101011" => Res := inReg1 + inReg2; -- SW 
                    when "100011" => Res := inReg1 + inReg2; -- LW
                    
                    when "101000" => Res := inReg1 + inReg2; -- SB
                    when "100000" => Res := inReg1 + inReg2; -- LB
                    
                    when "001110" => Res := inReg1 xor inReg2; -- XORI
                    when "001101" => Res := inReg1 or inReg2; -- ORI
                    when "001111" => Res(31 downto 16) := inReg2(15 downto 0); -- LUI
                    
                    --- Branch
                    when "000100" => -- BEQ 
                        if inReg1 = inReg2 then
                            Zero := '1';
                        else
                            Zero := '0';
                        end if;
            
                    when "000101" =>    -- BNE
                        if inReg1 = inReg2 then
                            Zero := '0';
                        else
                            Zero := '1';
                        end if;
                    
                    --- inReg2 contains the branch operation to be performed
                    when "000001" =>  -- BGEZ/BGEZAL
                        case inReg2(3 downto 0) is 
                            when "0001" => -- This includes 0 0001(BGEZ) and 1 0001(BGEZAL)
                                if inReg1 >= 0 then
                                    Zero := '1';
                                else
                                    Zero := '0';
                                end if;
            
                            when "0000" => -- This includes 1 0000(BLTZAL) and 0 0001(BLTZ)
                                if inReg1 < 0 then
                                    Zero := '1';
                                else
                                    Zero := '0';
                                end if;
                            when others => null;
                        end case;
                    
                    --- BGTZ
                    when "000111" => 
                        if inReg1 > 0 then
                           Zero := '1';
                        else
                            Zero := '0';
                        end if; 
                    
                    --- BLEZ
                    when "000110" => 
                        if inReg1 <= 0 then
                            Zero := '1';
                        else
                            Zero := '0';
                        end if; 
                        
                    when others => null;
                        
                end case;

                if control(MEM_TO_REG) = '0' then
                    if control(REG_WRITE) = '1' then
                        Write_Reg := InstReg2;
                        debug_write_res <= Res;
                        debug_write_reg <= Write_Reg;
                        register_memory(to_integer(unsigned(Write_Reg))) <= Res;
                    end if;
                    memtoreg <= '0';
                else
                    memtoreg <= '1';
                end if;
                
                memread <= control(MEM_READ);
                memwrite <= control(MEM_WRITE);
                
                if control(MEM_READ) = '1' then
                    if control(REG_DEST) = '0' then
                        write_reg_save <= InstReg2;
                    else
                        write_reg_save <= InstReg3;
                    end if;
                end if;
                
                if control(MEM_WRITE) = '1' then
                    Read2 := InstReg2;
                    inReg2 := register_memory(to_integer(unsigned(Read2)));
                    outwriteData <= inReg2;
                else
                    outwriteData <= (others => '0');
                end if;
                
                if control(LINK_RET) = '1' then
                    register_memory(31) <= pcF + 8;
                end if;
                
                outAluResult <= Res(31 downto 0);
                outZero <= Zero;
            else
                memtoreg <= '0';
                memread <= '0';
                memwrite <= '0';
                
                outZero <= '0';
                outAluResult <= X"00000000";
                alu_actual_func <= (others => '0');
            end if;
        end if;
    end process;
end;
