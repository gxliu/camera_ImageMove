----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:08:34 08/03/2011 
-- Design Name: 
-- Module Name:    camera_to_display - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity camera_to_display is
    Port ( 
		I_CLK25 : in  STD_LOGIC;
		O_PILOT_LED		: out std_logic;
		--Camera
		--J15
		I_C1PCLK		: in std_logic; --from camera
		O_C1MCLK		: out	std_logic; --to camera(10 - 24 - 27Mhz)
		O_C1PWDN		: out std_logic; --0:power on		1:power off
		I_C1HREF		: in std_logic; 
		I_C1VSYNC	: in std_logic;
		O_C1RSTB		: out std_logic; --0:				1:reset (all registers change to default value)
		O_C1SCL		: out std_logic; 	 --Serial interface clock(400khz)
		IO_C1SDA		: inout std_logic; --Serial interface data I/O
		I_C1D			: in std_logic_vector(9 downto 0); --YUVU

		--Display
		--Used by LCD and VGA
		O_VGA_R : out std_logic_vector(7 downto 0);--LCD only use 7 downto 2
		O_VGA_G : out std_logic_vector(7 downto 0);--LCD only use 7 downto 2
		O_VGA_B : out std_logic_vector(7 downto 0);--LCD only use 7 downto 2
		O_VGA_HSYNC : out std_logic; --(LCD)negative logic
		O_VGA_VSYNC : out std_logic; --(LCD)negative logic
		--LCD
		O_LCD_CLK	: out std_logic;
		O_LCD_ENB 	: out std_logic; --0:power off	1:power on
		O_LCD_RL	: out std_logic; --0:normal 		1:mirror
		O_LCD_UD	: out std_logic; --0:upside down	1:normal
		O_LCD_VQ	: out std_logic; --0:QVGA 			1:VGA
		O_LCD_ON	: out std_logic; --backlight 
		--VGA
		O_VGA_CLK		: out std_logic; 
		O_VGA_nBLANK	: out std_logic; --0:blanking time		1:valid signal	
		O_VGA_nPSAVE	: out std_logic; --0:power off			1:power on
		O_VGA_nSYNC	: out std_logic; --0:green with sync	1:sync off
		
		--EXTEND_BOARD
		I_EXTEND_SWITCH_RYB	: in std_logic_vector(2 downto 0);
		O_EXTEND_LED_RYB 		: out std_logic_vector(2 downto 0);
		
		O_EXTEND_7SEG_LED				: out std_logic_vector(7 downto 0);
		O_EXTEND_7SEG_LED_SELECT	: out std_logic
	 );
end camera_to_display;

architecture Behavioral of camera_to_display is
----------------------------------------------------------------
--Digital Clock Managner
----------------------------------------------------------------
	COMPONENT DCM1
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKDV_OUT : OUT std_logic;
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;


	COMPONENT DCM2
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;

	signal clk_1x			: std_logic;
	signal clk_div			: std_logic;
	signal clk_fx 			: std_logic;
	signal clk_raw1 		: std_logic;
	signal dcm1_locked	: std_logic;
	signal rst_from_dcm1 : std_logic;

	signal clk_raw2		: std_logic;
	signal dcm2_locked	: std_logic;
	signal rst_from_dcm2 : std_logic;
	
	----------------------------------------------------------
	--�J����
	----------------------------------------------------------
	signal cam1_clk					: std_logic;
	signal cam1_y						: std_logic_vector(7 downto 0);
	signal cam1_y_valid				: std_logic;
	signal cam1_pixel_count			: std_logic_vector(9 downto 0);
	signal cam1_line_count			: std_logic_vector(9 downto 0);
	signal cam1_write_enable		: std_logic_vector(0 downto 0);
	signal cam1_write_addr			: std_logic_vector(14 downto 0);
	signal cam1_href_old				: std_logic;
	
	----------------------------------------------------------
	--�摜������
	----------------------------------------------------------
	COMPONENT VRAM160x120x8
		PORT (
			clka : IN STD_LOGIC;
			wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			clkb : IN STD_LOGIC;
			addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
	END COMPONENT;
	
	constant C_MEMORY_WIDTH		: integer := 160;
	constant C_MEMORY_HEIGHT	: integer := 120;
	constant C_MEMORY_SIZE		: integer := 19200;
	
	----------------------------------------------------------
	--�f�B�X�v���C
	----------------------------------------------------------
	constant C_DISP_WIDTH			: integer := 793;
	constant C_DISP_HEIGHT			: integer := 525;
	constant C_DISP_VALID_WIDTH 	: integer := 640;
	constant C_DISP_VALID_HEIGHT 	: integer := 480;
	constant C_DISP_HSYNC_WIDTH	: integer := 96;
	constant C_DISP_HSYNC_BP		: integer := 44;
	constant C_DISP_VSYNC_WIDTH	: integer := 3;
	constant C_DISP_VSYNC_BP		: integer := 32;
	
	signal disp_clk				: std_logic;
	signal disp_line_count		: std_logic_vector(9 downto 0);
	signal disp_pixel_count		: std_logic_vector(9 downto 0);
	signal disp_vsync				: std_logic;
	signal disp_hsync				: std_logic;
	signal disp_enable			: std_logic;
	signal disp_enable_8d		: std_logic_vector(7 downto 0);
	signal disp_y					: std_logic_vector(7 downto 0);
	signal disp_read_addr		: std_logic_vector(14 downto 0);
	
	------- �ǉ������M���� -------
	signal disp_h_addr			: std_logic_vector(9 downto 0);
	signal disp_v_addr			: std_logic_vector(9 downto 0);
	signal disp_y_color        : std_logic_vector(7 downto 0);     -- LCD�ɕ\��������ʌ���
	signal disp_y_shadow       : std_logic_vector(9 downto 0);     -- �e�̕������J�E���g����
	signal disp_shift          : integer range 0 to 512;           -- �ǂꂾ�����炷��
	signal disp_pixel_count_shift : std_logic_vector(9 downto 0);  -- ���炷���߂̂������l
	
	-----------------------------------------
	--EXTEND_BOARD
	-----------------------------------------
	COMPONENT EXTEND_BOARD_WITH_7SEG
	PORT(
		I_CLK : IN std_logic;
		I_RST : IN std_logic;
		I_SWITCH_RYB : IN std_logic_vector(2 downto 0);          
		O_SWITCH_RYB_DECHAT : OUT std_logic_vector(2 downto 0);
		O_LED_RYB : OUT std_logic_vector(2 downto 0);
		O_R_COUNT : OUT std_logic_vector(7 downto 0);
		O_Y_COUNT : OUT std_logic_vector(7 downto 0);
		O_B_COUNT : OUT std_logic_vector(7 downto 0);
		O_7SEG_LED : OUT std_logic_vector(7 downto 0);
		O_7SEG_LED_SELECT : OUT std_logic
		);
	END COMPONENT;
	
	signal ui_switch_ryb_dechat : std_logic_Vector(2 downto 0);
	signal ui_led_ryb : std_logic_vector(2 downto 0);
	signal ui_r_count : std_logic_vector(7 downto 0);
	signal ui_y_count : std_logic_vector(7 downto 0);
	signal ui_b_count : std_logic_vector(7 downto 0);
	
begin
	---------------------------------------------------------
	--Digital Clock Manager
	---------------------------------------------------------
	MAIN_DCM: DCM1 PORT MAP(
		CLKIN_IN => I_CLK25,
		RST_IN => '0',
		CLKDV_OUT => clk_div,
		CLKFX_OUT => clk_fx,
		CLKIN_IBUFG_OUT => clk_raw1,
		CLK0_OUT => clk_1x,
		LOCKED_OUT => dcm1_locked
	);
	
	CAM1_DCM: DCM2 PORT MAP(
		CLKIN_IN => I_C1PCLK,
		RST_IN => rst_from_dcm1,
		CLKIN_IBUFG_OUT => clk_raw2,
		CLK0_OUT => cam1_clk,
		LOCKED_OUT => dcm2_locked
	);
	
	rst_from_dcm1	<= not dcm1_locked;
	O_PILOT_LED		<= not dcm2_locked;
	----------------------------------------------------------
	--�J����
	----------------------------------------------------------
	O_C1MCLK	<= clk_div; 									--to camera(10 - 24 - 27Mhz)
	O_C1PWDN <= '0';											--always ON 0:power on		1:power off
	O_C1RSTB <= (not rst_from_dcm1); --1:reset (all registers change to default value)
	O_C1SCL	<= '0';											--Don't use --Serial interface clock(400khz)
	IO_C1SDA	<= 'Z';											--High impedance --Serial interface data I/O
	
	--FPGA���狟�������N���b�N��2�{�̃N���b�N��Ԃ�
	--��f�M����I_C1HREF = '1'����I_C1VSYNC = '0'�̎��ɑ����Ă���
	--��f�M����Y U Y V �̏��Ԃő����Ă���
	process(cam1_clk)begin
		if(rising_edge(cam1_clk))then
			--���������̃J�E���g------------------------------------------
			cam1_href_old <= I_C1HREF;
			if(I_C1VSYNC = '1')then
				cam1_line_count	<= (others => '0');
			else
				if(cam1_href_old = '1' and I_C1HREF = '0')then
					cam1_line_count	<= cam1_line_count + 1;
				end if;
			end if;

			--�P�x�f�[�^�̔����o��+�s�N�Z�����̃J�E���g----------------------
			if(I_C1HREF = '0')then
				cam1_y_valid		<= '0';
				cam1_pixel_count	<= (others => '1');
			else
				cam1_y_valid		<= not cam1_y_valid;
				--�����̏ꍇ�P�x�f�[�^�𔲂��o��
				if(cam1_y_valid = '0')then
					cam1_pixel_count <= cam1_pixel_count + 1;
					cam1_y	<= I_C1D(9 downto 2);
				end if;
			end if;		
		end if;
	end process;
	
	--�������ݗp�̃A�h���X�̍쐬
	--cam1_line_count�̉���2bit��؂邱�Ƃ�4�Ŋ���C���l��cam1_data_count�̉���3bit��؂邱�Ƃ�8�Ŋ���
	cam1_write_addr <= (cam1_line_count(9 downto 2) * CONV_std_logic_vector(C_MEMORY_WIDTH,8)) + cam1_pixel_count(9 downto 2);
	--�������݃C�l�[�u���M���̍쐬
	--cam1_line_count(1 downto 0) = "00"��4���1��
	--cam1_data_count(2 downto 0) = "001"��8���1��C�܂�"000"�̎��Ƀf�[�^�����W�X�^������Ă���̂ł��̌��"001"�Ń������ɏ�������
	cam1_write_enable <= 		"1" 	when ((cam1_line_count(1 downto 0) = "00") and (cam1_pixel_count(1 downto 0) = "00"))
								else	"0";
	
	--------------------------------------------------------
	--�摜������
	--------------------------------------------------------
	VRAM1 : VRAM160x120x8
	PORT MAP (
		--�J��������̏�������
		clka	=>	cam1_clk,
		wea	=>	cam1_write_enable,
		addra	=>	cam1_write_addr,
		dina 	=>	cam1_y,
		
		--�f�B�X�v���C����̓ǂݏo��
		clkb	=>	disp_clk,
		addrb	=>	disp_read_addr,
		doutb	=>	disp_y
	);
	---------------------------------------------------------
	--�f�B�X�v���C
	---------------------------------------------------------
	--LCD
	O_LCD_CLK	<= disp_clk;
	O_LCD_RL		<= '0'; --0:normal 		1:mirror
	O_LCD_UD		<= '1'; --0:upside down	1:normal
	O_LCD_VQ		<= '1'; --0:QVGA 			1:VGA
	O_LCD_ON 	<= '1'; --0:power off	1:power on --backlight 
	--VGA
	O_VGA_CLK		<= not disp_clk;
	O_VGA_nSYNC		<= '1'; 	--0:green with sync	1:sync off
	O_VGA_nPSAVE	<= '1';	--0:power off			1:power on
	
	--Pixel Line Counter
	--�f�B�X�v���C�̑��s�N�Z�����ƁC��������������
	--LINE = 525, PIXEL = 793
	disp_clk <= clk_1x;
	
	process(disp_clk)begin
		if(rising_edge(disp_clk))then
			if(rst_from_dcm1 = '1')then
				disp_pixel_count  <= (others => '0');
				disp_line_count 	<= (others => '0');
			else
				--�s�N�Z���̃J�E���g
				if(disp_pixel_count >= C_DISP_WIDTH - 1)then
					disp_pixel_count <= (others=> '0');
					--�������̃J�E���g
					if(disp_line_count >= C_DISP_HEIGHT - 1)then
						disp_line_count <= (others=> '0');
					else
						disp_line_count <= disp_line_count + 1;
					end if;
				else
					disp_pixel_count <= disp_pixel_count + 1;
				end if;
			end if;
		end if;
	end process;
	
	--HSYNC VSYNC generator
	process(disp_clk)begin
		if(rising_edge(disp_clk))then
			--VSYNC generator
			-- 490�@- 492 ��3�{��VSYNC����
			if(C_DISP_HEIGHT - C_DISP_VSYNC_WIDTH - C_DISP_VSYNC_BP <= disp_line_count and disp_line_count < C_DISP_HEIGHT - C_DISP_VSYNC_BP)then
				disp_vsync <= '0';
			else
				disp_vsync <= '1';
			end if;
			
			--HSYNC generator
			-- 653 - 748 ��96�s�N�Z����HSYNC����
			if(C_DISP_WIDTH - C_DISP_HSYNC_WIDTH - C_DISP_HSYNC_BP <= disp_pixel_count and disp_pixel_count < C_DISP_WIDTH - C_DISP_HSYNC_BP)then
				disp_hsync <= '0';
			else
				disp_hsync <= '1';
			end if;
			
			--enable generator
			--pixel 640�����C line 480�����̍ۂ�ENABLE�M���𔭌�
			if(disp_pixel_count < C_DISP_VALID_WIDTH and disp_line_count < C_DISP_VALID_HEIGHT)then
				disp_enable <= '1';
			else
				disp_enable <= '0';
			end if;
			--enable�M���̃f�B���C�p�C�^�C�~���O�����̂���
			disp_enable_8d <= disp_enable_8d(6 downto 0) & disp_enable;
		end if;
	end process;
	
	-- Read Address Calculator
	-- ��ʂ��V�t�g�����鏈��
	disp_pixel_count_shift <= disp_pixel_count + disp_shift;
	process(disp_clk)begin
		if(rising_edge(disp_clk))then
			disp_v_addr <= "00" & disp_line_count(9 downto 2);
			-- �������T�C�Y�Ƃ̔�r
			if(disp_pixel_count_shift(9 downto 2) < C_MEMORY_WIDTH)then
				disp_h_addr <= "00" & disp_pixel_count_shift(9 downto 2);
				-- �J�����摜���̂܂�
				disp_y_color <= disp_y;
			-- ����镔��
			else
				-- �傫������̂ŁA�������T�C�Y�����Z
				disp_h_addr <= disp_pixel_count_shift(9 downto 2) - C_MEMORY_WIDTH;
				-- ���ɓh��Ԃ�
				disp_y_color <= X"00";
			end if;
		end if;
	end process;
	
	-- ���炷�ʒu�����߂鏈��
	process(disp_clk)begin
		if(rising_edge(disp_clk))then
			-- �J�����ɑ΂��āA�����ԕ����Ŕ���
			if(disp_line_count > 260 and disp_line_count < 264)then
				-- �������l�𒴂���(�����Ă��Ȃ�)
				if(disp_y > 40)then
					-- �摜�̓Y���Ȃ�
					disp_shift <= 0;
				-- �������l�𒴂��Ȃ�(�����Ă���)
				else
					disp_shift <= 300;
				end if;
			end if;
		end if;
	end process;
	
	disp_read_addr <= (disp_v_addr * CONV_std_logic_vector(C_MEMORY_WIDTH,8)) + disp_h_addr;
	
	--RGB_substitution
	O_VGA_R		<= disp_y_color;
	O_VGA_G		<= disp_y_color;
	O_VGA_B		<= disp_y_color;

	--LCD_ENB�͗L����f��\���Ă��邽�߁A
	--MEMORY����̓ǂݏo���^�C�~���O�ȂǂƓ������Ƃ�K�v������B
	--������LCD_ENB�ɓK�؂ȃf�B���C��^����B
	--disp_enable��1delay disp_enable_8d(0)��2delay disp_enable_8d(1)��3delay...
	O_LCD_ENB		<= disp_enable_8d(0); 
	O_VGA_nBLANK	<= disp_enable_8d(0); --0: 1:active area
	O_VGA_VSYNC		<= disp_vsync;
	O_VGA_HSYNC 	<= disp_hsync;
	
	---------------------------------------------------------
	--EXTEND_BOARD
	---------------------------------------------------------
	Inst_EXTEND_BOARD_WITH_7SEG: EXTEND_BOARD_WITH_7SEG PORT MAP(
		I_CLK => clk_1x,
		I_RST => rst_from_dcm1,
		I_SWITCH_RYB => I_EXTEND_SWITCH_RYB,
		O_SWITCH_RYB_DECHAT => ui_switch_ryb_dechat,
		O_LED_RYB => O_EXTEND_LED_RYB,
		O_R_COUNT => ui_r_count,
		O_Y_COUNT => ui_y_count,
		O_B_COUNT => ui_b_count,
		O_7SEG_LED => O_EXTEND_7SEG_LED,
		O_7SEG_LED_SELECT => O_EXTEND_7SEG_LED_SELECT
	);
end Behavioral;