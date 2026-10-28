
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vga_640x480 is
    Port (
        clk   : in  STD_LOGIC;
        rst   : in  STD_LOGIC;
        hsync : out STD_LOGIC;
        vsync : out STD_LOGIC;
        R     : out STD_LOGIC_VECTOR(7 downto 0);
        G     : out STD_LOGIC_VECTOR(7 downto 0);
        B     : out STD_LOGIC_VECTOR(7 downto 0)
    );
end vga_640x480;

architecture Behavioral of vga_640x480 is

    -- VGA 640 x 480 時序參數
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

    -- 七顆星星的中心座標
    -- 上排：紅、綠、藍
    constant RED_X   : integer := 110;
    constant RED_Y   : integer := 100;

    constant GREEN_X : integer := 320;
    constant GREEN_Y : integer := 100;

    constant BLUE_X  : integer := 530;
    constant BLUE_Y  : integer := 100;

    -- 下排：黃、青、洋紅
    constant YELLOW_X : integer := 110;
    constant YELLOW_Y : integer := 350;

    constant CYAN_X : integer := 320;
    constant CYAN_Y : integer := 350;

    constant MAG_X : integer := 530;
    constant MAG_Y : integer := 350;

    -- 中央：白色
    constant WHITE_X : integer := 320;
    constant WHITE_Y : integer := 225;

    -- 五角星頂點座標陣列
    type point_array is array (0 to 9) of integer;

    -- 相對中心點的 X 座標
    constant star_x : point_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    -- 相對中心點的 Y 座標
    constant star_y : point_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);

    signal div_count  : integer range 0 to 3 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    signal h_count : integer range 0 to 799 := 0;
    signal v_count : integer range 0 to 524 := 0;

    signal video_on : STD_LOGIC;

    -- 判斷像素是否位於五角星內
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
        -- 將畫面座標轉成星星的相對座標
        local_x := px - cx;
        local_y := py - cy;

        inside := false;
        j := 9;

        -- 使用射線交點法判斷是否在多邊形內
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

    -- 像素更新時機：每 4 個系統時脈週期一次
    pixel_tick <= '1' when div_count = 3 else '0';

    -- 時脈分頻計數器
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

    -- 水平與垂直掃描計數器
    process(clk, rst)
    begin
        if rst = '1' then
            h_count <= 0;
            v_count <= 0;

        elsif rising_edge(clk) then
            if pixel_tick = '1' then

                -- 水平掃描到最後一個位置
                if h_count = H_TOTAL - 1 then
                    h_count <= 0;

                    -- 完成一行，垂直位置加一
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

    -- 判斷是否位於有效顯示區域
    video_on <= '1'
        when h_count < H_DISPLAY and v_count < V_DISPLAY
        else '0';

    -- 水平同步訊號
    hsync <= '0'
        when h_count >= 656 and h_count < 752
        else '1';

    -- 垂直同步訊號
    vsync <= '0'
        when v_count >= 490 and v_count < 492
        else '1';

    -- RGB 顯示邏輯
    process(h_count, v_count, video_on)
    begin
        -- 預設為黑色
        R <= "00000000";
        G <= "00000000";
        B <= "00000000";

        if video_on = '1' then

            -- 紅色星星：上排左側
            if point_in_star(
                h_count, v_count, RED_X, RED_Y
            ) then
                R <= "11111111";
                G <= "00000000";
                B <= "00000000";

            -- 綠色星星：上排中央
            elsif point_in_star(
                h_count, v_count, GREEN_X, GREEN_Y
            ) then
                R <= "00000000";
                G <= "11111111";
                B <= "00000000";

            -- 藍色星星：上排右側
            elsif point_in_star(
                h_count, v_count, BLUE_X, BLUE_Y
            ) then
                R <= "00000000";
                G <= "00000000";
                B <= "11111111";

            -- 黃色星星：下排左側
            elsif point_in_star(
                h_count, v_count, YELLOW_X, YELLOW_Y
            ) then
                R <= "11111111";
                G <= "11111111";
                B <= "00000000";

            -- 青色星星：下排中央
            elsif point_in_star(
                h_count, v_count, CYAN_X, CYAN_Y
            ) then
                R <= "00000000";
                G <= "11111111";
                B <= "11111111";

            -- 洋紅色星星：下排右側
            elsif point_in_star(
                h_count, v_count, MAG_X, MAG_Y
            ) then
                R <= "11111111";
                G <= "00000000";
                B <= "11111111";

            -- 白色星星：畫面中央
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
