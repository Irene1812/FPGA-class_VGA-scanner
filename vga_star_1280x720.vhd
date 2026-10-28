
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga_1280x720 is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        R     : out STD_LOGIC_VECTOR(7 downto 0);
        G     : out STD_LOGIC_VECTOR(7 downto 0);
        B     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end vga_1280x720;

architecture Behavioral of vga_1280x720 is

    -- 1280 x 720 @ 60 Hz timing
    constant H_DISPLAY : integer := 1280;
    constant H_FRONT   : integer := 110;
    constant H_SYNC    : integer := 40;
    constant H_BACK    : integer := 220;
    constant H_TOTAL   : integer := 1650;

    constant V_DISPLAY : integer := 720;
    constant V_FRONT   : integer := 5;
    constant V_SYNC    : integer := 5;
    constant V_BACK    : integer := 20;
    constant V_TOTAL   : integer := 750;

    -- Seven star centers
    -- Top row: red, green, blue
    constant RED_X   : integer := 220;
    constant RED_Y   : integer := 160;

    constant GREEN_X : integer := 640;
    constant GREEN_Y : integer := 160;

    constant BLUE_X  : integer := 1060;
    constant BLUE_Y  : integer := 160;

    -- Bottom row: yellow, cyan, magenta
    constant YELLOW_X : integer := 220;
    constant YELLOW_Y : integer := 540;

    constant CYAN_X : integer := 640;
    constant CYAN_Y : integer := 540;

    constant MAG_X : integer := 1060;
    constant MAG_Y : integer := 540;

    -- Center: white
    constant WHITE_X : integer := 640;
    constant WHITE_Y : integer := 360;

    -- Five-point star vertices
    type point_array is array (0 to 9) of integer;

    constant star_x : point_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant star_y : point_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

    signal video_on : STD_LOGIC;

    -- Check whether a pixel is inside a star
    function point_in_star(
        px, py : integer;
        cx, cy : integer
    ) return boolean is

        variable inside : boolean := false;
        variable j : integer := 9;

        variable x1, y1 : integer;
        variable x2, y2 : integer;

        variable cross_x : integer;
        variable local_x : integer;
        variable local_y : integer;

    begin
        local_x := px - cx;
        local_y := py - cy;

        inside := false;
        j := 9;

        for i in 0 to 9 loop

            x1 := star_x(i);
            y1 := star_y(i);
            x2 := star_x(j);
            y2 := star_y(j);

            if ((y1 > local_y) /= (y2 > local_y)) then

                cross_x := x1 +
                    (local_y - y1) * (x2 - x1) /
                    (y2 - y1);

                if local_x < cross_x then
                    inside := not inside;
                end if;

            end if;

            j := i;

        end loop;

        return inside;
    end function;

begin

    -- Pixel counters update on every 74.25 MHz pixel clock
    process(clk, rst)
    begin
        if rst = '1' then
            h_count <= 0;
            v_count <= 0;

        elsif rising_edge(clk) then

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
    end process;

    -- Active display area
    video_on <= '1'
        when h_count < H_DISPLAY and v_count < V_DISPLAY
        else '0';

    -- Horizontal sync (negative polarity)
    hsync <= '0'
        when h_count >= H_DISPLAY + H_FRONT
         and h_count < H_DISPLAY + H_FRONT + H_SYNC
        else '1';

    -- Vertical sync (negative polarity)
    vsync <= '0'
        when v_count >= V_DISPLAY + V_FRONT
         and v_count < V_DISPLAY + V_FRONT + V_SYNC
        else '1';

    -- RGB display logic
    process(h_count, v_count, video_on)
    begin
        -- Default black
        R <= "00000000";
        G <= "00000000";
        B <= "00000000";

        if video_on = '1' then

            -- Red star
            if point_in_star(
                h_count, v_count, RED_X, RED_Y
            ) then
                R <= "11111111";
                G <= "00000000";
                B <= "00000000";

            -- Green star
            elsif point_in_star(
                h_count, v_count, GREEN_X, GREEN_Y
            ) then
                R <= "00000000";
                G <= "11111111";
                B <= "00000000";

            -- Blue star
            elsif point_in_star(
                h_count, v_count, BLUE_X, BLUE_Y
            ) then
                R <= "00000000";
                G <= "00000000";
                B <= "11111111";

            -- Yellow star
            elsif point_in_star(
                h_count, v_count, YELLOW_X, YELLOW_Y
            ) then
                R <= "11111111";
                G <= "11111111";
                B <= "00000000";

            -- Cyan star
            elsif point_in_star(
                h_count, v_count, CYAN_X, CYAN_Y
            ) then
                R <= "00000000";
                G <= "11111111";
                B <= "11111111";

            -- Magenta star
            elsif point_in_star(
                h_count, v_count, MAG_X, MAG_Y
            ) then
                R <= "11111111";
                G <= "00000000";
                B <= "11111111";

            -- White star
            elsif point_in_star(
                h_count, v_count, WHITE_X, WHITE_Y
            ) then
                R <= "11111111";
                G <= "11111111";
                B <= "11111111";

            end if;

        end if;
    end process;

end Behavioral;
