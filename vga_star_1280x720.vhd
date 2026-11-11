
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
    -- 1. VGA 1280 x 720 Timing
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
    -- 2. Star Positions
    ----------------------------------------------------------------

    constant RED_X   : integer := 320;
    constant RED_Y   : integer := 360;

    constant GREEN_X : integer := 640;
    constant GREEN_Y : integer := 360;

    constant BLUE_X  : integer := 960;
    constant BLUE_Y  : integer := 360;


    ----------------------------------------------------------------
    -- 3. Star Shape
    ----------------------------------------------------------------

    type int_array is array (0 to 9) of integer;

    constant STAR_X : int_array :=
        (0, 18, 62, 28, 38, 0, -38, -28, -62, -18);

    constant STAR_Y : int_array :=
        (-60, -18, -16, 10, 55, 32, 55, 10, -16, -18);


    ----------------------------------------------------------------
    -- 4. Animation Parameters
    ----------------------------------------------------------------

    constant BRIGHTNESS_MAX : integer := 15;

    -- æ˜Žé¡¯ä¿�ç•™é¤˜å…‰
    constant AFTERGLOW : integer := 4;

    -- è¿½é€�æ³¢æµªï¼šæ¯�é¡†æ˜Ÿæ˜Ÿ 30 frames
    constant CHASE_EACH : integer := 30;
    constant CHASE_FRAMES : integer := CHASE_EACH * 3;

    -- å…¨éƒ¨äº®èµ·å¾Œå�œç•™
    constant HOLD_FRAMES : integer := 30;

    -- å�Œæ­¥å‘¼å�¸
    constant BREATH_FRAMES : integer := 120;

    -- æ˜Ÿå…‰é–ƒè€€
    constant SPARKLE_FRAMES : integer := 120;

    -- å®Œæ•´å‹•ç•«å¾ªç’°
    constant TOTAL_FRAMES : integer :=
        CHASE_FRAMES +
        HOLD_FRAMES +
        BREATH_FRAMES +
        SPARKLE_FRAMES;
        -- 90 + 30 + 120 + 120 = 360


    ----------------------------------------------------------------
    -- 5. VGA Signals
    ----------------------------------------------------------------

    signal h_count : integer range 0 to H_TOTAL - 1 := 0;
    signal v_count : integer range 0 to V_TOTAL - 1 := 0;

    signal pixel_acc  : integer range 0 to 9999 := 0;
    signal pixel_tick : STD_LOGIC := '0';

    signal frame_tick : STD_LOGIC := '0';


    ----------------------------------------------------------------
    -- 6. Animation Signals
    ----------------------------------------------------------------

    signal anim_frame :
        integer range 0 to TOTAL_FRAMES - 1 := 0;

    signal red_level :
        integer range 0 to 15 := 0;

    signal green_level :
        integer range 0 to 15 := 0;

    signal blue_level :
        integer range 0 to 15 := 0;


    ----------------------------------------------------------------
    -- 7. Function: Check Whether Pixel Is Inside Star
    ----------------------------------------------------------------

    function point_in_star(
        px : integer;
        py : integer;
        cx : integer;
        cy : integer
    ) return boolean is

        variable is_inside : boolean := false;

        variable j : integer;

        variable xi : integer;
        variable yi : integer;

        variable xj : integer;
        variable yj : integer;

        variable lhs : integer;
        variable rhs : integer;

    begin

        for i in 0 to 9 loop

            j := (i + 1) mod 10;

            xi := cx + STAR_X(i);
            yi := cy + STAR_Y(i);

            xj := cx + STAR_X(j);
            yj := cy + STAR_Y(j);

            if ((yi > py) /= (yj > py)) then

                lhs := (px - xi) * (yj - yi);
                rhs := (py - yi) * (xj - xi);

                if yj > yi then

                    if lhs < rhs then
                        is_inside := not is_inside;
                    end if;

                else

                    if lhs > rhs then
                        is_inside := not is_inside;
                    end if;

                end if;

            end if;

        end loop;

        return is_inside;

    end function;


begin

    ----------------------------------------------------------------
    -- 8. Pixel Clock Enable
    -- Input Clock : 100 MHz
    -- Pixel Rate  : Average 74.25 MHz
    ----------------------------------------------------------------

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


    ----------------------------------------------------------------
    -- 9. VGA Horizontal and Vertical Counters
    ----------------------------------------------------------------

    VGA_COUNTER : process(clk, rst)

    begin

        if rst = '1' then

            h_count <= 0;
            v_count <= 0;

            frame_tick <= '0';

        elsif rising_edge(clk) then

            frame_tick <= '0';

            if pixel_tick = '1' then

                if h_count = H_TOTAL - 1 then

                    h_count <= 0;

                    if v_count = V_TOTAL - 1 then

                        v_count <= 0;
                        frame_tick <= '1';

                    else

                        v_count <= v_count + 1;

                    end if;

                else

                    h_count <= h_count + 1;

                end if;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- 10. VGA Synchronization Signals
    ----------------------------------------------------------------

    hsync <= '0'
        when (h_count >= H_DISPLAY + H_FRONT and
              h_count < H_DISPLAY + H_FRONT + H_SYNC)
        else '1';

    vsync <= '0'
        when (v_count >= V_DISPLAY + V_FRONT and
              v_count < V_DISPLAY + V_FRONT + V_SYNC)
        else '1';


    ----------------------------------------------------------------
    -- 11. Animation Frame Counter
    -- One complete cycle = 360 frames
    ----------------------------------------------------------------

    ANIMATION_COUNTER : process(clk, rst)

    begin

        if rst = '1' then

            anim_frame <= 0;

        elsif rising_edge(clk) then

            if frame_tick = '1' then

                if anim_frame = TOTAL_FRAMES - 1 then

                    anim_frame <= 0;

                else

                    anim_frame <= anim_frame + 1;

                end if;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- 12. RGB Animation Controller
    ----------------------------------------------------------------

    RGB_ANIMATION : process(anim_frame)

        variable p : integer;
        variable step_count : integer;

        variable r_temp : integer;
        variable g_temp : integer;
        variable b_temp : integer;

        variable breath_level : integer;

        variable sparkle_slot : integer;
        variable sparkle_pos : integer;
        variable sparkle_level : integer;

    begin

        r_temp := 0;
        g_temp := 0;
        b_temp := 0;

        p := 0;
        step_count := 0;

        breath_level := 0;

        sparkle_slot := 0;
        sparkle_pos := 0;
        sparkle_level := AFTERGLOW;


        ------------------------------------------------------------
        -- Stage 1: Chasing Wave
        -- Red -> Green -> Blue
        -- Frame 0 ~ 89
        ------------------------------------------------------------

        if anim_frame < CHASE_FRAMES then

            --------------------------------------------------------
            -- First Star: Red
            --------------------------------------------------------

            if anim_frame < CHASE_EACH then

                r_temp :=
                    (anim_frame + 1)
                    * BRIGHTNESS_MAX / CHASE_EACH;


            --------------------------------------------------------
            -- Second Star: Green
            -- Red fades to afterglow
            --------------------------------------------------------

            elsif anim_frame < CHASE_EACH * 2 then

                step_count := anim_frame - CHASE_EACH;

                r_temp :=
                    BRIGHTNESS_MAX -
                    ((BRIGHTNESS_MAX - AFTERGLOW)
                    * (step_count + 1) / CHASE_EACH);

                g_temp :=
                    (step_count + 1)
                    * BRIGHTNESS_MAX / CHASE_EACH;


            --------------------------------------------------------
            -- Third Star: Blue
            -- Green fades to afterglow
            --------------------------------------------------------

            else

                step_count := anim_frame - CHASE_EACH * 2;

                r_temp := AFTERGLOW;

                g_temp :=
                    BRIGHTNESS_MAX -
                    ((BRIGHTNESS_MAX - AFTERGLOW)
                    * (step_count + 1) / CHASE_EACH);

                b_temp :=
                    (step_count + 1)
                    * BRIGHTNESS_MAX / CHASE_EACH;

            end if;


        ------------------------------------------------------------
        -- Stage 2: All Stars Hold
        -- Frame 90 ~ 119
        ------------------------------------------------------------

        elsif anim_frame <
              CHASE_FRAMES + HOLD_FRAMES then

            p := anim_frame - CHASE_FRAMES;

            -- Red and Green gradually brighten
            r_temp :=
                AFTERGLOW +
                (12 - AFTERGLOW) * p / (HOLD_FRAMES - 1);

            g_temp :=
                AFTERGLOW +
                (12 - AFTERGLOW) * p / (HOLD_FRAMES - 1);

            -- Blue gradually adjusts to the same brightness
            b_temp :=
                BRIGHTNESS_MAX -
                (BRIGHTNESS_MAX - 12) * p / (HOLD_FRAMES - 1);


        ------------------------------------------------------------
        -- Stage 3: Synchronous Breathing
        -- Frame 120 ~ 239
        ------------------------------------------------------------

        elsif anim_frame <
              CHASE_FRAMES + HOLD_FRAMES + BREATH_FRAMES then

            p := anim_frame - CHASE_FRAMES - HOLD_FRAMES;

            if p < 60 then

                -- Gradually brighten
                breath_level :=
                    5 + p * 7 / 59;

            else

                -- Gradually dim
                breath_level :=
                    12 - (p - 60) * 7 / 59;

            end if;

            r_temp := breath_level;
            g_temp := breath_level;
            b_temp := breath_level;


        ------------------------------------------------------------
        -- Stage 4: Sparkle
        -- Frame 240 ~ 359
        ------------------------------------------------------------

        else

            p :=
                anim_frame -
                CHASE_FRAMES -
                HOLD_FRAMES -
                BREATH_FRAMES;

            -- Six sparkle intervals, 20 frames each
            sparkle_slot := p / 20;
            sparkle_pos := p mod 20;

            -- All stars retain a soft glow
            r_temp := AFTERGLOW;
            g_temp := AFTERGLOW;
            b_temp := AFTERGLOW;

            -- Gradually brighten and dim the selected star
            if sparkle_pos < 10 then

                sparkle_level :=
                    AFTERGLOW +
                    sparkle_pos * (BRIGHTNESS_MAX - AFTERGLOW) / 9;

            else

                sparkle_level :=
                    BRIGHTNESS_MAX -
                    (sparkle_pos - 10)
                    * (BRIGHTNESS_MAX - AFTERGLOW) / 9;

            end if;


            -- Repeating varied sparkle order:
            -- Red -> Blue -> Green -> Green -> Red -> Blue

            case sparkle_slot is

                when 0 | 4 =>
                    r_temp := sparkle_level;

                when 1 | 5 =>
                    b_temp := sparkle_level;

                when 2 | 3 =>
                    g_temp := sparkle_level;

                when others =>
                    null;

            end case;

        end if;


        ------------------------------------------------------------
        -- Update RGB Brightness
        ------------------------------------------------------------

        red_level   <= r_temp;
        green_level <= g_temp;
        blue_level  <= b_temp;

    end process;


    ----------------------------------------------------------------
    -- 13. RGB Output
    -- Three Fixed Stars
    ----------------------------------------------------------------

    RGB_OUTPUT : process(
        h_count,
        v_count,
        red_level,
        green_level,
        blue_level
    )

    begin

        red   <= (others => '0');
        green <= (others => '0');
        blue  <= (others => '0');


        if (h_count < H_DISPLAY) and
           (v_count < V_DISPLAY) then


            --------------------------------------------------------
            -- Red Star
            --------------------------------------------------------

            if point_in_star(
                h_count,
                v_count,
                RED_X,
                RED_Y
            ) then

                red <= std_logic_vector(
                    to_unsigned(red_level, 4)
                );

            end if;


            --------------------------------------------------------
            -- Green Star
            --------------------------------------------------------

            if point_in_star(
                h_count,
                v_count,
                GREEN_X,
                GREEN_Y
            ) then

                green <= std_logic_vector(
                    to_unsigned(green_level, 4)
                );

            end if;


            --------------------------------------------------------
            -- Blue Star
            --------------------------------------------------------

            if point_in_star(
                h_count,
                v_count,
                BLUE_X,
                BLUE_Y
            ) then

                blue <= std_logic_vector(
                    to_unsigned(blue_level, 4)
                );

            end if;

        end if;

    end process;


end Behavioral;
