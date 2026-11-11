
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

    ------------------------------------------------------------
    -- VGA 1280 x 720 Timing
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Star Color Exchange
    ------------------------------------------------------------
    constant COLOR_CHANGE_FRAMES : integer := 60;

    signal color_frame_counter :
        integer range 0 to COLOR_CHANGE_FRAMES-1 := 0;

    signal color_phase :
        integer range 0 to 2 := 0;

    ------------------------------------------------------------
    -- Star Shape
    ------------------------------------------------------------
    type star_array is array (0 to 9) of integer;

    constant STAR_X : star_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant STAR_Y : star_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);

    ------------------------------------------------------------
    -- VGA Counters
    ------------------------------------------------------------
    signal x_count : integer range 0 to H_TOTAL-1 := 0;
    signal y_count : integer range 0 to V_TOTAL-1 := 0;

    signal pixel_acc  : integer range 0 to 9999 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    ------------------------------------------------------------
    -- Fixed Star Positions
    ------------------------------------------------------------
    constant RED_X   : integer := 320;
    constant RED_Y   : integer := 360;

    constant GREEN_X : integer := 640;
    constant GREEN_Y : integer := 360;

    constant BLUE_X  : integer := 960;
    constant BLUE_Y  : integer := 360;

    ------------------------------------------------------------
    -- Star Detection Function
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Process 1: Pixel Clock Enable
    ------------------------------------------------------------
    PIXEL_CLOCK : process(clk, rst)
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

    ------------------------------------------------------------
    -- Process 2: VGA Horizontal and Vertical Counters
    ------------------------------------------------------------
    VGA_COUNTER : process(clk, rst)
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

    ------------------------------------------------------------
    -- Process 3: VGA Synchronization Signals
    ------------------------------------------------------------
    SYNC_SIGNAL : process(x_count, y_count)
    begin

        if (x_count >= H_DISPLAY + H_FRONT) and
           (x_count < H_DISPLAY + H_FRONT + H_SYNC) then

            hsync <= '0';

        else

            hsync <= '1';

        end if;

        if (y_count >= V_DISPLAY + V_FRONT) and
           (y_count < V_DISPLAY + V_FRONT + V_SYNC) then

            vsync <= '0';

        else

            vsync <= '1';

        end if;

    end process;

    ------------------------------------------------------------
    -- Process 4: Star Color Exchange
    -- RGB -> GBR -> BRG -> RGB
    ------------------------------------------------------------
    COLOR_CHANGE :　process(clk, rst)
    begin

        if rst = '1' then

            color_frame_counter <= 0;
            color_phase <= 0;

        elsif rising_edge(clk) then

            if pixel_tick = '1' and
               x_count = H_TOTAL - 1 and
               y_count = V_TOTAL - 1 then

                if color_frame_counter =
                   COLOR_CHANGE_FRAMES - 1 then

                    color_frame_counter <= 0;

                    if color_phase = 2 then
                        color_phase <= 0;
                    else
                        color_phase <= color_phase + 1;
                    end if;

                else

                    color_frame_counter <=
                        color_frame_counter + 1;

                end if;

            end if;

        end if;

    end process;

    ------------------------------------------------------------
    -- Process 5: RGB Output
    -- Fixed Positions + Color Exchange
    ------------------------------------------------------------
    RGB_OUTPUT :　process(x_count, y_count, color_phase)
    begin

        -- Black Background
        red   <= "0000";
        green <= "0000";
        blue  <= "0000";

        if x_count < H_DISPLAY and
           y_count < V_DISPLAY then

            ----------------------------------------------------
            -- Star 1
            ----------------------------------------------------
            if point_in_star(
                x_count, y_count, RED_X, RED_Y
            ) then

                case color_phase is

                    when 0 =>
                        red <= "1111";

                    when 1 =>
                        green <= "1111";

                    when 2 =>
                        blue <= "1111";

                    when others =>
                        red <= "1111";

                end case;

            end if;

            ----------------------------------------------------
            -- Star 2
            ----------------------------------------------------
            if point_in_star(
                x_count, y_count, GREEN_X, GREEN_Y
            ) then

                case color_phase is

                    when 0 =>
                        green <= "1111";

                    when 1 =>
                        blue <= "1111";

                    when 2 =>
                        red <= "1111";

                    when others =>
                        green <= "1111";

                end case;

            end if;

            ----------------------------------------------------
            -- Star 3
            ----------------------------------------------------
            if point_in_star(
                x_count, y_count, BLUE_X, BLUE_Y
            ) then

                case color_phase is

                    when 0 =>
                        blue <= "1111";

                    when 1 =>
                        red <= "1111";

                    when 2 =>
                        green <= "1111";

                    when others =>
                        blue <= "1111";

                end case;

            end if;

        end if;

    end process;

end Behavioral;
