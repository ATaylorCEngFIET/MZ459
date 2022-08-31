library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Stim_memory is 
end Stim_memory;

architecture rtl of Stim_memory is

constant c_clk_period : time := 10 ns;
constant c_read_data_width_b : integer := 64;
constant c_addr_width_a : integer := 4;
constant c_addr_width_b : integer := 4;
constant c_write_data_width_a : integer := 64;
constant c_memory_size : integer := c_write_data_width_a * (2**c_addr_width_a);


signal s_clk             :  std_logic:='0';                     
signal s_doutb           :  std_logic_vector(c_read_data_width_b-1 downto 0);                            
signal s_addra           :  std_logic_vector(c_addr_width_a-1 downto 0);
signal s_addrb           :  std_logic_vector(c_addr_width_b-1 downto 0);
                             
signal s_dina            :  std_logic_vector(c_write_data_width_a-1 downto 0);
signal s_ena             :  std_logic;                            
signal s_enb             :  std_logic;    
        
signal s_regceb          :  std_logic;              
signal s_rstb            :  std_logic;
signal s_sleep           :  std_logic;
signal s_wea             :  std_logic_vector(c_write_data_width_a/c_write_data_width_a-1 downto 0);                    
signal s_inject_single   :  std_logic;
signal s_inject_double   :  std_logic;
signal s_test_enable     :  std_logic;
signal s_enable_scrubbing:  std_logic;
signal s_scrubbing       :  std_logic;
signal s_scrub_error_cnt :  std_logic_vector(c_addr_width_b-1 downto 0);

component secded is generic(
    G_ADDR_WIDTH_A       : integer := c_addr_width_a;
    G_ADDR_WIDTH_B       : integer := c_addr_width_b;
    G_WRITE_DATA_WIDTH_A : integer := c_write_data_width_a;
    G_READ_DATA_WIDTH_B  : integer := c_read_data_width_b;
    G_CLOCKING_MODE      : string  := "common_clock";
    G_ECC_MODE           : string  := "both_encode_and_decode";
    G_BYTE_WRITE_WIDTH_A : integer := c_write_data_width_a;    
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
    doutb               : out std_logic_vector(G_READ_DATA_WIDTH_B-1 downto 0);                          
    addra               : in std_logic_vector(G_ADDR_WIDTH_A-1 downto 0);
    addrb               : in std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);
    clk                 : in std_logic;                                         
    dina                : in std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
    ena                 : in std_logic;                            
    enb                 : in std_logic;                                   
    regceb              : in std_logic;              
    rstb                : in std_logic;
    sleep               : in std_logic;
    enable_scrubbing    : in std_logic;
    scrubbing           : out std_logic;
    scrub_error_cnt     : out std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);
    wea                 : in std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0);    
    inject_single       : in std_logic;
    inject_double       : in std_logic;  
    test_enable         : in std_logic                
);
end component;

begin

bram_inst : secded generic map(
    G_ADDR_WIDTH_A        =>  c_addr_width_a,
    G_ADDR_WIDTH_B         => c_addr_width_b,
    G_WRITE_DATA_WIDTH_A   => c_write_data_width_a,
    G_READ_DATA_WIDTH_B    => c_read_data_width_b,
    G_BYTE_WRITE_WIDTH_A   => c_write_data_width_a,
    G_MEMORY_SIZE          => c_memory_size
    )
port map (   
            
    doutb               => s_doutb,              
    addra               => s_addra,         
    addrb               => s_addrb,         
    clk                 => s_clk,         
    dina                => s_dina,                   
    ena                 => s_ena,           
    enb                 => s_enb,              
    regceb              => s_regceb,                 
    rstb                => s_rstb,          
    sleep               => s_sleep,         
    wea                 => s_wea,
    enable_scrubbing    => s_enable_scrubbing,
    scrub_error_cnt     => s_scrub_error_cnt,
    scrubbing           => s_scrubbing,
    inject_single       => s_inject_single,     
    inject_double       => s_inject_double,       
    test_enable         => s_test_enable);       


s_clk <= not s_clk after (c_clk_period/2);

s_sleep <= '0'; 
s_regceb <= '1';

stim: process 
begin


s_wea <= "0";

s_ena <= '0';
s_enb <= '0';
s_addrb <= (others=>'0');
s_inject_single <= '0';
s_inject_double <= '0';
s_test_enable <= '0';
s_rstb <= '1';
s_enable_scrubbing <= '0';

wait until rising_edge(s_clk);
wait until rising_edge(s_clk);
wait until rising_edge(s_clk);
wait until rising_edge(s_clk);

s_rstb <= '0';

wait for 10*c_clk_period;
wait until rising_edge(s_clk);
for i in 0 to 15 loop
    s_addra <= std_logic_vector(to_unsigned(i,c_addr_width_a));
    s_dina <= std_logic_vector(to_unsigned(i,c_write_data_width_a));
    s_wea <= "1";
    s_ena <= '1';
 wait until rising_edge(s_clk);
end loop;
s_wea <= "0";
s_ena <= '0';

for i in 0 to 15 loop
    wait until rising_edge(s_clk);
    s_addrb <= std_logic_vector(to_unsigned(i,c_addr_width_a));
    s_enb <= '1';
end loop;

for i in 0 to 15 loop
    s_addra <= std_logic_vector(to_unsigned(i,c_addr_width_a));
    s_dina <= std_logic_vector(to_unsigned(i,c_write_data_width_a));
    s_wea <= "1";
    s_ena <= '1';
    s_test_enable <= '0';
    if(i=0) or (i = 2) or (i=4) or (i=6) or (i=8) then 
        --s_injectsbiterra <= '1';
        s_test_enable <= '1';
        s_inject_single <= '1';
    else
        --s_injectsbiterra <= '0';
        s_test_enable <= '0';
        s_inject_single <= '0';
    end if;
    wait until rising_edge(s_clk);
end loop;
s_wea <= "0";

for i in 0 to 15 loop
    wait until rising_edge(s_clk);
    s_addrb <= std_logic_vector(to_unsigned(i,c_addr_width_a));
    s_enb <= '1';
end loop;

wait for 10*c_clk_period;

s_enable_scrubbing <= '1';
wait for 100*c_clk_period;

s_enable_scrubbing <= '0';
wait until s_scrubbing = '0';

for i in 0 to 15 loop
    wait until rising_edge(s_clk);
    s_addrb <= std_logic_vector(to_unsigned(i,c_addr_width_a));
    s_enb <= '1';
end loop;

report "end of simulation" severity failure;

end process;

end rtl;
