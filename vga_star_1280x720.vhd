----------------------------------------------------------------------------------
-- 專題名稱：VGA 1280x720 動態彩色星星顯示系統 (vga_star.vhd)
-- 說明：本程式負責產生 720p 螢幕所需的時序、掃描座標、三顆星星的幾何形狀判斷，
--       以及每隔固定幀數（Frames）自動循環交換紅、綠、藍三色的動畫邏輯。
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- 【Entity（實體介面宣告）】
-- 定義這顆晶片對外的所有實體接腳（Inputs / Outputs）
entity vga_star is
    Port (
        clk   : in  STD_LOGIC;                      -- 系統主時脈（通常為 100MHz）
        rst   : in  STD_LOGIC;                      -- 重置按鈕（高電位時將系統歸零）

        hsync : out STD_LOGIC;                      -- 水平同步訊號（通知螢幕換行）
        vsync : out STD_LOGIC;                      -- 垂直同步訊號（通知螢幕換頁/重回頂端）

        red   : out STD_LOGIC_VECTOR(3 downto 0);   -- 紅色色階輸出（4位元，共16階）
        green : out STD_LOGIC_VECTOR(3 downto 0);   -- 綠色色階輸出（4位元）
        blue  : out STD_LOGIC_VECTOR(3 downto 0)    -- 藍色色階輸出（4位元）
    );
end vga_star;

architecture Behavioral of vga_star is

    ------------------------------------------------------------
    -- 【VGA 1280x720 @ 60Hz 標準時序規格常數】
    -- 包含實際顯示區與電子束折返掃描的隱形區（Front/Back Porch 與 Sync）
    ------------------------------------------------------------
    constant H_DISPLAY : integer := 1280;   -- 水平有效顯示像素寬度
    constant H_FRONT   : integer := 110;    -- 水平前肩區
    constant H_SYNC    : integer := 40;     -- 水平同步脈衝寬度
    constant H_BACK    : integer := 220;    -- 水平後肩區
    constant H_TOTAL   : integer := 1650;   -- 水平總像素數（含折返）

    constant V_DISPLAY : integer := 720;    -- 垂直有效顯示掃描線高度
    constant V_FRONT   : integer := 5;      -- 垂直前肩區
    constant V_SYNC    : integer := 5;      -- 垂直同步脈衝寬度
    constant V_BACK    : integer := 20;     -- 垂直後肩區
    constant V_TOTAL   : integer := 750;    -- 垂直總掃描線數（含折返）

    ------------------------------------------------------------
    -- 【星星顏色動態交換參數】
    ------------------------------------------------------------
    constant COLOR_CHANGE_FRAMES : integer := 60;   -- 每經過 60 幀（約 1 秒）切換一次顏色

    signal color_frame_counter : 
        integer range 0 to COLOR_CHANGE_FRAMES-1 := 0;  -- 幀數累積計數器

    signal color_phase : 
        integer range 0 to 2 := 0;                  -- 色彩循環階段狀態（0、1、2）

    ------------------------------------------------------------
    -- 【星星幾何形狀定義】
    -- 以中心點 (0,0) 為基準的 10 個多邊形頂點相對座標陣列
    ------------------------------------------------------------
    type star_array is array (0 to 9) of integer;

    constant STAR_X : star_array := 
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant STAR_Y : star_array := 
        =(-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);

    ------------------------------------------------------------
    -- 【VGA 掃描座標與時脈分頻內部信號】
    ------------------------------------------------------------
    signal x_count : integer range 0 to H_TOTAL-1 := 0;   -- 當前水平像素掃描座標
    signal y_count : integer range 0 to V_TOTAL-1 := 0;   -- 當前垂直掃描線座標

    signal pixel_acc  : integer range 0 to 9999 := 0;     -- 像素時脈分頻累積器
    signal pixel_tick : STD_LOGIC := '0';                 -- 像素時脈致能脈衝（每畫一個像素脈衝一次）

    ------------------------------------------------------------
    -- 【三顆固定星星的中心座標】
    ------------------------------------------------------------
    constant RED_X   : integer := 320;    -- 第一顆星 X 軸中心（靠左）
    constant RED_Y   : integer := 360;    -- 第一顆星 Y 軸中心（垂直置中）

    constant GREEN_X : integer := 640;    -- 第二顆星 X 軸中心（正中央）
    constant GREEN_Y : integer := 360;    -- 第二顆星 Y 軸中心

    constant BLUE_X  : integer := 960;    -- 第三顆星 X 軸中心（靠右）
    constant BLUE_Y  : integer := 360;    -- 第三顆星 Y 軸中心

    ------------------------------------------------------------
    -- 【射線交點演算法函數：判斷點 (px, py) 是否在星星內部】
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
        -- 走訪 10 個頂點，利用射線相交原理（Ray Casting Algorithm）判斷像素點是否落入多邊形內
        for i in 0 to 9 loop
            xi := cx + STAR_X(i);
            yi := cy + STAR_Y(i);
            xj := cx + STAR_X(j);
            yj := cy + STAR_Y(j);

            if ((yi > py) /= (yj > py)) then
                if px < (xj - xi) * (py - yi) / (yj - yi) + xi then
                    inside := not inside;
                end if;
            end if;
            j := i;
        end loop;

        return inside;
    end function;

begin

    ------------------------------------------------------------
    -- 【Process 1: 像素時脈分頻處理 (Pixel Clock Enable)】
    -- 將 100MHz 系統時脈降頻模擬出 720p 所需的 74.25MHz 像素時脈
    ------------------------------------------------------------
    PIXEL_CLOCK : process(clk, rst)
    begin
        if rst = '1' then
            pixel_acc  <= 0;
            pixel_tick <= '0';
        elsif rising_edge(clk) then
            if pixel_acc >= 2575 then
                pixel_acc  <= pixel_acc - 2575;
                pixel_tick <= '1';  -- 產生一個像素步進脈衝
            else
                pixel_acc  <= pixel_acc + 7425;
                pixel_tick <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- 【Process 2: 雙層掃描座標計數器 (VGA Counters)】
    -- 模擬傳統電視與螢幕電子束「由左至右、由上往下」的掃描軌跡
    ------------------------------------------------------------
    VGA_COUNTER : process(clk, rst)
    begin
        if rst = '1' then
            x_count <= 0;
            y_count <= 0;
        elsif rising_edge(clk) then
            if pixel_tick = '1' then
                if x_count = H_TOTAL - 1 then
                    x_count <= 0;  -- 水平一行掃描完畢，歸零並換行
                    
                    if y_count = V_TOTAL - 1 then
                        y_count <= 0;  -- 垂直一整頁掃描完畢，歸零重回畫面左上角
                    else
                        y_count <= y_count + 1;  -- 往下移動一行
                    end if;
                else
                    x_count <= x_count + 1;  -- 往右移動一個像素
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- 【Process 3: 同步訊號產生器 (VGA Synchronization Signals)】
    -- 當計數器走到規格書規定的 Sync 區間時，拉低 hsync/vsync 脈衝
    ------------------------------------------------------------
    SYNC_SIGNAL : process(x_count, y_count)
    begin
        -- 控制水平同步脈衝
        if (x_count >= H_DISPLAY + H_FRONT) and 
           (x_count < H_DISPLAY + H_FRONT + H_SYNC) then
            hsync <= '0';
        else
            hsync <= '1';
        end if;

        -- 控制垂直同步脈衝
        if (y_count >= V_DISPLAY + V_FRONT) and 
           (y_count < V_DISPLAY + V_FRONT + V_SYNC) then
            vsync <= '0';
        else
            vsync <= '1';
        end if;
    end process;

    ------------------------------------------------------------
    -- 【Process 4: 星星顏色循環計時器 (Color Exchange)】
    -- 每一幀畫面結束時進行一次幀數累積，滿 60 幀（約 0.5~1秒）就切換一次色相狀態
    ------------------------------------------------------------
    COLOR_CHANGE : process(clk, rst)
    begin
        if rst = '1' then
            color_frame_counter <= 0;
            color_phase <= 0;
        elsif rising_edge(clk) then
            -- 檢查是否為畫面上的最後一個像素（代表一整幀畫完）
            if pixel_tick = '1' and x_count = H_TOTAL - 1 and y_count = V_TOTAL - 1 then
                if color_frame_counter = COLOR_CHANGE_FRAMES - 1 then
                    color_frame_counter <= 0;
                    
                    -- 色彩階段在 0、1、2 之間循環切換
                    if color_phase = 2 then
                        color_phase <= 0;
                    else
                        color_phase <= color_phase + 1;
                    end if;
                else
                    color_frame_counter <= color_frame_counter + 1;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------
    -- 【Process 5: 畫面像素著色與消隱保護 (RGB Output)】
    -- 組合邏輯：先確保在有效 1280x720 範圍內，再判斷座標是否落在星星內，並依據 color_phase 填入顏色
    ------------------------------------------------------------
    RGB_OUTPUT : process(x_count, y_count, color_phase)
    begin
        -- 預設背景為黑色（消隱區與背景色）
        red   <= "0000";
        green <= "0000";
        blue  <= "0000";

        -- 僅在有效顯示區（1280x720）內進行繪圖，超出範圍自動進入消隱保護（輸出全黑）
        if x_count < H_DISPLAY and y_count < V_DISPLAY then

            ----------------------------------------------------
            -- 【第一顆星（左側 320, 360）色彩對應】
            ----------------------------------------------------
            if point_in_star(x_count, y_count, RED_X, RED_Y) then
                case color_phase is
                    when 0      => red   <= "1111";  -- 階段 0：顯示紅色
                    when 1      => green <= "1111";  -- 階段 1：顯示綠色
                    when 2      => blue  <= "1111";  -- 階段 2：顯示藍色
                    when others => red   <= "1111";
                end case;
            end if;

            ----------------------------------------------------
            -- 【第二顆星（中間 640, 360）色彩對應】
            ----------------------------------------------------
            if point_in_star(x_count, y_count, GREEN_X, GREEN_Y) then
                case color_phase is
                    when 0      => green <= "1111";  -- 階段 0：顯示綠色
                    when 1      => blue  <= "1111";  -- 階段 1：顯示藍色
                    when 2      => red   <= "1111";  -- 階段 2：顯示紅色
                    when others => green <= "1111";
                end case;
            end if;

            ----------------------------------------------------
            -- 【第三顆星（右側 960, 360）色彩對應】
            ----------------------------------------------------
            if point_in_star(x_count, y_count, BLUE_X, BLUE_Y) then
                case color_phase is
                    when 0      => blue  <= "1111";  -- 階段 0：顯示藍色
                    when 1      => red   <= "1111";  -- 階段 1：顯示紅色
                    when 2      => green <= "1111";  -- 階段 2：顯示綠色
                    when others => blue  <= "1111";
                end case;
            end if;

        end if;
    end process;

end Behavioral;
