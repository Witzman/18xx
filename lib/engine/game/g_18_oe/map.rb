# frozen_string_literal: true

module Engine
  module Game
    module G18OE
      module Map
        LAYOUT = :pointy
        AXES = { x: :number, y: :letter }.freeze
        TILE_TYPE = :lawson

        LOCATION_NAMES = {
          # --- UK & Ireland ---
          'E26' => 'Inverness',
          'E28' => 'Aberdeen',
          'F25' => 'Glasgow',
          'F27' => 'Dundee',
          'G24' => 'Stranraer',
          'G26' => 'Edinburgh',
          'H17' => 'Sligo',
          'H21' => 'Belfast',
          'H29' => 'Newcastle Upon Tyne',
          'I16' => 'Limerick',
          'I20' => 'Dublin',
          'I26' => 'Preston',
          'J15' => 'Cork',
          'J17' => 'Waterford',
          'J23' => 'Holyhead',
          'J25' => 'Liverpool',
          'J27' => 'Manchester',
          'J29' => 'Leeds and Sheffield',
          'K26' => 'Birmingham',
          'L17' => 'Celtic Sea',
          'L23' => 'Cardiff',
          'L25' => 'Bristol',
          'L29' => 'Cambridge',
          'M26' => 'Southampton and Portsmouth',
          'M28' => 'London',

          # --- Sea zone labels (western, from UK-FR) ---
          'N21' => 'English Channel',
          'S20' => 'Bay of Biscay',

          # --- Sea zone labels (confirmed from location_names.csv) ---
          'E34' => 'North Sea',
          'G60' => 'Baltic Sea',
          'Z55' => 'Adriatic Sea',
          'Y84' => 'Black Sea',

          # --- France & Belgium ---
          'N31' => 'Lille',
          'N33' => 'Gent',
          'N35' => 'Brussel',
          'O24' => 'Cherbourg',
          'O28' => 'Le Havre',
          'P19' => 'Brest',
          'P29' => 'Rouen',
          'P33' => 'Reims',
          'P37' => 'Luxembourg',
          'Q26' => 'Le Mans',
          'Q30' => 'Paris',
          'Q38' => 'Nancy',
          'R23' => 'Nantes',
          'R29' => 'Orleans',
          'S34' => 'Dijon',
          'T27' => 'Limoges',
          'T37' => 'Geneve and Lausanne',
          'U24' => 'Bordeaux',
          'U32' => 'Saint-Etienne',
          'U34' => 'Lyon',
          'V21' => 'Bayonne',
          'V27' => 'Toulouse',
          'W32' => 'Nimes and Montpellier',

          # --- Spain & Portugal ---
          'X25' => 'Andorra',
          'X33' => 'Marseille',
          'X35' => 'Toulon',
          'X37' => 'Nice',
          'Y14' => 'Madrid',
          'Z27' => 'Barcelona',
          'Z41' => 'Ajaccio',
          'DD17' => 'Cartagena',
          'Z1'  => 'Lisboa',

          # --- Western Mediterranean sea labels ---
          'Z33' => 'Sea of Sardinia',
          'Z39' => 'Tyrrhenian Sea',

          # --- Aegean sea label ---
          'AA40' => 'Aegean Sea',

          # --- Scandinavia ---
          'C48' => 'Christiania',
          'D57' => 'Stockholm',
          'F49' => 'Goteborg',
          'I50' => 'Kobenhavn',

          # --- PHS Zone (Prussia / Holland / Switzerland) ---
          'K46' => 'Hamburg',
          'L53' => 'Stettin',
          'M50' => 'Berlin',
          'N49' => 'Leipzig',
          'R47' => 'Breslau',

          # --- Austria-Hungary ---
          'R55' => 'Wien',
          'S60' => 'Budapest',

          # --- Italy ---
          'V41' => 'Milano',
          'Z47' => 'Roma',
          'BB51' => 'Napoli',

          # --- Russia ---
          'C74' => 'Sankt-Peterburg',
          'J73' => 'Minsk',
          'M62' => 'Warszawa',
          'O80' => 'Kiev',

          # --- Constantinople ---
          'AA82' => 'Constantinople',

          # --- Off-board destination labels ---
          'D25' => 'Scottish Highlands',
          'A40' => 'Norwegian Coast (to Narvik)',
          'A54' => 'North Sweden',
          'A56' => 'North Sweden',
          'B41' => 'Norwegian Coast (to Narvik)',
          'B83' => 'Arkhangelsk',
          'E88' => 'Moskva',
          'F87' => 'Moskva',
          'G88' => 'Moskva',
          'N1'  => 'New York',
          'N87' => 'Kharkov',
          'S88' => 'Sevastopol',
          'T87' => 'Sevastopol',
          'BB87' => 'Levant',
          'DD1'  => 'North Africa & The Americas',
          'FF5'  => 'Casablanca',
          'FF11' => 'Melilla',
          'FF25' => 'Alger',
          'GG40' => 'Tunis',
          'GG88' => 'Alexandria & Suez',
          'HH87' => 'Alexandria & Suez',
        }.freeze

        HEXES = {
          white: {
            # -------------------------------------------------------------------------
            # Blank land hexes (no terrain cost, no city defined yet).
            # Terrain hexes have been extracted below; city-only hexes to be extracted
            # when cities.csv is applied.
            # -------------------------------------------------------------------------
            %w[
              A42 A66 A68 A70 A72 A74
              B47 B49 B55 B57 B63 B65 B67 B69 B71 B73 B75 B77 B79 B81
              C46 C48 C54 C56 C58 C64 C66 C72 C74 C76 C78 C80 C82
              D45 D47 D49 D55 D67 D69 D71 D73 D75 D77 D79 D81 D83 D85
              E42 E44 E48 E56 E58 E66 E68 E70 E72 E74 E76 E78 E80 E82 E84 E86
              F25 F27 F29 F49 F51 F53 F55 F69 F71 F73 F75 F77 F79 F81 F83 F85
              G26 G28 G46 G50 G52 G54 G56 G64 G66 G68 G70 G72 G74 G76 G78 G80 G82 G84 G86
              H17 H19 H21 H27 H29 H43 H45 H47 H51 H53 H55 H63 H65 H67 H69 H71 H73 H75 H77 H79 H81 H83 H85 H87
              I18 I20 I28 I44 I46 I64 I66 I68 I70 I72 I74 I76 I78 I80 I82 I84 I86
              J15 J17 J25 J27 J29 J45 J47 J49 J63 J65 J67 J69 J71 J73 J75 J77 J79 J81 J83 J85 J87
              K26 K28 K30 K40 K42 K44 K46 K48 K50 K54 K56 K58 K60 K62 K64 K66 K68 K70 K72 K74 K76 K78 K80 K82 K84 K86
              L25 L27 L29 L31 L37 L39 L41 L43 L45 L47 L49 L51 L53 L55 L57 L59 L61 L63 L65 L67 L69 L71 L73 L75 L77 L79 L81 L83 L85 L87
              M24 M26 M34 M36 M38 M40 M42 M44 M46 M48 M50 M52 M54 M56 M58 M60 M62 M64 M66 M68 M70 M72 M74 M76 M78 M80 M82 M84 M86
              N31 N33 N35 N37 N39 N41 N43 N45 N47 N49 N51 N53 N55 N57 N59 N61 N63 N65 N67 N69 N71 N73 N75 N77 N79 N81 N83 N85
              O24 O28 O30 O32 O34 O36 O38 O40 O42 O44 O46 O48 O50 O52 O54 O56 O58 O60 O62 O64 O66 O68 O70 O72 O74 O76 O78 O80 O82 O84 O86
              P19 P21 P23 P25 P27 P29 P31 P33 P35 P37 P39 P41 P43 P45 P47 P49 P51 P53 P55 P57 P59 P61 P63 P65 P67 P69 P71 P73 P75 P77 P79 P81 P83 P85 P87
              Q22 Q24 Q26 Q28 Q30 Q32 Q34 Q36 Q38 Q40 Q42 Q44 Q46 Q48 Q50 Q52 Q54 Q56 Q58 Q60 Q62 Q64 Q66 Q68 Q70 Q72 Q74 Q76 Q78 Q80 Q82 Q84 Q86
              R23 R25 R27 R29 R31 R33 R35 R37 R41 R43 R45 R47 R49 R51 R53 R55 R57 R59 R61 R63 R65 R67 R69 R71 R73 R75 R77 R79 R81 R83 R85 R87
              S24 S26 S28 S30 S32 S34 S36 S40 S56 S58 S60 S62 S64 S66 S68 S70 S72 S74 S76 S78 S80 S82 S84 S86
              T25 T27 T29 T31 T35 T53 T55 T57 T59 T61 T63 T65 T67 T69 T71 T73 T75 T77 T79 T81
              U6 U8 U22 U24 U26 U28 U34 U48 U50 U54 U56 U58 U60 U62 U64 U66 U68 U70 U72 U74 U76 U78 U80
              V5 V7 V17 V21 V23 V25 V27 V39 V41 V43 V45 V47 V51 V53 V55 V57 V59 V61 V63 V65 V67 V69 V71 V73 V75 V77 V79
              W6 W10 W12 W14 W16 W18 W26 W28 W30 W32 W34 W40 W46 W48 W56 W58 W60 W62 W64 W66 W68 W70 W72 W74 W76 W78
              X5 X9 X11 X13 X17 X21 X29 X33 X35 X37 X43 X49 X55 X63 X65 X67 X69 X71 X73 X75 X77
              Y2 Y4 Y16 Y18 Y20 Y22 Y24 Y28 Y44 Y46 Y50 Y56 Y58 Y64 Y66 Y68 Y70 Y72 Y74 Y76 Y78
              Z3 Z5 Z7 Z9 Z11 Z13 Z15 Z17 Z19 Z25 Z27 Z41 Z45 Z47 Z51 Z61 Z63 Z65 Z67 Z69 Z71 Z73 Z75 Z77 Z79
              AA2 AA4 AA6 AA8 AA14 AA16 AA20 AA22 AA48 AA52 AA54 AA62 AA64 AA66 AA68 AA70 AA72 AA74 AA76 AA78 AA80 AA82 AA84 AA86
              BB1 BB3 BB5 BB11 BB17 BB27 BB39 BB41 BB51 BB55 BB57 BB63 BB65 BB67 BB69 BB71 BB77 BB83 BB85
              CC6 CC8 CC10 CC12 CC16 CC18 CC20 CC38 CC40 CC56 CC58 CC64 CC66 CC68 CC76 CC78 CC80 CC82 CC84 CC86
              DD5 DD11 DD15 DD17 DD39 DD65 DD67 DD69 DD71 DD79 DD81 DD83 DD85 DD87
              EE68 EE70 EE72 EE80 EE82 EE84 EE86
              FF49 FF53 FF67 FF69 FF81 FF83 FF85 FF87
              GG52 GG68 GG70
            ] => '',

            # -------------------------------------------------------------------------
            # Mountain terrain — £30 upgrade cost
            # -------------------------------------------------------------------------
            %w[B51 B53 DD9 DD13 K22 M22 R39 S42 S50 T33 U10 U12 V15 V19 V33 W54 X45 X59 Y6 BB13 BB53 GG50] =>
              'upgrade=cost:30,terrain:mountain',

            # Mountain terrain — £30 upgrade cost + town
            %w[G24 I16 I26] => 'town=revenue:0;upgrade=cost:30,terrain:mountain',

            # Mountain terrain — £30 upgrade cost + city (Saint-Etienne)
            ['U32'] => 'city=revenue:0;upgrade=cost:30,terrain:mountain',

            # -------------------------------------------------------------------------
            # Mountain terrain — £45 upgrade cost
            # -------------------------------------------------------------------------
            %w[
              A48 A50 A52
              G18 H15 H25
              J13 J19
              K24
              S38 S44 S48
              U30 U52
              V9 V13 V29 V35
              W20 W36 W42 W44
              X7 X15 X27 X47 X57 X61
              Y26 Y48 Y62 Z21 Z49
              AA10 AA12 AA50
              BB7 BB9 BB19
              CC14 CC54
              DD55
            ] => 'upgrade=cost:45,terrain:mountain',

            # Mountain terrain — £45 upgrade cost + town
            %w[E26 E28 J23] => 'town=revenue:0;upgrade=cost:45,terrain:mountain',

            # Mountain terrain — £45 upgrade cost + double-town (Geneve and Lausanne)
            ['T37'] => 'town=revenue:0;town=revenue:0;upgrade=cost:45,terrain:mountain',

            # Mountain terrain — £45 upgrade cost + metropolis (Madrid)
            ['Y14'] => 'city=revenue:0;upgrade=cost:45,terrain:mountain',

            # -------------------------------------------------------------------------
            # Mountain terrain — £60 upgrade cost
            # -------------------------------------------------------------------------
            %w[
              A44 A46
              B43
              C44 D43
              S46 S52 S54
              T49 T51
              U36 U40 U42 U46
              V11 V31 V37
              W8 W24 W38
              X19
              Y8 Y10 Y12 Y60
              AA18
              BB15
              FF51
            ] => 'upgrade=cost:60,terrain:mountain',

            # -------------------------------------------------------------------------
            # Mountain terrain — £120 upgrade cost
            # -------------------------------------------------------------------------
            %w[B45 T39 T41 T43 T45 T47 U38 U44 W22 X23] => 'upgrade=cost:120,terrain:mountain',

            # -------------------------------------------------------------------------
            # Water terrain — £30 upgrade cost
            # -------------------------------------------------------------------------
            %w[C50 C52 D51 D53 G16 G20 I14 Z23] => 'upgrade=cost:30,terrain:water',

            # Water terrain — £30 upgrade cost + city (Stockholm)
            ['D57'] => 'city=revenue:0;upgrade=cost:30,terrain:water',

            # -------------------------------------------------------------------------
            # Water terrain — £45 upgrade cost
            # -------------------------------------------------------------------------
            %w[C42 D41 DD7 E24 E50 E52 E54 EE52 G44 I48 I52 Q20] =>
              'upgrade=cost:45,terrain:water',

            # Water terrain — £45 upgrade cost + impassable borders (Channel Islands area)
            ['M30'] => 'upgrade=cost:45,terrain:water;border=edge:3,type:impassable;border=edge:5,type:impassable',

            # Water terrain — £45 upgrade cost + town (Cardiff)
            ['L23'] => 'town=revenue:0;upgrade=cost:45,terrain:water',

            # Water terrain — £45 upgrade cost + city (Kobenhavn)
            ['I50'] => 'city=revenue:0;upgrade=cost:45,terrain:water',

            # -------------------------------------------------------------------------
            # Water terrain — £60 upgrade cost
            # -------------------------------------------------------------------------
            %w[F23 T23] => 'upgrade=cost:60,terrain:water',

            # Mountain terrain — £60 upgrade cost + town (X25 = Andorra)
            ['X25'] => 'town=revenue:0;upgrade=cost:60,terrain:mountain',
          },
          yellow: {
            # TODO: Pre-printed yellow tiles — path edges TBD from zoomed map images.
            # ['J25']  => 'city=revenue:30;label=Y;path=a:2,b:_0;path=a:_0,b:4',       # Liverpool
            # ['J27']  => 'city=revenue:20;path=a:1,b:_0;path=a:_0,b:4',               # Manchester
            # ['M28']  => 'city=revenue:30;upgrade=cost:30,terrain:water;path=a:5,b:_0;...', # London (metropolis, water:30)
            # ['AA82'] => 'city=revenue:NN;path=a:N,b:_0;...',                            # Constantinople (edges TBD)
          },
          red: {
            # Off-board hexes. Revenue values and path edges TBD from zoomed map images.
            # TODO: Replace offboard=revenue:0 with actual phase revenues.
            # TODO: Replace path=a:0,b:_0 with correct connecting edge numbers.

            # Northwest
            ['D25']  => 'offboard=revenue:yellow_20|green_40|brown_50;path=a:0,b:_0;path=a:5,b:_0', # Scottish Highlands

            # Northern Scandinavia
            ['A40']  => 'offboard=revenue:0;path=a:0,b:_0', # Norwegian Coast (to Narvik)
            ['A54']  => 'offboard=revenue:0;path=a:0,b:_0', # North Sweden
            ['A56']  => 'offboard=revenue:0;path=a:0,b:_0', # North Sweden
            ['B41']  => 'offboard=revenue:0;path=a:0,b:_0', # Norwegian Coast (to Narvik)
            ['B83']  => 'offboard=revenue:0;path=a:0,b:_0', # Arkhangelsk

            # Eastern Russia / Urals — three hexes all connecting to Moscow
            ['E88']  => 'offboard=revenue:0;path=a:0,b:_0', # Moskva
            ['F87']  => 'offboard=revenue:0;path=a:0,b:_0', # Moskva
            ['G88']  => 'offboard=revenue:0;path=a:0,b:_0', # Moskva

            # Far west / far east (mid-map)
            ['N1']   => 'offboard=revenue:0;path=a:0,b:_0', # New York
            ['N87']  => 'offboard=revenue:0;path=a:0,b:_0', # Kharkov

            # Black Sea / Crimea
            ['S88']  => 'offboard=revenue:0;path=a:0,b:_0', # Sevastopol
            ['T87']  => 'offboard=revenue:0;path=a:0,b:_0', # Sevastopol

            # Iberian / Atlantic — Lisboa: 2 station slots; top slot is RCP home
            ['Z1']   => 'offboard=revenue:0;city=revenue:0;city=revenue:0;path=a:0,b:_0',

            # Eastern Mediterranean / Middle East
            ['BB87'] => 'offboard=revenue:0;path=a:0,b:_0', # Levant

            # North Africa
            ['DD1']  => 'offboard=revenue:0;path=a:0,b:_0', # North Africa & The Americas
            ['FF5']  => 'offboard=revenue:0;path=a:0,b:_0', # Casablanca
            ['FF11'] => 'offboard=revenue:0;path=a:0,b:_0', # Melilla
            ['FF25'] => 'offboard=revenue:0;path=a:0,b:_0', # Alger
            ['GG40'] => 'offboard=revenue:0;path=a:0,b:_0', # Tunis
            ['GG88'] => 'offboard=revenue:0;path=a:0,b:_0', # Alexandria & Suez
            ['HH87'] => 'offboard=revenue:0;path=a:0,b:_0', # Alexandria & Suez
          },
          blue: {
            # Sea zone hexes — borders and ferry connections TBD from zoomed map images.
            # Copy from g_18_oe_uk_fr/map.rb for western zones (Channel, Biscay, Atlantic).
            # Eastern zones (North Sea, Baltic, Adriatic, Black Sea) to be added from sea_hexes.csv.
            #
            # Sea zone label hexes (no borders defined yet — just reserve the coordinate):
            # ['E34'] => '', # North Sea label
            # ['G60'] => '', # Baltic Sea label
            # ['Z55'] => '', # Adriatic Sea label
            # ['Y84'] => '', # Black Sea label
          },
        }.freeze
      end
    end
  end
end
