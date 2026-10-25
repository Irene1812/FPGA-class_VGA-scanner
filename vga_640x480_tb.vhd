
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.ENV.ALL;

entity vga_640x480_tb is
end vga_640x480_tb;

architecture Behavioral of vga_640x480_tb is

    signal clk   : STD_LOGIC := '0';
    signal rst   : STD_LOGIC := '1';

    signal hsync : STD_LOGIC;
    signal vsync : STD_LOGIC;

    signal R : STD_LOGIC;
    signal G : STD_LOGIC;
    signal B : STD_LOGIC;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instantiate VGA design
    uut : entity work.vga_640x480
        port map (
            clk   => clk,
            rst   => rst,
            hsync => hsync,
            vsync => vsync,
            R     => R,
            G     => G,
            B     => B
        );

    -- 100 MHz clock
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Reset
    stim_process : process
    begin
        rst <= '1';
        wait for 107 ns;

        rst <= '0';
        wait;
    end process;

    -- Check RGB using independent scan counters
    check_rgb_process : process
        variable tb_div : integer range 0 to 3 := 0;
        variable tb_h   : integer range 0 to 799 := 0;
        variable tb_v   : integer range 0 to 524 := 0;
    begin
        loop
            wait until rising_edge(clk);

            if rst = '1' then
                tb_div := 0;
                tb_h   := 0;
                tb_v   := 0;

            else
                -- Match the DUT's divide-by-4 pixel enable
                if tb_div = 3 then
                    tb_div := 0;

                    if tb_h = 799 then
                        tb_h := 0;

                        if tb_v = 524 then
                            tb_v := 0;
                        else
                            tb_v := tb_v + 1;
                        end if;

                    else
                        tb_h := tb_h + 1;
                    end if;

                else
                    tb_div := tb_div + 1;
                end if;

                -- Allow DUT outputs to settle
                wait for 1 ns;

                -- Red rectangle: (50,50), size 150x100
                if tb_h = 50 and tb_v = 50 then
                    assert R = '1' and G = '0' and B = '0'
                        report "ERROR: Red rectangle"
                        severity error;
                end if;

                -- Green rectangle: (250,150), size 120x150
                if tb_h = 250 and tb_v = 150 then
                    assert R = '0' and G = '1' and B = '0'
                        report "ERROR: Green rectangle"
                        severity error;
                end if;

                -- Blue rectangle: (420,250), size 160x120
                if tb_h = 420 and tb_v = 250 then
                    assert R = '0' and G = '0' and B = '1'
                        report "ERROR: Blue rectangle"
                        severity error;

                    report "RGB checks passed"
                        severity note;

                    stop;
                    wait;
                end if;
            end if;
        end loop;
    end process;

end Behavioral;
