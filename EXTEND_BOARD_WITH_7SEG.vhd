----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:00:52 08/12/2011 
-- Design Name: 
-- Module Name:    EXTEND_BOARD_WITH_7SEG - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity EXTEND_BOARD_WITH_7SEG is
    Port ( I_CLK : in  STD_LOGIC;
			  I_RST : in  STD_LOGIC;
           I_SWITCH_RYB : in  STD_LOGIC_VECTOR(2 downto 0);
           O_SWITCH_RYB_DECHAT : out  STD_LOGIC_VECTOR (2 downto 0);
			  O_LED_RYB : out  STD_LOGIC_VECTOR (2 downto 0);
           O_R_COUNT : out  STD_LOGIC_VECTOR (7 downto 0);
           O_Y_COUNT : out  STD_LOGIC_VECTOR (7 downto 0);
           O_B_COUNT : out  STD_LOGIC_VECTOR (7 downto 0);
			  O_7SEG_LED : out STD_LOGIC_VECTOR(7 downto 0);
			  O_7SEG_LED_SELECT : out std_logic
           );
end EXTEND_BOARD_WITH_7SEG;

architecture Behavioral of EXTEND_BOARD_WITH_7SEG is
--R,Y,Bスイッチのchattering除去
--3つのLEDに対応した3つの8bitカウンタ
--Rスイッチがインクリメント，Yスイッチがデクリメント，Bスイッチがセレクタ

	--分周用
	signal sampling_timer : std_logic_vector(9 downto 0);
	signal sampling_clk	 : std_logic;
	
	--chattering除去用
	signal dechat_count : std_logic_vector(3 downto 0) := "0000";
	signal r_dechat : std_logic;
	signal y_dechat : std_logic;
	signal b_dechat : std_logic;
	
	--カウンタおよびセレクタ用
	signal repeat_timer : std_logic_vector(13 downto 0);
	signal selected_reg : std_logic_vector(1 downto 0);	
	signal b_dechat_old : std_logic;
	
	signal r_count : std_logic_vector(7 downto 0):= x"00";
	signal y_count : std_logic_vector(7 downto 0):= x"00";
	signal b_count : std_logic_vector(7 downto 0):= x"00";
	
	--7SEG LED用
	signal led_high : std_logic_vector(7 downto 0);
	signal led_low  : std_logic_vector(7 downto 0);
	signal selected_count : std_logic_vector(7 downto 0);
begin
	process(I_CLK)begin
		if(rising_edge(I_CLK))then
			if(I_RST = '1')then
				sampling_timer <= (others => '0');
			else
				sampling_timer <= sampling_timer + 1;
				sampling_clk	<= sampling_timer(9);
			end if;
		end if;
	end process;


	--chattering除去プロセス
	process(sampling_clk)begin
		if(rising_edge(sampling_clk))then
			if(I_SWITCH_RYB(2) = '0')then
				if(dechat_count = "1111")then
					r_dechat <= '1';
				end if;
			else
				r_dechat <= '0';
			end if;
			
			if(I_SWITCH_RYB(1) = '0')then
				if(dechat_count = "1111")then
					y_dechat <= '1';
				end if;
			else
				y_dechat <= '0';
			end if;
			
			if(I_SWITCH_RYB(0) = '0')then
				if(dechat_count = "1111")then
					b_dechat <= '1';
				end if;
			else
				b_dechat <= '0';
			end if;
			
			if(I_SWITCH_RYB /= "111")then
				dechat_count <= dechat_count + 1;
			else
				dechat_count <= (others => '0');
			end if;
		end if;
	end process;

	--カウンタプロセス
	process(sampling_clk)begin
		if(rising_edge(sampling_clk))then
			b_dechat_old <= b_dechat;
			if(b_dechat_old = '0' and  b_dechat = '1')then
				if(selected_reg = "10")then
					selected_reg <= (others => '0');
				else
					selected_reg <= selected_reg + 1;
				end if;
			end if;
				
			if(repeat_timer = "11111111111111" or repeat_timer = "00000000000000")then
				
				if(r_dechat = '1')then
					case(selected_reg)is
						when "00" => r_count <= r_count + 1;
						when "01" => y_count <= y_count + 1;
						when "10" => b_count <= b_count + 1;
						when others => 
					end case;
					
				elsif(y_dechat = '1')then
					case(selected_reg)is
						when "00" => r_count <= r_count - 1;
						when "01" => y_count <= y_count - 1;
						when "10" => b_count <= b_count - 1;
						when others => 
					end case;
				end if;
			end if;
			
			if(r_dechat = '1' or y_dechat = '1')then
				if(repeat_timer =  "11111111111111")then
					repeat_timer <= "11110000000000";
				else
					repeat_timer <= repeat_timer + 1;
				end if;
			else
				repeat_timer <= (others => '0');
			end if;
		end if;
	end process;
	
	O_SWITCH_RYB_DECHAT <= r_dechat & y_dechat & b_dechat;
	with(selected_reg)select
	O_LED_RYB <= 	"100" when "00",
						"010" when "01",
						"001" when "10",
						"000" when others;
	O_R_COUNT <= r_count;
	O_Y_COUNT <= y_count;
	O_B_COUNT <= b_count;

	
	-------------------------------------
	--7seg LED decoder
	-------------------------------------
	with(selected_reg)select
	selected_count <= 	r_count when "00",
								y_count when "01",
								b_count when "10",
							(others => '0') when others;
							
	with(selected_count(7 downto 4))select
	led_high <=		"11111100" when x"0",
						"01100000" when x"1",
						"11011010" when x"2", 
						"11110010" when x"3",
						"01100110" when x"4",
						"10110110" when x"5",
						"10111110" when x"6",
						"11100100" when x"7",
						"11111110" when x"8",
						"11110110" when x"9",
						"11101110" when x"A",
						"00111110" when x"b",
						"00011010" when x"c",
						"01111010" when x"d",
						"10011110" when x"E",
						"10001110" when x"F",
						"00000000" when others;
	
	with(selected_count(3 downto 0))select
	led_low <=		"11111100" when x"0",
						"01100000" when x"1",
						"11011010" when x"2", 
						"11110010" when x"3",
						"01100110" when x"4",
						"10110110" when x"5",
						"10111110" when x"6",
						"11100100" when x"7",
						"11111110" when x"8",
						"11110110" when x"9",
						"11101110" when x"A",
						"00111110" when x"b",
						"00011010" when x"c",
						"01111010" when x"d",
						"10011110" when x"E",
						"10001110" when x"F",
						"00000000" when others;
	
	O_7SEG_LED 			<=	led_high		when sampling_clk = '1' else
								led_low;
	O_7SEG_LED_SELECT	<=	'0'			when sampling_clk = '0' else
								'1';
end Behavioral;

