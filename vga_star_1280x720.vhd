
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga_1280x720 is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        R     : out STD_LOGIC_VECTOR(3 downto 0);
        G     : out STD_LOGIC_VECTOR(3 downto 0);
        B     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end vga_1280x720;

architecture Behavioral of vga_1280x720 is

    -- 1280 x 720 timing parameters
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

    -- Star polygon coordinates
    type integer_array is array (0 to 9) of integer;

    constant STAR_X : integer_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant STAR_Y : integer_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);
		
    -- Star Speed Settings
    constant RED_SPEED    : integer := 3;
    constant GREEN_SPEED  : integer := 4;
    constant BLUE_SPEED   : integer := 5;
    constant YELLOW_SPEED : integer := 3;
    constant CYAN_SPEED   : integer := 4;
    constant MAG_SPEED    : integer := 5;
    constant WHITE_SPEED  : integer := 6;

    -- Pixel counters
    signal x_count : integer range 0 to H_TOTAL-1 := 0;
    signal y_count : integer range 0 to V_TOTAL-1 := 0;

    -- Pixel enable accumulator for 100 MHz input clock
    signal pixel_acc : integer range 0 to 9999 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    -- Star positions
    signal red_x_pos   : integer := 220;
    signal red_y_pos   : integer := 160;

    signal green_x_pos : integer := 640;
    signal green_y_pos : integer := 160;

    signal blue_x_pos  : integer := 1060;
    signal blue_y_pos  : integer := 160;

    signal yellow_x_pos : integer := 220;
    signal yellow_y_pos : integer := 540;

    signal cyan_x_pos : integer := 640;
    signal cyan_y_pos : integer := 540;

    signal mag_x_pos : integer := 1060;
    signal mag_y_pos : integer := 540;

    signal white_x_pos : integer := 640;
    signal white_y_pos : integer := 360;

    -- Check whether a pixel is inside a star
    function point_in_star(
        px : integer;
        py : integer;
        cx : integer;
        cy : integer
    ) return boolean is

        variable inside : boolean := false;
        variable xi, yi : integer;
        variable xj, yj : integer;

    begin
        for i in 0 to 9 loop

            if i = 0 then
                xi := STAR_X(0);
                yi := STAR_Y(0);
                xj := STAR_X(9);
                yj := STAR_Y(9);
            else
                xi := STAR_X(i);
                yi := STAR_Y(i);
                xj := STAR_X(i-1);
                yj := STAR_Y(i-1);
            end if;

            if ((yi > py-cy) /= (yj > py-cy)) then

                if (px-cx) <
                   ((xj-xi) * (py-cy-yi)) / (yj-yi) + xi then

                    inside := not inside;

                end if;

            end if;

        end loop;

        return inside;

    end function;

begin

    -- Generate 74.25 MHz pixel enable from 100 MHz clock
    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                pixel_acc  <= 0;
                pixel_tick <= '0';

            else
                if pixel_acc >= 2575 then
                    pixel_acc  <= pixel_acc - 2575;
                    pixel_tick <= '1';

                else
                    pixel_acc  <= pixel_acc + 7425;
                    pixel_tick <= '0';

                end if;
            end if;

        end if;
    end process;


    -- Horizontal and vertical counters
    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                x_count <= 0;
                y_count <= 0;

            elsif pixel_tick = '1' then

                if x_count = H_TOTAL - 1 then
                    x_count <= 0;

                    if y_count = V_TOTAL - 1 then
                        y_count <= 0;
                    else
                        y_count <= y_count + 1;
                    end if;

                else
                    x_count <= x_count + 1;
                end if;

            end if;

        end if;
    end process;


    -- Horizontal sync
    hsync <= '0' when
        (x_count >= H_DISPLAY + H_FRONT and
         x_count < H_DISPLAY + H_FRONT + H_SYNC)
        else '1';

    -- Vertical sync
    vsync <= '0' when
        (y_count >= V_DISPLAY + V_FRONT and
         y_count < V_DISPLAY + V_FRONT + V_SYNC)
        else '1';


    -- Move all stars toward lower-left
    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then

                red_x_pos   <= 220;
                red_y_pos   <= 160;

                green_x_pos <= 640;
                green_y_pos <= 160;

                blue_x_pos  <= 1060;
                blue_y_pos  <= 160;

                yellow_x_pos <= 220;
                yellow_y_pos <= 540;

                cyan_x_pos <= 640;
                cyan_y_pos <= 540;

                mag_x_pos <= 1060;
                mag_y_pos <= 540;

                white_x_pos <= 640;
                white_y_pos <= 360;

            elsif pixel_tick = '1' and
                  x_count = H_TOTAL - 1 and
                  y_count = V_TOTAL - 1 then

                -- Red star: speed 2
                if red_x_pos - 2 < -70 or red_y_pos + 2 > 790 then
                    red_x_pos <= 1400;
                    red_y_pos <= -60;
                else
                    red_x_pos <= red_x_pos - RED_SPEED;
                    red_y_pos <= red_y_pos + RED_SPEED;
                end if;

                -- Green star: speed 3
                if green_x_pos - 3 < -70 or green_y_pos + 3 > 790 then
                    green_x_pos <= 1400;
                    green_y_pos <= -60;
                else
                    green_x_pos <= green_x_pos - GREEN_SPEED;
                    green_y_pos <= green_y_pos + GREEN_SPEED;
                end if;

                -- Blue star: speed 4
                if blue_x_pos - 4 < -70 or blue_y_pos + 4 > 790 then
                    blue_x_pos <= 1400;
                    blue_y_pos <= -60;
                else
                    blue_x_pos <= blue_x_pos - BLUE_SPEED;
                    blue_y_pos <= blue_y_pos + BLUE_SPEED;
                end if;

                -- Yellow star: speed 2
                if yellow_x_pos - 2 < -70 or yellow_y_pos + 2 > 790 then
                    yellow_x_pos <= 1400;
                    yellow_y_pos <= -60;
                else
                    yellow_x_pos <= yellow_x_pos - YELLOW_SPEED;
                    yellow_y_pos <= yellow_y_pos + YELLOW_SPEED;
                end if;

                -- Cyan star: speed 3
                if cyan_x_pos - 3 < -70 or cyan_y_pos + 3 > 790 then
                    cyan_x_pos <= 1400;
                    cyan_y_pos <= -60;
                else
                    cyan_x_pos <= cyan_x_pos - CYAN_SPEED;
                    cyan_y_pos <= cyan_y_pos + CYAN_SPEED;
                end if;

                -- Magenta star: speed 4
                if mag_x_pos - 4 < -70 or mag_y_pos + 4 > 790 then
                    mag_x_pos <= 1400;
                    mag_y_pos <= -60;
                else
                    mag_x_pos <= mag_x_pos - MAG_SPEED;
                    mag_y_pos <= mag_y_pos + MAG_SPEED;
                end if;

                -- White star: speed 5
                if white_x_pos - 5 < -70 or white_y_pos + 5 > 790 then
                    white_x_pos <= 1400;
                    white_y_pos <= -60;
                else
                    white_x_pos <= white_x_pos - WHITE_SPEED;
                    white_y_pos <= white_y_pos + WHITE_SPEED;
                end if;

            end if;

        end if;
    end process;


    -- RGB color generation
    process(x_count, y_count,
            red_x_pos, red_y_pos,
            green_x_pos, green_y_pos,
            blue_x_pos, blue_y_pos,
            yellow_x_pos, yellow_y_pos,
            cyan_x_pos, cyan_y_pos,
            mag_x_pos, mag_y_pos,
            white_x_pos, white_y_pos)

    begin

        -- Default: black
        R <= "0000";
        G <= "0000";
        B <= "0000";

        if x_count < H_DISPLAY and y_count < V_DISPLAY then

            -- Red star
            if point_in_star(
                x_count, y_count,
                red_x_pos, red_y_pos
            ) then

                R <= "1111";
                G <= "0000";
                B <= "0000";

            -- Green star
            elsif point_in_star(
                x_count, y_count,
                green_x_pos, green_y_pos
            ) then

                R <= "0000";
                G <= "1111";
                B <= "0000";

            -- Blue star
            elsif point_in_star(
                x_count, y_count,
                blue_x_pos, blue_y_pos
            ) then

                R <= "0000";
                G <= "0000";
                B <= "1111";

            -- Yellow star
            elsif point_in_star(
                x_count, y_count,
                yellow_x_pos, yellow_y_pos
            ) then

                R <= "1111";
                G <= "1111";
                B <= "0000";

            -- Cyan star
            elsif point_in_star(
                x_count, y_count,
                cyan_x_pos, cyan_y_pos
            ) then

                R <= "0000";
                G <= "1111";
                B <= "1111";

            -- Magenta star
            elsif point_in_star(
                x_count, y_count,
                mag_x_pos, mag_y_pos
            ) then

                R <= "1111";
                G <= "0000";
                B <= "1111";

            -- White star
            elsif point_in_star(
                x_count, y_count,
                white_x_pos, white_y_pos
            ) then

                R <= "1111";
                G <= "1111";
                B <= "1111";

            end if;

        end if;

    end process;

end Behavioral;
