# VGA Scanner Star Color Exchange Animation

https://github.com/user-attachments/assets/8bfb72e4-10cb-48dd-845a-a88287f0059a

<img width="1470" height="270" alt="1" src="https://github.com/user-attachments/assets/506d21e0-20c3-420c-a2f1-2760f9b9034a" />
<img width="1470" height="230" alt="2" src="https://github.com/user-attachments/assets/1a1f2110-ffbe-4197-8c3e-5208ea78a152" />
<img width="1470" height="848" alt="3" src="https://github.com/user-attachments/assets/a40b9563-4fd3-442f-9fed-6a9dbb9fda5d" />
<img width="1470" height="337" alt="4" src="https://github.com/user-attachments/assets/1da2e255-df33-4c6c-9065-5111ca4e9c6b" />


## 星形幾何與射線判斷圖

- 使用十個頂點定義星星的幾何形狀。
- 使用 Ray Casting Algorithm 判斷像素是否位於星星內部。
- 透過奇數與偶數交點規則區分 Inside 和 Outside。
- 使用 Boolean 回傳值控制後續 RGB 顏色輸出。

```
variable inside : boolean := false;
variable j      : integer := 9;

variable xi : integer;
variable yi : integer;
variable xj : integer;
variable yj : integer;

begin
    -- Check all 10 vertices using the ray casting algorithm
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
```

### 1. 星形幾何定義
使用十個頂點（10 Vertices）定義五角星的幾何形狀，透過連接十個頂點形成封閉的多邊形（Polygon）。星星的幾何形狀由 STAR_X 和 STAR_Y 兩組座標陣列定義：

<img width="663" height="667" alt="desmos-graph" src="https://github.com/user-attachments/assets/ff36f2ec-a32b-4264-88ed-3c640f1e0fab" />

座標計算：
星星實際頂點位置是由中心座標加上相對座標計算而得：
    X_i=C_x+STAR\_X(i)
    Y_i=C_y+STAR\_Y(i)

例如，第一顆星星的中心座標為 (320, 360)，其 P0 頂點為：
    X_0=320+0=320
    Y_0=360-60=300
因此，P0 的實際座標為 (320, 300)。

### 2. 射線交點演算法
判斷目前 VGA 掃描的像素是否位於星形多邊形內部。
VGA 會依照水平及垂直掃描座標，逐一取得目前像素位置 (x_count, y_count)，並將該座標傳入 point_in_star() 函數進行判斷。

射線判斷示意圖:
<img width="1008" height="637" alt="image" src="https://github.com/user-attachments/assets/d0255b67-082c-40b5-850d-3e556ecaecb3" />
   Intersection Count	  Result	  Description
1. 奇數 (1, 3, 5...)	    Inside	  像素位於多邊形內部
2. 偶數 (0, 2, 4...)	  Outside  	像素位於多邊形外部
*如果測試點在星星內部，往外移動時必須穿過奇數次邊界才能離開。
*如果測試點在星星外部，往右移動時穿過的邊界次數會是偶數。

判斷結果	         意義	             RGB 輸出
inside = true	   射線交點數為奇數	 顯示星星顏色
inside = false	 射線交點數為偶數	 顯示黑色背景
