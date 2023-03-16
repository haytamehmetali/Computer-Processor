library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity data_path is
	port(
			clk			: in std_logic;
			rst			: in std_logic;
			IR_Load		: in std_logic;
			MAR_Load	: in std_logic;
			PC_Load		: in std_logic;
			PC_Inc		: in std_logic;
			A_Load		: in std_logic;
			B_Load		: in std_logic;
			ALU_Sel		: in std_logic_vector(2 downto 0);
			CCR_Load	: in std_logic;
			BUS1_Sel	: in std_logic_vector(1 downto 0);
			BUS2_Sel	: in std_logic_vector(1 downto 0);
			from_memory	: in std_logic_vector(7 downto 0);
			-- Outputs
			IR			: out std_logic_vector(7 downto 0);
			address		: out std_logic_vector(7 downto 0);	-- bellege giden adres bilgisi
			CCR_Result	: out std_logic_vector(3 downto 0);	-- NZVC
			to_memory	: out std_logic_vector(7 downto 0)	-- bellege giden veri
	);
end data_path;

architecture arch of data_path is

-- ALU:
component ALU is
	port(
			A 			: in std_logic_vector(7 downto 0);	-- Signed
			B 			: in std_logic_vector(7 downto 0);	-- Signed
			ALU_Sel		: in std_logic_vector(2 downto 0);	-- Islem turu
			-- Output:
			NZVC		: out std_logic_vector(3 downto 0);
			ALU_Result	: out std_logic_vector(7 downto 0)
	);
end component;

-- Veri yolu ic siyallari:
signal BUS1			: std_logic_vector(7 downto 0);
signal BUS2			: std_logic_vector(7 downto 0);
signal ALU_Result	: std_logic_vector(7 downto 0);
signal IR_Reg		: std_logic_vector(7 downto 0);
signal MAR			: std_logic_vector(7 downto 0);
signal PC			: std_logic_vector(7 downto 0);
signal A_Reg		: std_logic_vector(7 downto 0);
signal B_Reg		: std_logic_vector(7 downto 0);
signal CCR_In		: std_logic_vector(3 downto 0);
signal CCR      	: std_logic_vector(3 downto 0);

begin

-- BUS1 Mux:
	BUS1 <= PC 			when BUS1_Sel <= "00" else
		    A_Reg 		when BUS1_Sel <= "01" else
			B_Reg 	    when BUS1_Sel <= "10" else (others => '0');
			
-- BUS2 Mux:
	BUS2 <= ALU_Result	when BUS2_Sel <= "00" else
		    BUS1 		when BUS2_Sel <= "01" else
			from_memory when BUS2_Sel <= "10" else (others => '0');


-- Komut Register (IR)
	process(clk,rst)
	begin
		if(rst = '1') then
			IR <= (others => '0');
		elsif(rising_edge(clk)) then
			if(IR_Load = '1') then
				IR <= BUS2;
			end if;
		end if;
	end process;

-- Memory Access Register (MAR)
	process(clk,rst)
	begin
		if(rst = '1') then
			MAR <= (others => '0');
		elsif(rising_edge(clk)) then
			if(MAR_Load = '1') then
				MAR <= BUS2;
			end if;
		end if;
	end process;
	address <= MAR;
	
-- Program Counter (PC)
	process(clk,rst)
	begin
		if(rst = '1') then
			PC <= (others => '0');
		elsif(rising_edge(clk)) then
			if(PC_Load = '1') then
				PC <= BUS2;
			elsif(PC_Inc = '1') then
				PC <= PC + x"01";
			end if;
		end if;
	end process;
	
-- A Register (A_Reg)
	process(clk,rst)
	begin
		if(rst = '1') then
			A_Reg <= (others => '0');
		elsif(rising_edge(clk)) then
			if(A_Load = '1') then
				A_Reg <= BUS2;
			end if;
		end if;
	end process;
	
-- B Register (B_Reg)
	process(clk,rst)
	begin
		if(rst = '1') then
			B_Reg <= (others => '0');
		elsif(rising_edge(clk)) then
			if(B_Load = '1') then
				B_Reg <= BUS2;
			end if;
		end if;
	end process;
	
-- ALU
ALU_U : ALU port map
			(
				A 			=> B_Reg,
				B 			=> BUS1,
				ALU_Sel		=> ALU_Sel,
				-- Output: 
				NZVC		=> CCR_In,
				ALU_Result	=> ALU_Result		
			);

-- CCR Register
	process(clk,rst)
	begin
		if(rst = '1') then
			CCR <= (others => '0');
		elsif(rising_edge(clk)) then
			if(CCR_Load = '1') then
				CCR <= CCR_In;	-- NZVC flag bilgisi
			end if;
		end if;
	end process;
	CCR_Result <= CCR;
	
-- Veri yolundan bellege gidecek sinyal atamasi:
	to_memory <= BUS1;

end architecture;