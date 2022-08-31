library ieee;
use ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;


entity bram_instance is generic (
    G_ADDR_WIDTH_A       : integer := 12;
    G_ADDR_WIDTH_B       : integer := 12;
    G_WRITE_DATA_WIDTH_A : integer := 64;
    G_READ_DATA_WIDTH_B  : integer := 64;
    G_CLOCKING_MODE      : string  := "common_clock";
    G_ECC_MODE           : string  := "both_encode_and_decode";
    G_BYTE_WRITE_WIDTH_A : integer := 64;    
    G_READ_LATENCY_B     : integer := 2;
    G_WRITE_MODE_B       : string  := "no_change";
    G_READ_RESET_VALUE_B : string  := "0";
    G_RST_MODE_A         : string  := "SYNC";
    G_RST_MODE_B         : string  := "SYNC";
    G_MEMORY_PRIMITIVE   : string  := "block";
    G_MEMORY_OPTIMIZATION: string  := "true";
    G_MEMORY_INIT_FILE   : string  := "none";
    G_MEMORY_INIT_PARAM  : string  := "0";
    G_MEMORY_SIZE        : integer := 4096
);
port (         
    dbiterrb : out std_logic;             
    doutb  : out std_logic_vector(G_READ_DATA_WIDTH_B-1 downto 0);             
    sbiterrb : out std_logic;               
    addra : in std_logic_vector(G_ADDR_WIDTH_A-1 downto 0);
    addrb : in std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);
    clka  : in std_logic;              
    clkb  : in std_logic;                             
    dina  : in std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
    ena   : in std_logic;                            
    enb   : in std_logic;    
    injectdbiterra  : in std_logic;                         
    injectsbiterra  : in std_logic;                                
    regceb : in std_logic;              
    rstb   : in std_logic;
    sleep  : in std_logic;
    wea    : in std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0)                      
);
end entity;


architecture rtl of bram_instance is 

begin

    xpm_memory_sdpram_inst : xpm_memory_sdpram
    generic map (
       ADDR_WIDTH_A => G_ADDR_WIDTH_A,                      -- DECIMAL
       ADDR_WIDTH_B => G_ADDR_WIDTH_B,                      -- DECIMAL
       AUTO_SLEEP_TIME => 0,                                -- DECIMAL
       BYTE_WRITE_WIDTH_A => G_BYTE_WRITE_WIDTH_A,          -- DECIMAL
       CASCADE_HEIGHT => 0,                                 -- DECIMAL
       CLOCKING_MODE => G_CLOCKING_MODE,                    -- String
       ECC_MODE => G_ECC_MODE,                              -- String
       MEMORY_INIT_FILE => G_MEMORY_INIT_FILE,              -- String
       MEMORY_INIT_PARAM => G_MEMORY_INIT_PARAM,            -- String
       MEMORY_OPTIMIZATION => G_MEMORY_OPTIMIZATION,        -- String
       MEMORY_PRIMITIVE => G_MEMORY_PRIMITIVE,              -- String
       MEMORY_SIZE => G_MEMORY_SIZE,                        -- DECIMAL
       MESSAGE_CONTROL => 0,                                -- DECIMAL
       READ_DATA_WIDTH_B => G_READ_DATA_WIDTH_B,            -- DECIMAL
       READ_LATENCY_B => G_READ_LATENCY_B,                  -- DECIMAL
       READ_RESET_VALUE_B => G_READ_RESET_VALUE_B,          -- String
       RST_MODE_A => G_RST_MODE_A,                          -- String
       RST_MODE_B => G_RST_MODE_B,                          -- String
       SIM_ASSERT_CHK => 0,                                 -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
       USE_EMBEDDED_CONSTRAINT => 0,                        -- DECIMAL
       USE_MEM_INIT => 1,                                   -- DECIMAL
       USE_MEM_INIT_MMI => 0,                               -- DECIMAL
       WAKEUP_TIME => "disable_sleep",                      -- String
       WRITE_DATA_WIDTH_A => G_WRITE_DATA_WIDTH_A,          -- DECIMAL
       WRITE_MODE_B => G_WRITE_MODE_B,                      -- String
       WRITE_PROTECT => 1                                   -- DECIMAL
    )
    port map (
       dbiterrb => dbiterrb,             -- 1-bit output: Status signal to indicate double bit error occurrence
                                         -- on the data output of port B.
 
       doutb => doutb,                   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
       sbiterrb => sbiterrb,             -- 1-bit output: Status signal to indicate single bit error occurrence
                                         -- on the data output of port B.
 
       addra => addra,                   -- ADDR_WIDTH_A-bit input: Address for port A write operations.
       addrb => addrb,                   -- ADDR_WIDTH_B-bit input: Address for port B read operations.
       clka => clka,                     -- 1-bit input: Clock signal for port A. Also clocks port B when
                                         -- parameter CLOCKING_MODE is "common_clock".
 
       clkb => clkb,                     -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                         -- "independent_clock". Unused when parameter CLOCKING_MODE is
                                         -- "common_clock".
 
       dina => dina,                     -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
       ena => ena,                       -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                         -- cycles when write operations are initiated. Pipelined internally.
 
       enb => enb,                       -- 1-bit input: Memory enable signal for port B. Must be high on clock
                                         -- cycles when read operations are initiated. Pipelined internally.
 
       injectdbiterra => injectdbiterra, -- 1-bit input: Controls double bit error injection on input data when
                                         -- ECC enabled (Error injection capability is not available in
                                         -- "decode_only" mode).
 
       injectsbiterra => injectsbiterra, -- 1-bit input: Controls single bit error injection on input data when
                                         -- ECC enabled (Error injection capability is not available in
                                         -- "decode_only" mode).
 
       regceb => regceb,                 -- 1-bit input: Clock Enable for the last register stage on the output
                                         -- data path.
 
       rstb => rstb,                     -- 1-bit input: Reset signal for the final port B output register
                                         -- stage. Synchronously resets output port doutb to the value specified
                                         -- by parameter READ_RESET_VALUE_B.
 
       sleep => sleep,                   -- 1-bit input: sleep signal to enable the dynamic power saving feature.
       wea => wea                        -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                         -- for port A input data port dina. 1 bit wide when word-wide writes
                                         -- are used. In byte-wide write configurations, each bit controls the
                                         -- writing one byte of dina to address addra. For example, to
                                         -- synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                         -- is 32, wea would be 4'b0010.
 
    );


end architecture;