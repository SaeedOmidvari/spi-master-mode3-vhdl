----------------------------------------------------------------------------------
-- Company:         Univ. Bremerhaven
-- Engineer:        Saeed Omidvari
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sph1pol1 is
end entity;

architecture sim of tb_sph1pol1 is
  constant USPI_SIZE : integer := 16;

  signal resetn   : std_logic := '0';
  signal bclk     : std_logic := '0';
  signal spi_clkp : std_logic := '0';
  signal start    : std_logic := '0';
  signal done     : std_logic;

  signal scsq     : std_logic;
  signal sclk     : std_logic;
  signal sdo      : std_logic;
  signal sdi      : std_logic := '0';

  signal sndData  : std_logic_vector(USPI_SIZE-1 downto 0) := (others => '0');
  signal rcvData  : std_logic_vector(USPI_SIZE-1 downto 0);

  constant SLV_PAT : std_logic_vector(USPI_SIZE-1 downto 0) := x"A5A5";
  signal slave_shift : std_logic_vector(USPI_SIZE-1 downto 0) := SLV_PAT;

  function slv_to_hex(slv : std_logic_vector) return string is
    constant HEX : string := "0123456789ABCDEF";
    variable tmp : std_logic_vector(slv'length-1 downto 0) := slv;
    variable res : string(1 to (slv'length+3)/4);
    variable nib : std_logic_vector(3 downto 0);
    variable idx : integer;
    variable pad_len : integer;
  begin
    pad_len := (4 - (tmp'length mod 4)) mod 4;
    if pad_len /= 0 then
      tmp := (pad_len-1 downto 0 => '0') & tmp;
    end if;

    for i in 0 to res'length-1 loop
      idx := tmp'length-1 - i*4;
      nib := tmp(idx downto idx-3);
      res(i+1) := HEX(to_integer(unsigned(nib)) + 1);
    end loop;

    return res;
  end function;

begin
  -- DUT
  dut: entity work.sph1pol1
    generic map (USPI_SIZE => USPI_SIZE)
    port map(
      resetn   => resetn,
      bclk     => bclk,
      spi_clkp => spi_clkp,
      start    => start,
      done     => done,
      scsq     => scsq,
      sclk     => sclk,
      sdo      => sdo,
      sdi      => sdi,
      sndData  => sndData,
      rcvData  => rcvData
    );

  bclk <= not bclk after 5 ns;

  tick_gen : process
    constant DIV : integer := 10; -- adjust SPI speed here
    variable cnt : integer := 0;
  begin
    wait until rising_edge(bclk);

    if cnt = DIV-1 then
      spi_clkp <= '1';
      cnt := 0;
    else
      spi_clkp <= '0';
      cnt := cnt + 1;
    end if;
  end process;


  slave_model : process
    variable sh : std_logic_vector(USPI_SIZE-1 downto 0) := SLV_PAT;
  begin
    wait until (scsq'event) or (sclk'event);

    if (scsq'event and scsq = '0') then
      sh := SLV_PAT;
    end if;

    if (sclk'event and sclk = '1' and scsq = '0') then
      sh := sh(USPI_SIZE-2 downto 0) & '0';
    end if;

    slave_shift <= sh;

    if scsq = '0' then
      sdi <= sh(USPI_SIZE-1);
    else
      sdi <= '0';
    end if;
  end process;


  stim : process
  begin

    resetn <= '0';
    wait for 100 ns;
    wait until rising_edge(bclk);
    resetn <= '1';

    sndData <= x"80AA";

    wait until rising_edge(bclk);
    start <= '1';
    wait until rising_edge(bclk);
    start <= '0';

    wait until done = '1';
    wait for 50 ns;

    report "RCV = 0x" & slv_to_hex(rcvData);

    sndData <= x"1234";
    wait until rising_edge(bclk);
    start <= '1';
    wait until rising_edge(bclk);
    start <= '0';

    wait until done = '1';
    wait for 50 ns;

    report "RCV2 = 0x" & slv_to_hex(rcvData);

    wait;
  end process;

end architecture;
