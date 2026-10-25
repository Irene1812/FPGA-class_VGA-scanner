library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga_640x480 is
    Port (
        clk  : in  STD_LOGIC;
        rst  : in  STD_LOGIC;

        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;

        R : out STD_LOGIC;
        G : out STD_LOGIC;
        B : out STD_LOGIC
    );
end vga_640x480;

architecture Behavioral of vga_640x480 is

    -- VGA 640x480 timing parameters
    constant H_DISPLAY : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BACK    : integer := 48;
    constant H_TOTAL   : integer := 800;

    constant V_DISPLAY : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := 525;

    -- Rectangle 1: red
    constant X1 : integer := 50;
    constant Y1 : integer := 50;
    constant W1 : integer := 150;
    constant H1 : integer := 100;

    -- Rectangle 2: green
    constant X2 : integer := 250;
    constant Y2 : integer := 150;
    constant W2 : integer := 120;
    constant H2 : integer := 150;

    -- Rectangle 3: blue
    constant X3 : integer := 420;
    constant Y3 : integer := 250;
    constant W3 : integer := 160;
    constant H3 : integer := 120;

    signal div_count : integer range 0 to 3 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    signal h_count : integer range 0 to 799 := 0;
    signal v_count : integer range 0 to 524 := 0;

    signal video_on : STD_LOGIC;

begin

    -- 100 MHz / 4 = 25 MHz pixel enable
    pixel_tick <= '1' when div_count = 3 else '0';

    process(clk, rst)
    begin
        if rst = '1' then
            div_count <= 0;
        elsif rising_edge(clk) then
            if div_count = 3 then
                div_count <= 0;
            else
                div_count <= div_count + 1;
            end if;
        end if;
    end process;

    -- Horizontal and vertical scanning counters
    process(clk, rst)
    begin
        if rst = '1' then
            h_count <= 0;
            v_count <= 0;

        elsif rising_edge(clk) then
            if pixel_tick = '1' then

                if h_count = H_TOTAL - 1 then
                    h_count <= 0;

                    if v_count = V_TOTAL - 1 then
                        v_count <= 0;
                    else
                        v_count <= v_count + 1;
                    end if;

                else
                    h_count <= h_count + 1;
                end if;

            end if;
        end if;
    end process;

    -- Active display region
    video_on <= '1'
        when h_count < H_DISPLAY and
             v_count < V_DISPLAY
        else '0';

    -- VGA synchronization signals (active low)
    hsync <= '0'
        when h_count >= 656 and h_count < 752
        else '1';

    vsync <= '0'
        when v_count >= 490 and v_count < 492
        else '1';

    -- Draw three independent rectangles
    process(h_count, v_count, video_on)
    begin
        R <= '0';
        G <= '0';
        B <= '0';

        if video_on = '1' then

            -- Rectangle 1: red
            if h_count >= X1 and h_count < X1 + W1 and
               v_count >= Y1 and v_count < Y1 + H1 then
                R <= '1';

            -- Rectangle 2: green
            elsif h_count >= X2 and h_count < X2 + W2 and
                  v_count >= Y2 and v_count < Y2 + H2 then
                G <= '1';

            -- Rectangle 3: blue
            elsif h_count >= X3 and h_count < X3 + W3 and
                  v_count >= Y3 and v_count < Y3 + H3 then
                B <= '1';
            end if;

        end if;
    end process;

end Behavioral;
