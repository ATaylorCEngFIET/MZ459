-- vsg_off
-- vsg_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity secded is generic(
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
end entity;

architecture rtl of secded is 

component bram_instance is generic (
    G_ADDR_WIDTH_A              : integer := 12;
    G_ADDR_WIDTH_B              : integer := 12;
    G_WRITE_DATA_WIDTH_A        : integer := 64;
    G_READ_DATA_WIDTH_B         : integer := 64;
    G_CLOCKING_MODE             : string  := "common_clock";
    G_ECC_MODE                  : string  := "both_encode_and_decode";
    G_BYTE_WRITE_WIDTH_A        : integer := 64;    
    G_READ_LATENCY_B            : integer := 2;
    G_WRITE_MODE_B              : string  := "no_change";
    G_READ_RESET_VALUE_B        : string  := "0";
    G_RST_MODE_A                : string  := "SYNC";
    G_RST_MODE_B                : string  := "SYNC";
    G_MEMORY_PRIMITIVE          : string  := "block";
    G_MEMORY_OPTIMIZATION       : string  := "true";
    G_MEMORY_INIT_FILE          : string  := "none";
    G_MEMORY_INIT_PARAM         : string  := "0";
    G_MEMORY_SIZE               : integer := 262144
);
port (         
    dbiterrb                    : out std_logic;             
    doutb                       : out std_logic_vector(G_READ_DATA_WIDTH_B-1 downto 0);             
    sbiterrb                    : out std_logic;               
    addra                       : in std_logic_vector(G_ADDR_WIDTH_A-1 downto 0);
    addrb                       : in std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);
    clka                        : in std_logic;              
    clkb                        : in std_logic;                             
    dina                        : in std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
    ena                         : in std_logic;                            
    enb                         : in std_logic;    
    injectdbiterra              : in std_logic;                         
    injectsbiterra              : in std_logic;                                
    regceb                      : in std_logic;              
    rstb                        : in std_logic;
    sleep                       : in std_logic;
    wea                         : in std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0)        
);
end component;   

constant c_rw_delay : integer := 1; -- one clock cycle for read set up, one clock cycle for correction if needed

type t_addr_delay is array (( c_rw_delay)-1 downto 0 ) of std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);
type t_data_delay is array (( c_rw_delay)-1 downto 0 ) of std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
type t_wea_delay is array ((  c_rw_delay)-1 downto 0 ) of std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0);
subtype t_slv_delay is std_logic_vector( (  c_rw_delay)-1 downto 0);
type t_fsm is (idle, delay, check);

signal   s_doutb               : std_logic_vector(G_READ_DATA_WIDTH_B-1 downto 0);                      
signal   s_addra               : t_addr_delay;
signal   s_addrb               : t_addr_delay;                           
signal   s_dina                : t_data_delay;
signal   s_ena                 : t_slv_delay;                            
signal   s_enb                 : t_slv_delay;                                   
signal   s_regceb              : t_slv_delay;              
signal   s_wea                 : t_wea_delay;

                
signal   s_addra_ip            : std_logic_vector(G_ADDR_WIDTH_A-1 downto 0);
signal   s_addrb_ip            : std_logic_vector(G_ADDR_WIDTH_B-1 downto 0);                          
signal   s_dina_ip             : std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
signal   s_ena_ip              : std_logic;                           
signal   s_enb_ip              : std_logic;                                  
signal   s_regceb_ip           : std_logic;            
signal   s_wea_ip              : std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0); 

 
--signal   s_rstb                : std_logic;
--signal   s_sleep               : std_logic;
signal   s_inject_single       : t_slv_delay;
signal   s_inject_double       : t_slv_delay;
signal   s_inject_single_ip    : std_logic;
signal   s_inject_double_ip    : std_logic;    
signal   s_test_enable         : t_slv_delay;   

signal   s_sbiterrb            : std_logic;
signal   s_dbiterrb            : std_logic;

signal   s_current_state       : t_fsm;
signal   s_scrub_rd_addr       : unsigned(G_ADDR_WIDTH_B-1 downto 0):=(others =>'0');
signal   s_scrub_wr_addr       : unsigned(G_ADDR_WIDTH_A-1 downto 0):=(others =>'0');
signal   s_scrub_dina           : std_logic_vector(G_WRITE_DATA_WIDTH_A-1 downto 0);
signal   s_scrub_ena           : std_logic;
signal   s_scrub_enb           : std_logic;
signal   s_scrub_wea           : std_logic_vector(G_WRITE_DATA_WIDTH_A/G_BYTE_WRITE_WIDTH_A-1 downto 0);
signal   s_latency_cnt         : unsigned(G_READ_LATENCY_B-1 downto 0);
signal   s_scrub_err_cnt       : unsigned(G_ADDR_WIDTH_B-1 downto 0):=(others =>'0');
signal   s_scrubbing           : std_logic;

begin

bram_inst : bram_instance generic map( 
    G_ADDR_WIDTH_A       =>    G_ADDR_WIDTH_A,            
    G_ADDR_WIDTH_B       =>    G_ADDR_WIDTH_B,            
    G_WRITE_DATA_WIDTH_A =>    G_WRITE_DATA_WIDTH_A,      
    G_READ_DATA_WIDTH_B  =>    G_READ_DATA_WIDTH_B,       
    G_CLOCKING_MODE      =>    G_CLOCKING_MODE,           
    G_ECC_MODE           =>    G_ECC_MODE,                
    G_BYTE_WRITE_WIDTH_A =>    G_BYTE_WRITE_WIDTH_A,      
    G_READ_LATENCY_B     =>    G_READ_LATENCY_B,          
    G_WRITE_MODE_B       =>    G_WRITE_MODE_B,            
    G_READ_RESET_VALUE_B =>    G_READ_RESET_VALUE_B,      
    G_RST_MODE_A         =>    G_RST_MODE_A,              
    G_RST_MODE_B         =>    G_RST_MODE_B,              
    G_MEMORY_PRIMITIVE   =>    G_MEMORY_PRIMITIVE,        
    G_MEMORY_OPTIMIZATION=>    G_MEMORY_OPTIMIZATION,     
    G_MEMORY_INIT_FILE   =>    G_MEMORY_INIT_FILE,        
    G_MEMORY_INIT_PARAM  =>    G_MEMORY_INIT_PARAM,       
    G_MEMORY_SIZE        =>    G_MEMORY_SIZE             
    )
port map (   
    dbiterrb       => s_dbiterrb,              
    doutb          => s_doutb,              
    sbiterrb       => s_sbiterrb,      
    addra          => s_addra_ip,         
    addrb          => s_addrb_ip,         
    clka           => clk,          
    clkb           => clk,          
    dina           => s_dina_ip,                   
    ena            => s_ena_ip,           
    enb            => s_enb_ip,           
    injectdbiterra => s_inject_double_ip,
    injectsbiterra => s_inject_single_ip,       
    regceb         => s_regceb_ip,                 
    rstb           => rstb,          
    sleep          => sleep,         
    wea            => s_wea_ip);

delay_user_access : process(clk)
begin 
    if rising_edge(clk) then 
        s_addra         <= s_addra(s_addra'high-1 downto 0) & addra; 
        s_addrb         <= s_addrb(s_addrb'high-1 downto 0) & addrb; 
        s_dina          <= s_dina(s_dina'high-1 downto 0) & dina; 
        s_ena           <= s_ena(s_ena'high-1 downto 0) & ena;
        s_enb           <= s_enb(s_enb'high-1 downto 0) & enb;
        s_regceb        <= s_regceb(s_regceb'high-1 downto 0) & regceb;
        s_wea           <= s_wea(s_wea'high-1 downto 0) & wea;
        s_inject_double <= s_inject_double(s_inject_double'high-1 downto 0) & inject_double;
        s_inject_single <= s_inject_single(s_inject_single'high-1 downto 0) & inject_single;
    end if;
end process;

s_addra_ip          <= s_addra(s_addra'high) when s_scrubbing = '0' else std_logic_vector(s_scrub_wr_addr);
s_addrb_ip          <= s_addrb(s_addrb'high) when s_scrubbing = '0' else std_logic_vector(s_scrub_rd_addr);
s_dina_ip           <= s_dina(s_dina'high) when s_scrubbing = '0' else s_scrub_dina; 
s_ena_ip            <= s_ena(s_ena'high) when s_scrubbing = '0' else s_scrub_ena;
s_enb_ip            <= s_enb(s_enb'high) when s_scrubbing = '0' else s_scrub_enb;
s_regceb_ip         <= s_regceb(s_regceb'high);
s_wea_ip            <= s_wea(s_wea'high) when s_scrubbing = '0' else std_logic_vector(s_scrub_wea);
doutb               <= s_doutb;
s_inject_double_ip  <= s_inject_double(s_inject_double'high);
s_inject_single_ip  <= s_inject_single(s_inject_single'high);
scrubbing           <= s_scrubbing;
scrub_error_cnt     <= std_logic_vector(s_scrub_err_cnt);

process(clk)
begin
    if rising_edge(clk) then
        s_scrub_enb <= '0';
        s_scrub_ena <= '0';
        s_scrub_wea <= (others => '0');
        case s_current_state is 
            when idle => 
                if enable_scrubbing = '1' then 
                    if s_scrub_rd_addr = (s_scrub_rd_addr'range =>'1') then 
                        s_scrub_rd_addr <= (others => '0');
                    else
                        s_scrub_rd_addr <= s_scrub_rd_addr + 1;
                    end if;
                    s_scrubbing <= '1';
                    s_latency_cnt <= (others =>'0');
                    s_scrub_enb <= '1';
                    s_current_state <= delay;
                else
                    s_scrubbing <= '0';
                end if;
                
            when delay =>
                if s_latency_cnt = (G_READ_LATENCY_B-1) then 
                    s_current_state <= check;
                else 
                    s_latency_cnt <= s_latency_cnt + 1;
                end if;
            when check => 
                if s_sbiterrb = '1' then 
                    s_scrub_err_cnt <= s_scrub_err_cnt + 1; 
                    s_scrub_wr_addr <= s_scrub_rd_addr;
                    s_scrub_ena <= '1'; 
                    s_scrub_wea <= (others=>'1');
                    s_scrub_dina <= s_doutb;
                end if;
                s_current_state <= idle;
            when others =>
                s_current_state <= idle;
        end case;
    end if;             
end process; 


end architecture;