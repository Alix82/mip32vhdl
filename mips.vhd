library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.mips_constants.all;

Entity mips is
  port(inInstruction   : in std_logic_vector(31 downto 0);
       Clk             : in std_logic;
       reset           : in std_logic;
       O_Fetch         : out std_logic;
       O_PCNext        : out std_logic_vector(31 downto 0);

       outMemAddr      : out std_logic_vector(31 downto 0);
       outMemRead      : out std_logic;
       inMemReadData   : in std_logic_vector(31 downto 0);
       inMemRead       : in std_logic;
       outMemWrite     : out std_logic;
       outMemWriteData : out std_logic_vector(31 downto 0)

   --error_control   : out std_logic
       );
End mips;

Architecture rtl of mips is


    component DECODER is
        port(
         clk         : in std_logic;
         instruction : in  std_logic_vector(31 downto 0);
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
    end component DECODER;


    component ALU is
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
    end component ALU;


    component MEMORY_RW is
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
    end component MEMORY_RW;


    component SIGNEXTEND is
        Port (
            clk   : in std_logic;
            in16  : in std_logic_vector(15 downto 0);
            out32 : out std_logic_vector(31 downto 0)
        );
    end component SIGNEXTEND;


    component PC_BRIDGE is
    Port (clk : in std_logic;
          i_operation     : in std_logic_vector(11 downto 0);
          i_instrext      : in std_logic_vector(31 downto 0);
          o_instrext      : out std_logic_vector(31 downto 0);
          jump            : out std_logic;
          branch          : out std_logic;
          jumptoreg       : out std_logic
    );
    end component;


    component PC_NEXT is
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
    end component;


    signal fetch : std_logic := '1';
    signal alu_pause : std_logic := '0';

    signal operationD : std_logic_vector (11 downto 0) := (others => '0');

    signal pcnext : std_logic_vector(31 downto 0) := (others => '0');
    signal pcF : std_logic_vector(31 downto 0) := (others => '0');

    signal instructionExtended : std_logic_vector(31 downto 0) := (others => '0');
    signal instructionExtPC : std_logic_vector(31 downto 0) := (others => '0');

    signal alu_zero      : std_logic := '0';
    signal alu_result    : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_mem_write : std_logic_vector(31 downto 0) := (others => '0');
    signal alu_opcode    : std_logic_vector(5 downto 0) := (others => '0');
    signal alu_func      : std_logic_vector(5 downto 0) := (others => '0');
    signal alu_shamt     : std_logic_vector(4 downto 0) := (others => '0');

    signal InstReg1      : std_logic_vector(4 downto 0) := (others => '0');
    signal InstReg2      : std_logic_vector(4 downto 0) := (others => '0');
    signal InstReg3      : std_logic_vector(4 downto 0) := (others => '0');

    signal memtoreg   : std_logic := '0';
    signal memread    : std_logic := '0';
    signal memwrite   : std_logic := '0';
    signal jump       : std_logic := '0';
    signal jumptoreg  : std_logic := '0';
    signal branch     : std_logic := '0';
    signal discard    : std_logic := '0';

    signal clk_counter : integer := 0;
begin

    O_PCNext <= pcnext;
    O_Fetch <= not alu_pause;

    process(clk) begin
    if rising_edge(clk) then
        clk_counter <= clk_counter +1;
    end if;
    end process;

    --------------------------------------------------------------------
    -- STAGE 1 FETCH/DECODE
    --------------------------------------------------------------------
    DECODER0: DECODER port map (clk, ininstruction, pcnext,
                                discard, operationD, alu_opcode, alu_func, alu_shamt,
                                pcF,
                                InstReg1, InstReg2, InstReg3, fetch);
    SIGNEXTEND0: SIGNEXTEND port map (clk, ininstruction(15 downto 0), instructionExtended);

    --------------------------------------------------------------------
    -- STAGE 2
    --------------------------------------------------------------------
    ALU0: ALU port map (clk, reset, pcF,
                        alu_opcode, alu_func, alu_shamt,
                        InstReg1, InstReg2, InstReg3,
                        instructionExtended, operationD, fetch, inMemReadData, inMemRead, memtoreg, memread, memwrite,
                        alu_zero, alu_result, alu_mem_write, alu_pause);

    PC_BRIDGE0: PC_BRIDGE port map (clk, operationD, instructionExtended, instructionExtPC, jump, branch, jumptoreg);

    --------------------------------------------------------------------
    -- STAGE 3 Memory
    --------------------------------------------------------------------
    MEMORY_RW0: MEMORY_RW port map (clk, alu_result, alu_mem_write,
                                    memtoreg, memread, memwrite, outMemAddr, outMemRead, outMemWrite, outMemWriteData);

    PC_NEXT0: PC_NEXT port map (clk, reset, instructionExtPC, alu_result, alu_pause, alu_zero, jump, branch, jumptoreg, discard, pcnext);

end rtl;
