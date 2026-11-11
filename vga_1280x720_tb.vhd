
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity vga_star_tb is
end vga_star_tb;

architecture Behavioral of vga_star_tb is

    constant H_DISPLAY : integer := 1280;
    constant H_TOTAL   : integer := 1650;

    constant V_DISPLAY : integer := 720;
    constant V_TOTAL   : integer := 750;

    constant FRAME_COUNT : integer := 10;
    constant CLK_PERIOD  : time := 10 ns;

    constant CYCLES_PER_FRAME : integer := 1666667;

    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';

    signal hsync : STD_LOGIC;
    signal vsync : STD_LOGIC;

    signal R : STD_LOGIC_VECTOR(3 downto 0);
    signal G : STD_LOGIC_VECTOR(3 downto 0);
    signal B : STD_LOGIC_VECTOR(3 downto 0);

    -- Pixel enable
    signal pixel_enable : STD_LOGIC := '0';

    signal h_tb : integer range 0 to H_TOTAL-1 := 0;
    signal v_tb : integer range 0 to V_TOTAL-1 := 0;

    signal pixel_acc_tb : integer range 0 to 9999 := 0;

begin

    ------------------------------------------------
    -- DUT
    ------------------------------------------------

    DUT : entity work.vga_star
        port map (
            clk   => clk,
            rst   => rst,
            hsync => hsync,
            vsync => vsync,
            R     => R,
            G     => G,
            B     => B
        );

    ------------------------------------------------
    -- 100 MHz Clock
    ------------------------------------------------

    clk <= not clk after CLK_PERIOD/2;

    ------------------------------------------------
    -- Reset
    ------------------------------------------------

    process
    begin

        rst <= '1';

        wait for 100 ns;

        rst <= '0';

        wait;

    end process;

    ------------------------------------------------
    -- Pixel Enable Generator
    -- Same as DUT
    ------------------------------------------------

    process(clk, rst)
    begin

        if rst = '1' then

            pixel_acc_tb <= 0;
            pixel_enable <= '0';

        elsif rising_edge(clk) then

            if pixel_acc_tb >= 2575 then

                pixel_acc_tb <= pixel_acc_tb - 2575;
                pixel_enable <= '1';

            else

                pixel_acc_tb <= pixel_acc_tb + 7425;
                pixel_enable <= '0';

            end if;

        end if;

    end process;

    ------------------------------------------------
    -- RGB Recording
    ------------------------------------------------

    process

        file RGB_FILE : text open write_mode
                        is "rgb.txt";

        variable RGB_LINE : line;

        variable rgb_value : integer;

        -- 8-bit RGB values
        variable R8 : integer;
        variable G8 : integer;
        variable B8 : integer;

    begin

        wait until rst = '0';

        wait until rising_edge(clk);

        wait for 1 ns;

        for frame in 0 to FRAME_COUNT-1 loop

            h_tb <= 0;
            v_tb <= 0;

            for pixel in 0 to CYCLES_PER_FRAME-1 loop

                wait until rising_edge(clk);

                wait for 1 ns;

                if pixel_enable = '1' then

                    -- Active display area
                    if h_tb < H_DISPLAY and
                       v_tb < V_DISPLAY then

                        --------------------------------
                        -- Convert 4-bit RGB to 8-bit RGB
                        --------------------------------

                        R8 :=
                            to_integer(unsigned(R)) * 17;

                        G8 :=
                            to_integer(unsigned(G)) * 17;

                        B8 :=
                            to_integer(unsigned(B)) * 17;

                        --------------------------------
                        -- Convert RGB to decimal integer
                        --------------------------------

                        rgb_value :=
                            R8 * 65536 +
                            G8 * 256 +
                            B8;

                        --------------------------------
                        -- Write RGB pixel
                        --------------------------------

                        if h_tb > 0 then
                            write(RGB_LINE, string'(","));
                        end if;

                        write(RGB_LINE, rgb_value);

                        --------------------------------
                        -- End of active display line
                        --------------------------------

                        if h_tb = H_DISPLAY-1 then

                            writeline(RGB_FILE, RGB_LINE);

                        end if;

                    end if;

                    --------------------------------
                    -- Horizontal Counter
                    --------------------------------

                    if h_tb = H_TOTAL-1 then

                        h_tb <= 0;

                        if v_tb = V_TOTAL-1 then

                            v_tb <= 0;

                        else

                            v_tb <= v_tb + 1;

                        end if;

                    else

                        h_tb <= h_tb + 1;

                    end if;

                end if;

            end loop;

            --------------------------------
            -- Blank line separates frames
            --------------------------------

            writeline(RGB_FILE, RGB_LINE);

            report "Frame " &
                   integer'image(frame+1) &
                   " completed";

        end loop;

        report "RGB recording completed";

        wait;

    end process;

end Behavioral;
