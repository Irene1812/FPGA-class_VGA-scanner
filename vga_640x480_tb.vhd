library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.ENV.ALL;

entity vga_640x480_tb is
end vga_640x480_tb;

architecture Behavioral of vga_640x480_tb is

    -- 系統時脈與 Reset
    signal clk : STD_LOGIC := '0';
    signal rst : STD_LOGIC := '1';

    -- VGA 同步訊號
    signal hsync : STD_LOGIC;
    signal vsync : STD_LOGIC;

    -- 8-bit RGB，每個顏色分量範圍為 0～255
    signal R : STD_LOGIC_VECTOR(7 downto 0);
    signal G : STD_LOGIC_VECTOR(7 downto 0);
    signal B : STD_LOGIC_VECTOR(7 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    -- ========================================
    -- 1. 連接 VGA 主程式
    -- ========================================
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

    -- ========================================
    -- 2. 產生 100 MHz 時脈
    -- ========================================
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- ========================================
    -- 3. Reset 測試
    -- ========================================
    stim_process : process
    begin
        rst <= '1';
        wait for 107 ns;

        rst <= '0';
        wait;
    end process;

    -- ========================================
    -- 4. RGB 顏色驗證
    -- 使用獨立的 VGA 掃描計數器
    -- ========================================
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
                -- 模擬除以 4 的像素更新時機
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

                -- 等待主程式輸出穩定
                wait for 1 ns;

                -- --------------------------------
                -- 測試淺黃色
                -- RGB = (255, 242, 166)
                -- 測試座標：(320, 100)
                -- --------------------------------
                if tb_h = 320 and tb_v = 100 then
                    assert
                        R = "11111111" and
                        G = "11110010" and
                        B = "10100110"
                    report "ERROR: Light yellow pixel"
                    severity error;

                    if R = "11111111" and
                       G = "11110010" and
                       B = "10100110" then
                        report "Light yellow check passed"
                            severity note;
                    end if;
                end if;

                -- --------------------------------
                -- 測試淺藍色
                -- RGB = (173, 216, 230)
                -- 測試座標：(110, 350)
                -- --------------------------------
                if tb_h = 110 and tb_v = 350 then
                    assert
                        R = "10101101" and
                        G = "11011000" and
                        B = "11100110"
                    report "ERROR: Light blue pixel"
                    severity error;

                    if R = "10101101" and
                       G = "11011000" and
                       B = "11100110" then
                        report "Light blue check passed"
                            severity note;
                    end if;
                end if;

                -- --------------------------------
                -- 測試淺紫色
                -- RGB = (216, 180, 226)
                -- 測試座標：(530, 350)
                -- --------------------------------
                if tb_h = 530 and tb_v = 350 then
                    assert
                        R = "11011000" and
                        G = "10110100" and
                        B = "11100010"
                    report "ERROR: Light purple pixel"
                    severity error;

                    if R = "11011000" and
                       G = "10110100" and
                       B = "11100010" then
                        report "Light purple check passed"
                            severity note;
                    end if;

                    report "RGB checks completed"
                        severity note;

                    stop;
                    wait;
                end if;

            end if;
        end loop;
    end process;

end Behavioral;
