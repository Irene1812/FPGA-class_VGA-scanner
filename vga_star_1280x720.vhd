
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_star is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;

        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;

        red   : out STD_LOGIC_VECTOR(3 downto 0);
        green : out STD_LOGIC_VECTOR(3 downto 0);
        blue  : out STD_LOGIC_VECTOR(3 downto 0)
    );
end vga_star;

architecture Behavioral of vga_star is

    ----------------------------------------------------------------
    -- VGA 1280 x 720 Timing
    ----------------------------------------------------------------
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

    ----------------------------------------------------------------
    -- Star Movement Speed
    ----------------------------------------------------------------
    constant RED_SPEED   : integer := 4;
    constant GREEN_SPEED : integer := 5;
    constant BLUE_SPEED  : integer := 6;

    ----------------------------------------------------------------
    -- Brightness Speed Control
    -- Larger value = slower brightness change
    ----------------------------------------------------------------
    constant BRIGHT_DIV : integer := 3;

    signal bright_counter :
        integer range 0 to BRIGHT_DIV-1 := 0;

    ----------------------------------------------------------------
    -- Star Shape
    ----------------------------------------------------------------
    type star_array is array (0 to 9) of integer;

    constant STAR_X : star_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant STAR_Y : star_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);

    ----------------------------------------------------------------
    -- VGA Counters
    ----------------------------------------------------------------
    signal x_count : integer range 0 to H_TOTAL-1 := 0;
    signal y_count : integer range 0 to V_TOTAL-1 := 0;

    signal pixel_acc  : integer range 0 to 9999 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    ----------------------------------------------------------------
    -- Star Positions
    ----------------------------------------------------------------
    signal red_x   : integer := 640;
    signal red_y   : integer := 160;

    signal green_x : integer := 400;
    signal green_y : integer := 440;

    signal blue_x  : integer := 880;
    signal blue_y  : integer := 440;

    ----------------------------------------------------------------
    -- Brightness Level
    -- Range: 0 to 15
    ----------------------------------------------------------------
    signal red_level   : integer range 0 to 15 := 0;
    signal green_level : integer range 0 to 15 := 0;
    signal blue_level  : integer range 0 to 15 := 0;

    signal red_up   : STD_LOGIC := '1';
    signal green_up : STD_LOGIC := '1';
    signal blue_up  : STD_LOGIC := '1';

    ----------------------------------------------------------------
    -- Star Detection Function
    ----------------------------------------------------------------
    function point_in_star (
        px : integer;
        py : integer;
        cx : integer;
        cy : integer
    ) return boolean is

        variable inside : boolean := false;
        variable j      : integer := 9;

        variable xi : integer;
        variable yi : integer;
        variable xj : integer;
        variable yj : integer;

    begin

        for i in 0 to 9 loop

            xi := cx + STAR_X(i);
            yi := cy + STAR_Y(i);

            xj := cx + STAR_X(j);
            yj := cy + STAR_Y(j);

            if ((yi > py) /= (yj > py)) then

                if px < (xj - xi) * (py - yi) /
                        (yj - yi) + xi then

                    inside := not inside;

                end if;

            end if;

            j := i;

        end loop;

        return inside;

    end function;

begin

    ----------------------------------------------------------------
    -- Process 1: Pixel Clock Enable
    -- 100 MHz input, approximately 74.25 MHz pixel enable
    ----------------------------------------------------------------
    process(clk, rst)
    begin

        if rst = '1' then

            pixel_acc  <= 0;
            pixel_tick <= '0';

        elsif rising_edge(clk) then

            if pixel_acc >= 2575 then

                pixel_acc  <= pixel_acc - 2575;
                pixel_tick <= '1';

            else

                pixel_acc  <= pixel_acc + 7425;
                pixel_tick <= '0';

            end if;

        end if;

    end process;

    ----------------------------------------------------------------
    -- Process 2: VGA Horizontal and Vertical Counters
    ----------------------------------------------------------------
    process(clk, rst)
    begin

        if rst = '1' then

            x_count <= 0;
            y_count <= 0;

        elsif rising_edge(clk) then

            if pixel_tick = '1' then

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

    ----------------------------------------------------------------
    -- Process 3: VGA Synchronization Signals
    ----------------------------------------------------------------
    process(x_count, y_count)
    begin

        -- Horizontal Sync
        if (x_count >= H_DISPLAY + H_FRONT) and
           (x_count < H_DISPLAY + H_FRONT + H_SYNC) then

            hsync <= '0';

        else

            hsync <= '1';

        end if;

        -- Vertical Sync
        if (y_count >= V_DISPLAY + V_FRONT) and
           (y_count < V_DISPLAY + V_FRONT + V_SYNC) then

            vsync <= '0';

        else

            vsync <= '1';

        end if;

    end process;

    ----------------------------------------------------------------
    -- Process 4: Star Movement
    -- Stars move toward lower-left
    ----------------------------------------------------------------
    process(clk, rst)
    begin

        if rst = '1' then

            red_x   <= 640;
            red_y   <= 160;

            green_x <= 400;
            green_y <= 440;

            blue_x  <= 880;
            blue_y  <= 440;

        elsif rising_edge(clk) then

            if pixel_tick = '1' and
               x_count = H_TOTAL - 1 and
               y_count = V_TOTAL - 1 then

                -- Red Star
                if red_x > -100 and red_y < 820 then

                    red_x <= red_x - RED_SPEED;
                    red_y <= red_y + RED_SPEED;

                else

                    red_x <= 1280;
                    red_y <= 0;

                end if;

                -- Green Star
                if green_x > -100 and green_y < 820 then

                    green_x <= green_x - GREEN_SPEED;
                    green_y <= green_y + GREEN_SPEED;

                else

                    green_x <= 1280;
                    green_y <= 0;

                end if;

                -- Blue Star
                if blue_x > -100 and blue_y < 820 then

                    blue_x <= blue_x - BLUE_SPEED;
                    blue_y <= blue_y + BLUE_SPEED;

                else

                    blue_x <= 1280;
                    blue_y <= 0;

                end if;

            end if;

        end if;

    end process;

    ----------------------------------------------------------------
    -- Process 5: Brightness Control
    -- Update brightness every BRIGHT_DIV frames
    ----------------------------------------------------------------
    process(clk, rst)
    begin

        if rst = '1' then

            red_level   <= 0;
            green_level <= 0;
            blue_level  <= 0;

            red_up   <= '1';
            green_up <= '1';
            blue_up  <= '1';

            bright_counter <= 0;

        elsif rising_edge(clk) then

            if pixel_tick = '1' and
               x_count = H_TOTAL - 1 and
               y_count = V_TOTAL - 1 then

                if bright_counter = BRIGHT_DIV - 1 then

                    bright_counter <= 0;

                    ------------------------------------------------
                    -- Red Brightness
                    ------------------------------------------------
                    if red_up = '1' then

                        if red_level < 15 then
                            red_level <= red_level + 1;
                        else
                            red_up    <= '0';
                            red_level <= 14;
                        end if;

                    else

                        if red_level > 0 then
                            red_level <= red_level - 1;
                        else
                            red_up    <= '1';
                            red_level <= 1;
                        end if;

                    end if;

                    ------------------------------------------------
                    -- Green Brightness
                    ------------------------------------------------
                    if green_up = '1' then

                        if green_level < 15 then
                            green_level <= green_level + 1;
                        else
                            green_up    <= '0';
                            green_level <= 14;
                        end if;

                    else

                        if green_level > 0 then
                            green_level <= green_level - 1;
                        else
                            green_up    <= '1';
                            green_level <= 1;
                        end if;

                    end if;

                    ------------------------------------------------
                    -- Blue Brightness
                    ------------------------------------------------
                    if blue_up = '1' then

                        if blue_level < 15 then
                            blue_level <= blue_level + 1;
                        else
                            blue_up    <= '0';
                            blue_level <= 14;
                        end if;

                    else

                        if blue_level > 0 then
                            blue_level <= blue_level - 1;
                        else
                            blue_up    <= '1';
                            blue_level <= 1;
                        end if;

                    end if;

                else

                    bright_counter <= bright_counter + 1;

                end if;

            end if;

        end if;

    end process;

    ----------------------------------------------------------------
    -- Process 6: RGB Output
    -- 4-bit RGB provides 16 brightness levels
    ----------------------------------------------------------------
    process(
        x_count, y_count,
        red_x, red_y,
        green_x, green_y,
        blue_x, blue_y,
        red_level, green_level, blue_level
    )
    begin

        -- Default: Black Background
        red   <= "0000";
        green <= "0000";
        blue  <= "0000";

        if x_count < H_DISPLAY and
           y_count < V_DISPLAY then

            -- Red Star
            if point_in_star(
                x_count, y_count, red_x, red_y
            ) then

                red <= std_logic_vector(
                    to_unsigned(red_level, 4)
                );

            end if;

            -- Green Star
            if point_in_star(
                x_count, y_count, green_x, green_y
            ) then

                green <= std_logic_vector(
                    to_unsigned(green_level, 4)
                );

            end if;

            -- Blue Star
            if point_in_star(
                x_count, y_count, blue_x, blue_y
            ) then

                blue <= std_logic_vector(
                    to_unsigned(blue_level, 4)
                );

            end if;

        end if;

    end process;

end Behavioral;
