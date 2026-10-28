library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library STD;
use STD.TEXTIO.ALL;
use STD.ENV.ALL;

entity vga_1280x720_tb is
end vga_1280x720_tb;

architecture Behavioral of vga_1280x720_tb is

    -- 1280 x 720 VGA
    constant H_DISPLAY : integer := 1280;
    constant H_TOTAL   : integer := 1650;

    constant V_DISPLAY : integer := 720;
    constant V_TOTAL   : integer := 750;

    -- 74.25 MHz pixel clock
    constant CLK_PERIOD : time := 13.468 ns;

    signal clk   : STD_LOGIC := '0';
    signal rst   : STD_LOGIC := '1';

    signal hsync : STD_LOGIC;
    signal vsync : STD_LOGIC;

    signal R : STD_LOGIC_VECTOR(7 downto 0);
    signal G : STD_LOGIC_VECTOR(7 downto 0);
    signal B : STD_LOGIC_VECTOR(7 downto 0);

begin

    --------------------------------------------------
    -- Device Under Test
    --------------------------------------------------
    UUT : entity work.vga_1280x720
        port map (
            clk   => clk,
            rst   => rst,
            hsync => hsync,
            vsync => vsync,
            R     => R,
            G     => G,
            B     => B
        );

    --------------------------------------------------
    -- Clock generation
    --------------------------------------------------
    clock_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    --------------------------------------------------
    -- Reset
    --------------------------------------------------
    reset_process : process
    begin
        rst <= '1';
        wait for 100 ns;

        rst <= '0';
        wait;
    end process;

    --------------------------------------------------
    -- Generate rgb.txt
    --------------------------------------------------
    rgb_file_process : process(clk, rst)

        file rgb_file : text
            open write_mode is "rgb.txt";

        variable rgb_line : line;

        variable pixel_x : integer range 0 to H_TOTAL - 1 := 0;
        variable pixel_y : integer range 0 to V_TOTAL - 1 := 0;

        variable rgb_value : integer range 0 to 16777215;

    begin

        if rst = '1' then
            pixel_x := 0;
            pixel_y := 0;

        elsif rising_edge(clk) then

            -- Sample RGB for the current pixel coordinate.
            -- The DUT's counter and RGB signals are aligned
            -- with these testbench coordinates.
            if pixel_x < H_DISPLAY and
               pixel_y < V_DISPLAY then

                -- Combine R, G, B into a 24-bit integer.
                rgb_value :=
                    to_integer(unsigned(R)) * 65536 +
                    to_integer(unsigned(G)) * 256 +
                    to_integer(unsigned(B));

                -- Write the decimal RGB value.
                write(rgb_line, rgb_value);

                -- Separate pixels with commas.
                if pixel_x < H_DISPLAY - 1 then
                    write(rgb_line, string'(","));
                end if;

                -- End each active display row.
                if pixel_x = H_DISPLAY - 1 then
                    writeline(rgb_file, rgb_line);
                end if;

            end if;

            -- Advance the testbench pixel coordinates.
            if pixel_x = H_TOTAL - 1 then
                pixel_x := 0;

                if pixel_y = V_TOTAL - 1 then
                    pixel_y := 0;
                else
                    pixel_y := pixel_y + 1;
                end if;

            else
                pixel_x := pixel_x + 1;
            end if;

            -- Stop after the last visible pixel.
            if pixel_x = 0 and pixel_y = 0 then
                report "rgb.txt generation completed."
                    severity note;
                stop;
            end if;

        end if;

    end process;

end Behavioral;
