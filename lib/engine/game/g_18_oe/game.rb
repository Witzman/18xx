# frozen_string_literal: true

require_relative 'meta'
require_relative 'entities'
require_relative 'map'
require_relative '../base'
require_relative 'round/consolidation'
require_relative 'step/consolidate'
require_relative 'step/convert_to_national'
require_relative 'step/golden_bell_choice'
require_relative 'step/d_token_placement'
require_relative 'step/krasnaya_strela_assign'
require_relative 'step/hochberg_placement'

module Engine
  module Game
    module G18OE
      class Game < Game::Base
        include_meta(G18OE::Meta)
        include G18OE::Entities
        include G18OE::Map
        attr_accessor :minor_regional_order, :minor_available_regions, :minor_floated_regions, :regional_corps_floated,
                      :consolidation_triggered, :consolidation_complete, :golden_bell_position, :minor_track_rights,
                      :nationals_formation_queue
        attr_reader :fulfilled_train_obligation

        MARKET = [
          ['', '110', '120C', '135', '150', '165', '180', '200', '225', '250', '280', '310', '350', '390', '440', '490', '550'],
          %w[90p 100 110C 120 135 150 165 180 200 225 250 280 310 350 390 440 490],
          %w[80p 90 100C 110 120 135 150 165 180 200 225 250 280 310],
          %w[75p 80 90C 100 110 120 135 150 165 180 200],
          %w[70p 75 80C 90 100 110 120 135 150],
          %w[65p 70 75C 80 90 100 110],
          %w[60p 65 70 75 80],
          %w[50 60 65 70],
        ].freeze
        CERT_LIMIT = { 2 => 99, 3 => 48, 4 => 36, 5 => 29, 6 => 24, 7 => 20 }.freeze
        # Standard game: £5,400 total / num_players, rounded up to nearest £5.
        # 2-player variant uses without-concessions formula (£5,200 / 2 = £2,600).
        STARTING_CASH = { 2 => 2600, 3 => 1800, 4 => 1350, 5 => 1080, 6 => 900, 7 => 775 }.freeze
        BANK_CASH = 54_000
        CAPITALIZATION = :incremental
        SELL_BUY_ORDER = :sell_buy
        MUST_SELL_IN_BLOCKS = false
        HOME_TOKEN_TIMING = :float
        TILE_UPGRADES_MUST_USE_MAX_EXITS = [:cities].freeze
        # §13: bank-break ends at current OR; level-8 purchase ends at one_more_full_or_set
        GAME_END_CHECK = { bank: :current_or, final_phase: :one_more_full_or_set }.freeze
        # Physical game includes 20×£5,000 notes set aside at setup; injected when first level-8 bought
        REMAINDER_CASH = 100_000

        STOCKMARKET_COLORS = {
          par: :blue,
          convert_range: :red,
        }.freeze

        EVENTS_TEXT = Base::EVENTS_TEXT.merge(
          'consolidation_triggered' => [
            'Consolidation Round',
            'Consolidation round follows at end of current OR set; minors and regionals must merge or be abandoned',
          ],
          'd_token_phase_change' => [
            'Green Junction Bonus Upgraded',
            'Green Junction Mercantile +£20 marker removed; +£40 marker now available to place',
          ],
          'remainder_cash_added' => [
            'Remainder Cash Added',
            '£100,000 remainder cash injected into bank; game ends after one more full OR set',
          ]
        ).freeze

        MARKET_TEXT = {
          par: 'Regional par values',
          convert_range: 'Major par values',
        }.freeze

        PHASES = [
          {
            name: '2',
            train_limit: { minor: 2, regional: 2, major: 4 },
            tiles: [:yellow],
            operating_rounds: 2,
            status: ['train_obligation'],
          },
          {
            name: '3',
            on: '3',
            train_limit: { minor: 2, regional: 2, major: 4 },
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['train_obligation', 'can_merge_minors'],
          },
          {
            name: '4',
            on: '4',
            train_limit: { minor: 1, regional: 1, major: 3, national: 4 },
            tiles: %i[yellow green],
            operating_rounds: 2,
            status: ['can_merge_minors', 'sml_available', 'nationals_can_form'],
          },
          {
            name: '5',
            on: '5',
            train_limit: { minor: 1, regional: 1, major: 3, national: 4 },
            tiles: %i[yellow green brown],
            operating_rounds: 2,
            status: ['can_merge_minors', 'sml_available'],
          },
          {
            name: '6',
            on: '6',
            train_limit: { major: 2, national: 3 },
            tiles: %i[yellow green brown],
            operating_rounds: 2,
            status: ['can_merge_minors', 'sml_available', 'nationals_can_form'],
          },
          {
            name: '7',
            on: '7+7',
            train_limit: { major: 2, national: 3 },
            tiles: %i[yellow green brown gray],
            operating_rounds: 2,
            status: ['can_merge_minors', 'sml_available'],
          },
          {
            name: '8',
            on: '8+8',
            train_limit: { major: 2, national: 3 },
            tiles: %i[yellow green brown gray],
            operating_rounds: 2,
            status: ['can_merge_minors', 'sml_available', 'nationals_can_form'],
          },
        ].freeze

        TRAINS = [
          # Level 2 — yellow; rusts when first Level 4 train is bought
          {
            name: '2+2',
            distance: [{ 'nodes' => ['town'], 'pay' => 2, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 2, 'visit' => 2 }],
            price: 100,
            rusts_on: '4',
            num: 30,
          },
          # Level 3 — green double-sided (3 / 3+3); rust at Level 6
          {
            name: '3',
            distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 }],
            price: 200,
            rusts_on: '6',
            variants: [{
              name: '3+3',
              distance: [{ 'nodes' => ['town'], 'pay' => 3, 'visit' => 99 },
                         { 'nodes' => %w[city offboard town], 'pay' => 3, 'visit' => 3 }],
              price: 225,
              rusts_on: '6',
            }],
            num: 20,
          },
          # Level 4 — green double-sided (4 / 4+4); rust at Level 8
          {
            name: '4',
            distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 4, 'visit' => 4 }],
            price: 300,
            rusts_on: '8+8',
            variants: [{
              name: '4+4',
              distance: [{ 'nodes' => ['town'], 'pay' => 4, 'visit' => 99 },
                         { 'nodes' => %w[city offboard town], 'pay' => 4, 'visit' => 4 }],
              price: 350,
              rusts_on: '8+8',
            }],
            num: 10,
          },
          # Level 5 — brown double-sided (5 / 5+5); permanent
          {
            name: '5',
            distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 5, 'visit' => 5 }],
            price: 400,
            variants: [{
              name: '5+5',
              distance: [{ 'nodes' => ['town'], 'pay' => 5, 'visit' => 99 },
                         { 'nodes' => %w[city offboard town], 'pay' => 5, 'visit' => 5 }],
              price: 475,
            }],
            num: 8,
            events: [{ 'type' => 'consolidation_triggered' }, { 'type' => 'd_token_phase_change' }],
          },
          # Level 6 — brown double-sided (6 / 6+6); permanent
          {
            name: '6',
            distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 6, 'visit' => 6 }],
            price: 525,
            variants: [{
              name: '6+6',
              distance: [{ 'nodes' => ['town'], 'pay' => 6, 'visit' => 99 },
                         { 'nodes' => %w[city offboard town], 'pay' => 6, 'visit' => 6 }],
              price: 600,
            }],
            num: 6,
          },
          # Level 7 — gray double-sided (7+7 / 4D); permanent
          # NOTE: Level 8 trains become available only after the 4th Level 7 purchase
          {
            name: '7+7',
            distance: [{ 'nodes' => ['town'], 'pay' => 7, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 7, 'visit' => 7 }],
            price: 750,
            variants: [{
              name: '4D',
              distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                         { 'nodes' => %w[city offboard], 'pay' => 4, 'visit' => 99 }],
              price: 850,
            }],
            num: 14,
          },
          # Level 8 — gray double-sided (8+8 / 5D); permanent
          # NOTE: purchase of the FIRST level-8 triggers game end
          {
            name: '8+8',
            distance: [{ 'nodes' => ['town'], 'pay' => 8, 'visit' => 99 },
                       { 'nodes' => %w[city offboard town], 'pay' => 8, 'visit' => 8 }],
            price: 900,
            variants: [{
              name: '5D',
              distance: [{ 'nodes' => ['town'], 'pay' => 0, 'visit' => 99 },
                         { 'nodes' => %w[city offboard], 'pay' => 5, 'visit' => 99 }],
              price: 1000,
            }],
            num: 8,
            available_on: '7',
            events: [{ 'type' => 'remainder_cash_added' }],
          },
        ].freeze

        # 2 chits per zone; 16 total for 12 minors.
        # Asterisked zones (UK/PHS/FR): 6 chits combined but capped at 4 selections —
        # when the 4th is taken the remaining chits for those zones are removed from play.
        MINOR_TRACK_RIGHTS_CHITS = {
          'UK' => 2,
          'PHS' => 2,
          'FR' => 2,
          'AH' => 2,
          'IT' => 2,
          'SP' => 2,
          'SC' => 2,
          'RU' => 2,
        }.freeze
        ASTERISKED_ZONES = %w[UK PHS FR].freeze
        ASTERISKED_ZONES_CAP = 4

        ZONE_DISCOUNT_ZONES         = %w[SP IT SC RU].freeze
        ZONE_DISCOUNT_RATE          = 0.2 # 20% §11.1.5
        ZONE_TERRAIN_DISCOUNT_RATE  = 0.5 # 50% §11.1.5; E/F augment zone discount
        TILE_POINT_BUDGET = { minor: 3, regional: 3, major: 6, national: 9 }.freeze
        MINOR_MAX_TREASURY = 180
        EF_TERRAIN_AUGMENT          = { 'E' => :water, 'F' => :mountain }.freeze
        EXTRA_TILE_POINTS = { 'G' => 2 }.freeze
        MAIL_CONTRACT_REVENUE = { '2' => 20, '3' => 40, '4' => 40, '5' => 50, '6' => 50, '7' => 60, '8' => 60 }.freeze
        DISCOUNTED_UPGRADE_CORPORATIONS = %w[B].freeze
        GOLDEN_BELL_CORP_ID   = 'C'
        D_TOKEN_CORP_ID       = 'D'
        MAIL_CONTRACT_CORP_ID = 'K'
        CCTC_COMPANY_SYM      = 'CCTC'
        CCTC_TOWN_REVENUE     = { '2' => 10, '3' => 20, '4' => 20, '5' => 40, '6' => 40, '7' => 60, '8' => 60 }.freeze
        HMLC_COMPANY_SYM      = 'HMLC'
        HMLC_MIN_TERRAIN_COST = 45
        KRASNAYA_STRELA_CORP_ID = 'L'
        TRAIN_DISCOUNT_RATE   = 0.1
        D_TOKEN_PHASE2_BONUS  = 20
        D_TOKEN_PHASE5_BONUS  = 40
        SML_COMPANY_SYM = 'SML'
        SML_TRAIN_NAME  = '2+2'
        BBE_COMPANY_SYM  = 'BBE'
        BBBT_COMPANY_SYM = 'BBBT'

        CORPORATIONS_TRACK_RIGHTS = {
          # United Kingdom
          'LNWR' => 'UK',
          'GWR' => 'UK',
          'GSWR' => 'UK',
          # France / Belgium
          'PLM' => 'FR',
          'MIDI' => 'FR',
          'OU' => 'FR',
          'BEL' => 'FR',
          # Prussia / Holland / Switzerland
          'BHB' => 'PHS',
          'POB' => 'PHS',
          'KSS' => 'PHS',
          'KBS' => 'PHS',
          # Austria-Hungary
          'SB' => 'AH',
          'MAV' => 'AH',
          # Italy
          'SFAI' => 'IT',
          'SFR' => 'IT',
          # Spain / Portugal
          'CHN' => 'SP',
          'MZA' => 'SP',
          'RCP' => 'SP',
          # Russia
          'MSP' => 'RU',
          'MKV' => 'RU',
          'LRZD' => 'RU',
          'WW' => 'RU',
          # Scandinavia
          'DSJ' => 'SC',
          'BJV' => 'SC',
        }.freeze

        NATIONAL_REGION_HEXES = {
          # United Kingdom / Ireland
          'UK' => %w[D25 E24 E26 E28 F23 F25 F27 F29 G16 G18 G20 G24 G26 G28
                     H15 H17 H19 H21 H25 H27 H29 I14 I16 I18 I20 I26 I28
                     J13 J15 J17 J19 J23 J25 J27 J29 K22 K24 K26 K28 K30
                     L23 L25 L27 L29 L31 M22 M24 M26 M28 M30],
          # Scandinavia (Sweden / Norway / Denmark)
          'SC' => %w[A42 A44 A46 A48 A50 A52 A54 A56 B41 B43 B45 B47 B49 B51 B53 B55 B57
                     C42 C44 C46 C48 C50 C52 C54 C56 C58 D41 D43 D45 D47 D49 D51 D53 D55 D57
                     E42 E44 E48 E50 E52 E54 E56 E58 F49 F51 F53 F55
                     G44 G46 G50 G52 G54 G56 H43 H45 H47 H51 H53 H55 I44 I46 I48 I50 I52],
          # France / Belgium
          'FR' => %w[N31 N33 N35 N37 O24 O28 O30 O32 O34 O36 O38
                     P19 P21 P23 P25 P27 P29 P31 P33 P35 P37
                     Q20 Q22 Q24 Q26 Q28 Q30 Q32 Q34 Q36 Q38
                     R23 R25 R27 R29 R31 R33 R35 R37 R39
                     S24 S26 S28 S30 S32 S34 S36 S38 T23 T25 T27 T29 T31 T33 T35 T37
                     U22 U24 U26 U28 U30 U32 U34 U36 U38
                     V21 V23 V25 V27 V29 V31 V33 V35 V37
                     W22 W24 W26 W28 W30 W32 W34 W36 W38
                     X25 X27 X29 X33 X35 X37 Y28 Z41 AF25],
          # Prussia / Holland / Switzerland
          'PHS' => %w[I64 J45 J47 J49 J63 J65 K40 K42 K44 K46 K48 K50 K54 K56 K58 K60 K62 K64
                      L37 L39 L41 L43 L45 L47 L49 L51 L53 L55 L57 L59 L61
                      M34 M36 M38 M40 M42 M44 M46 M48 M50 M52 M54 M56 M58
                      N37 N39 N41 N43 N45 N47 N49 N51 N53 N55 N57
                      O38 O40 O42 O44 O46 O48 O50 O52 O54 O56 O58
                      P39 P41 P43 P45 P47 P49 Q38 Q40 Q42 Q44 Q46 Q48 Q50
                      R39 R41 R43 R45 R47 R49 R51 S38 S40 S42 S44 S46 S48
                      T37 T39 T41 T43 U38 U40 U42],
          # Austria-Hungary
          'AH' => %w[O52 O54 P49 P51 P53 P55 P57 P59 P61 P63 P65 P67 P69 P71 P73
                     Q50 Q52 Q54 Q56 Q58 Q60 Q62 Q64 Q66 Q68 Q70 Q72 Q74
                     R51 R53 R55 R57 R59 R61 R63 R65 R67 R69 R71 R73
                     S44 S46 S48 S50 S52 S54 S56 S58 S60 S62 S64 S66 S68 S70 S72 S74
                     T45 T47 T49 T51 T53 T55 T57 T59 T61 T63 T65 T67 T69 T71 T73 T75
                     U50 U52 U54 U56 U58 U60 U62 U64 U66 U68 U70 U72 U74
                     V51 V53 V55 V57 V59 V61 V63 V65 V67 V69
                     W54 W56 W58 W60 X55 X57 X59 X61 Y56 Y58 Y60 Y62],
          # Italy
          'IT' => %w[U38 U40 U42 U44 U46 U48 V37 V39 V41 V43 V45 V47
                     W38 W40 W42 W44 W46 W48 X43 X45 X47 X49 Y44 Y46 Y48 Y50
                     Z45 Z47 Z49 Z51 AA48 AA50 AA52 AA54
                     AB39 AB41 AB51 AB53 AB55 AB57 AC38 AC40 AC54 AC56 AC58
                     AD39 AD55 AE52 AF49 AF51 AF53 AG40 AG50 AG52],
          # Spain / Portugal
          'SP' => %w[U6 U8 U10 U12 V5 V7 V9 V11 V13 V15 V17 V19
                     W6 W8 W10 W12 W14 W16 W18 W20 W22
                     X5 X7 X9 X11 X13 X15 X17 X19 X21 X23 X25
                     Y2 Y4 Y6 Y8 Y10 Y12 Y14 Y16 Y18 Y20 Y22 Y24 Y26 Y28
                     Z1 Z3 Z5 Z7 Z9 Z11 Z13 Z15 Z17 Z19 Z21 Z23 Z25 Z27
                     AA2 AA4 AA6 AA8 AA10 AA12 AA14 AA16 AA18 AA20 AA22
                     AB1 AB3 AB5 AB7 AB9 AB11 AB13 AB15 AB17 AB19
                     AC6 AC8 AC10 AC12 AC14 AC16 AC18 AC20
                     AD1 AD5 AD7 AD9 AD11 AD13 AD15 AD17 AF5 AF11],
          # Russia
          'RU' => %w[A64 A66 A68 A70 A72 A74 B63 B65 B67 B69 B71 B73 B75 B77 B79 B81 B83
                     C64 C66 C72 C74 C76 C78 C80 C82 D67 D69 D71 D73 D75 D77 D79 D81 D83 D85
                     E66 E68 E70 E72 E74 E76 E78 E80 E82 E84 E86
                     F69 F71 F73 F75 F77 F79 F81 F83 F85 F87
                     G64 G66 G68 G70 G72 G74 G76 G78 G80 G82 G84 G86 G88
                     H63 H65 H67 H69 H71 H73 H75 H77 H79 H81 H83 H85 H87
                     I64 I66 I68 I70 I72 I74 I76 I78 I80 I82 I84 I86
                     J67 J69 J71 J73 J75 J77 J79 J81 J83 J85 J87
                     K64 K66 K68 K70 K72 K74 K76 K78 K80 K82 K84 K86
                     L61 L63 L65 L67 L69 L71 L73 L75 L77 L79 L81 L83 L85 L87
                     M58 M60 M62 M64 M66 M68 M70 M72 M74 M76 M78 M80 M82 M84 M86
                     N59 N61 N63 N65 N67 N69 N71 N73 N75 N77 N79 N81 N83 N85 N87
                     O58 O60 O62 O64 O66 O68 O70 O72 O74 O76 O78 O80 O82 O84 O86
                     P73 P75 P77 P79 P81 P83 P85 P87 Q74 Q76 Q78 Q80 Q82 Q84 Q86
                     R75 R77 R79 R81 R83 R85 R87 S76 S78 S80 S82 S84 S86 S88 T79 T81 T87 U80],
        }.freeze

        # Cities that sit on a national-zone border hex (hex listed in two zones).
        # All other cities belong unambiguously to one zone; only these two need an explicit override.
        CITY_NATIONAL_ZONE = {
          'Q38' => 'FR',  # Nancy   — FR/PHS border hex
          'O52' => 'PHS', # Dresden — PHS/AH border hex
        }.freeze

        # §1.3.1 dev-note: all nationals within a zone share one national railroad name.
        NATIONAL_NAMES = {
          # United Kingdom
          'LNWR' => 'British Railways',
          'GWR'  => 'British Railways',
          'GSWR' => 'British Railways',
          # France / Belgium
          'PLM'  => 'Societe nationale des chemins de fer francais',
          'MIDI' => 'Societe nationale des chemins de fer francais',
          'OU'   => 'Societe nationale des chemins de fer francais',
          'BEL'  => 'Societe nationale des chemins de fer francais',
          # Prussia / Holland / Switzerland
          'BHB'  => 'Deutsche Bahn',
          'POB'  => 'Deutsche Bahn',
          'KSS'  => 'Deutsche Bahn',
          'KBS'  => 'Deutsche Bahn',
          # Austria-Hungary
          'SB'   => 'Österreichische Bundesbahnen',
          'MAV'  => 'Österreichische Bundesbahnen',
          # Italy
          'SFAI' => 'Ferrovie dello Stato',
          'SFR'  => 'Ferrovie dello Stato',
          # Spain / Portugal
          'CHN'  => 'Red Nacional de los Ferrocarriles Espanoles',
          'MZA'  => 'Red Nacional de los Ferrocarriles Espanoles',
          'RCP'  => 'Red Nacional de los Ferrocarriles Espanoles',
          # Russia
          'MSP'  => 'Rossiyskiye Zheleznye Dorogi',
          'MKV'  => 'Rossiyskiye Zheleznye Dorogi',
          'LRZD' => 'Rossiyskiye Zheleznye Dorogi',
          'WW'   => 'Rossiyskiye Zheleznye Dorogi',
          # Scandinavia
          'DSJ'  => 'Statens Järnvägar',
          'BJV'  => 'Statens Järnvägar',
        }.freeze

        # Cities excluded from minor home-token placement regardless of zone membership.
        # These are Balkan / Ottoman / south-east European cities outside the concession
        # railroad system. Most are already outside all zone hex lists; S76 (Jassy) is the
        # only one currently inside a zone (RU) that requires active filtering.
        # AA82 (Constantinople) is also excluded via metropolis_hex? but listed here for clarity.
        MINOR_EXCLUDED_HOME_CITIES = %w[
          S76 W64 W74 Y70
          AA62 AB69 AD79 AE72 AA82
        ].freeze

        TRACK_RIGHTS_COST = {
          'UK' => 40,
          'PHS' => 40,
          'FR' => 20,
          'AH' => 20,
          'IT' => 10,
          'SP' => 10,
          'RU' => 10,
          'SC' => 10,
        }.freeze

        MAX_FLOATED_REGIONALS = 18
        CONVERSION_NEW_SHARES = 6

        METROPOLIS_UPGRADE_CHAINS = {
          'K26'  => %w[OE4 OE12 OE26 OE37].freeze, # Birmingham
          'M28'  => %w[OE6 OE15 OE28 OE40].freeze, # London
          'Q30'  => %w[OE4 OE17 OE30 OE37].freeze, # Paris
          'Y14'  => %w[OE4 OE12 OE26 OE37].freeze, # Madrid
          'M50'  => %w[OE4 OE13 OE27 OE38].freeze, # Berlin
          'R55'  => %w[OE4 OE12 OE26 OE37].freeze, # Wien
          'AB51' => %w[OE7 OE16 OE29 OE41].freeze, # Napoli
          'AA82' => %w[OE5 OE14 OE26 OE39].freeze, # Constantinople
          'C74'  => %w[OE8 OE18 OE26 OE37].freeze, # Sankt-Peterburg
        }.freeze

        TILES = {
          '3' => {
            'count' => 14,
            'color' => 'yellow',
            'code' => 'town=revenue:10,style:dot,loc:center;path=a:0,b:_0;path=a:_0,b:1',
          },
          '4' => {
            'count' => 25,
            'color' => 'yellow',
            'code' => 'town=revenue:10,style:dot,loc:center;path=a:0,b:_0;path=a:_0,b:3',
          },
          '5' => 15,
          '6' => 25,
          '7' => 14,
          '8' => 88,
          '9' => 90,
          '12' => 10,
          '13' => 8,
          '57' => 19,
          '58' => {
            'count' => 25,
            'color' => 'yellow',
            'code' => 'town=revenue:10,style:dot,loc:center;path=a:0,b:_0;path=a:_0,b:2',
          },
          '80' => 5,
          '81' => 5,
          '82' => 20,
          '83' => 20,
          '141' => 15,
          '142' => 15,
          '143' => 5,
          '144' => 5,
          '145' => 13,
          '146' => 21,
          '147' => 13,
          '201' => 9,
          '202' => 18,
          '205' => 17,
          '206' => 17,
          '207' => 12,
          '208' => 9,
          '544' => 8,
          '545' => 8,
          '546' => 7,
          '621' => 12,
          '622' => 9,
          'OE1' =>
            {
              'count' => 4,
              'color' => 'yellow',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:3,b:_0',
            },
          'OE2' =>
            {
              'count' => 6,
              'color' => 'yellow',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:2,b:_0',
            },
          'OE3' =>
            {
              'count' => 2,
              'color' => 'yellow',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:1,b:_0',
            },
          'OE4' =>
            {
              'count' => 5,
              'color' => 'yellow',
              'code' => 'city=revenue:30;city=revenue:30;city=revenue:30;path=a:0,b:_0;path=a:2,b:_1;path=a:4,b:_2;label=ABP',
            },
          'OE5' =>
            {
              'count' => 1,
              'color' => 'yellow',
              'code' => 'city=revenue:30;city=revenue:30;path=a:0,b:_0;path=a:_0,b:1;path=a:5,b:_1;path=a:_1,b:3;label=C',
            },
          'OE6' =>
            {
              'count' => 1,
              'color' => 'yellow',
              'code' => 'city=revenue:30;city=revenue:30;path=a:1,b:_0;path=a:5,b:_0;path=a:2,b:_1;path=a:4,b:_1;label=L',
            },
          'OE7' =>
            {
              'count' => 1,
              'color' => 'yellow',
              'code' => 'city=revenue:30;city=revenue:30;path=a:1,b:_0;path=a:4,b:_1;label=N',
            },
          'OE8' =>
            {
              'count' => 1,
              'color' => 'yellow',
              'code' => 'city=revenue:30;city=revenue:30;path=a:0,b:_0;path=a:5,b:_1;label=S',
            },
          'OE9' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            },
          'OE10' =>
            {
              'count' => 3,
              'color' => 'green',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0',
            },
          'OE11' =>
            {
              'count' => 3,
              'color' => 'green',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0',
            },
          'OE12' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:50;city=revenue:50;city=revenue:50;path=a:0,b:_0;path=a:_0,b:3;'\
                        'path=a:2,b:_1;path=a:_1,b:5;path=a:4,b:_2;path=a:_2,b:1;label=A',
            },
          'OE13' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:60;city=revenue:60;city=revenue:60;path=a:0,b:_0;path=a:_0,b:3;'\
                        'path=a:2,b:_1;path=a:_1,b:5;path=a:4,b:_2;path=a:_2,b:1;label=B',
            },
          'OE14' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:50;city=revenue:50,slots:2;path=a:0,b:_0;path=a:_0,b:1;path=a:5,b:_1;path=a:_1,b:3;label=C',
            },
          'OE15' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:60,slots:2;city=revenue:60,slots:2;path=a:1,b:_0;path=a:5,b:_0;'\
                        'path=a:2,b:_1;path=a:3,b:_1;path=a:4,b:_1;label=L',
            },
          'OE16' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:50,slots:2;city=revenue:50;path=a:1,b:_0;path=a:_0,b:3;path=a:4,b:_1;path=a:_1,b:2;label=N',
            },
          'OE17' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:50;city=revenue:50;city=revenue:50;path=a:0,b:_0;path=a:2,b:_1;path=a:4,b:_2;label=P',
            },
          'OE18' =>
            {
              'count' => 1,
              'color' => 'green',
              'code' => 'city=revenue:50;city=revenue:50,slots:2;path=a:0,b:_0;path=a:_0,b:2;path=a:5,b:_1;path=a:_1,b:3;label=S',
            },
          'OE20' =>
            {
              'count' => 3,
              'color' => 'brown',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0',
            },
          'OE21' =>
            {
              'count' => 2,
              'color' => 'brown',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            },
          'OE22' =>
            {
              'count' => 6,
              'color' => 'brown',
              'code' => 'town=revenue:10,size:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;' \
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0',
            },
          'OE23' =>
            {
              'count' => 12,
              'color' => 'brown',
              'code' => 'city=revenue:40;path=a:0,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            },
          'OE24' =>
            {
              'count' => 20,
              'color' => 'brown',
              'code' => 'city=revenue:40;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0',
            },
          'OE25' =>
            {
              'count' => 12,
              'color' => 'brown',
              'code' => 'city=revenue:40;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            },
          'OE26' =>
            {
              'count' => 1,
              'color' => 'brown',
              'code' => 'city=revenue:80,slots:3;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=ACS',
            },
          'OE27' =>
            {
              'count' => 1,
              'color' => 'brown',
              'code' => 'city=revenue:80,slots:4;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=B',
            },
          'OE28' =>
            {
              'count' => 1,
              'color' => 'brown',
              'code' => 'city=revenue:90,slots:4;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=L',
            },
          'OE29' =>
            {
              'count' => 1,
              'color' => 'brown',
              'code' => 'city=revenue:80,slots:3;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;label=N',
            },
          'OE30' =>
            {
              'count' => 1,
              'color' => 'brown',
              'code' => 'city=revenue:80;city=revenue:80;city=revenue:80;path=a:0,b:_0;path=a:1,b:_1;path=a:2,b:_1;'\
                        'path=a:3,b:_2;path=a:4,b:_2;path=a:5,b:_0;label=P',
            },
          'OE31' =>
            {
              'count' => 3,
              'color' => 'brown',
              'code' => 'city=revenue:60,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0;label=Y',
            },
          'OE32' =>
            {
              'count' => 3,
              'color' => 'brown',
              'code' => 'city=revenue:60,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0;label=Y',
            },
          'OE33' =>
            {
              'count' => 11,
              'color' => 'brown',
              'code' => 'city=revenue:60,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=Y',
            },
          'OE34' =>
            {
              'count' => 5,
              'color' => 'gray',
              'code' => 'city=revenue:60;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0',
            },
          'OE35' =>
            {
              'count' => 6,
              'color' => 'gray',
              'code' => 'city=revenue:60;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0',
            },
          'OE36' =>
            {
              'count' => 16,
              'color' => 'gray',
              'code' => 'city=revenue:60;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0',
            },
          'OE37' =>
            {
              'count' => 3,
              'color' => 'gray',
              'code' => 'city=revenue:100,slots:3;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=APS',
            },
          'OE38' =>
            {
              'count' => 1,
              'color' => 'gray',
              'code' => 'city=revenue:120,slots:4;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=B',
            },
          'OE39' =>
            {
              'count' => 1,
              'color' => 'gray',
              'code' => 'city=revenue:100,slots:4;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=B',
            },
          'OE40' =>
            {
              'count' => 1,
              'color' => 'gray',
              'code' => 'city=revenue:120,slots:4;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=L',
            },
          'OE41' =>
            {
              'count' => 1,
              'color' => 'gray',
              'code' => 'city=revenue:100,slots:3;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:4,b:_0;label=N',
            },
          'OE42' =>
            {
              'count' => 3,
              'color' => 'gray',
              'code' => 'city=revenue:80,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:5,b:_0;label=Y',
            },
          'OE43' =>
            {
              'count' => 3,
              'color' => 'gray',
              'code' => 'city=revenue:80,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;path=a:3,b:_0;path=a:5,b:_0;label=Y',
            },
          'OE44' =>
            {
              'count' => 11,
              'color' => 'gray',
              'code' => 'city=revenue:80,slots:2;path=a:0,b:_0;path=a:1,b:_0;path=a:2,b:_0;'\
                        'path=a:3,b:_0;path=a:4,b:_0;path=a:5,b:_0;label=Y',
            },
        }.freeze

        def setup
          super
          @golden_bell_position = :normal
          @krasnaya_strela_train = nil
          @krasnaya_strela_base_distance = nil
          @minor_regional_order = []
          @minor_available_regions = self.class::MINOR_TRACK_RIGHTS_CHITS.transform_values(&:itself)
          @minor_asterisked_selected = 0
          @minor_floated_regions = {}
          @minor_track_rights = {}
          @regional_corps_floated = 0
          @fulfilled_train_obligation = Set.new
          @first_or_complete = false
          @nationals_formation_queue = []
          @cctc_corp = nil
          @cctc_hex = nil
          @sml_claimed = false
          @sml_trains  = Set.new
          @bbe_hexes        = {}
          @bbbt_protected_corp = nil

          corporations.each do |corp|
            corp.par_via_exchange = companies.find { |c| c.sym == corp.id } if corp.type == :minor
          end
        end

        def revenue_for(route, stops)
          base = super

          route.train.owner.all_abilities
            .select { |a| a.type == :hex_bonus && !a.hexes.empty? }
            .each { |a| base += a.amount * stops.count { |s| a.hexes.include?(s.hex.coordinates) } }

          return base unless d_train?(route.train)

          # §11.6 — D-trains double all city and red-zone (offboard) revenue
          doublers = stops.select { |s| s.city? || s.offboard? }
          doubling_bonus = doublers.sum { |s| s.route_revenue(route.phase, route.train) }

          # §15.7 — Krasnaya Strela: the extra city on a D-train does not double;
          # player may choose any city — optimal choice is always the lowest-value stop
          if @krasnaya_strela_train == route.train
            min_rev = doublers.map { |s| s.route_revenue(route.phase, route.train) }.min || 0
            doubling_bonus -= min_rev
          end

          base + doubling_bonus
        end

        def d_train?(train)
          %w[4D 5D].include?(train.name)
        end

        def ipo_name(_entity = nil)
          'Treasury'
        end

        # ── Nationals: formation trigger ────────────────────────────────────────

        # Called from Step::BuyTrain when phase 4, 6, or 8 begins.
        # Builds the formation queue starting with buyer_player, then all other
        # players in seat order who own at least one major.
        def eligible_majors_for(player)
          corporations.select { |c| c.type == :major && c.president?(player) }
        end

        def trigger_nationals_formation!(buyer_player)
          buyer_idx = @players.index(buyer_player) || 0
          eligible = @players.rotate(buyer_idx).select { |p| eligible_majors_for(p).any? }
          return if eligible.empty?

          @nationals_formation_queue = eligible
          @log << '-- Event: Nationals may now form --'
        end

        # ── Nationals: conversion ───────────────────────────────────────────────

        def convert_to_national(corporation)
          @log << "#{corporation.name} converts to a National Railroad"

          # 1. Cash → bank
          if corporation.cash.positive?
            @log << "  #{corporation.name} returns £#{corporation.cash} to bank"
            corporation.spend(corporation.cash, @bank)
          end

          # 2. Treasury certs → Open Market (50% limit temporarily waived per rules)
          treasury_shares = (corporation.shares_by_corporation[corporation] || []).dup
          treasury_shares.each do |share|
            @share_pool.transfer_shares(share.to_bundle, @share_pool, allow_president_change: false)
          end

          # 3. Remove all tokens from map
          corporation.tokens.each do |token|
            next unless token.city

            token.remove!
          end

          # 4. Flip to national type and apply national name (§1.3.1)
          national_name = NATIONAL_NAMES[corporation.id]
          corporation.type = :national
          if national_name
            corporation.full_name = national_name
            @log << "  #{corporation.name} operates as #{national_name}"
          end
          @log << "  #{corporation.name} is now a National Railroad"

          # 5. Enforce train limit — discard cheapest excess trains
          limit = @phase.train_limit(corporation)
          while corporation.trains.length > limit
            train = corporation.trains.min_by(&:price)
            @log << "  #{corporation.name} discards #{train.name} (train limit #{limit})"
            @depot.reclaim_train(train)
          end

          # 6. Clear merged-minor track rights — §10.5: chits stay on abandoned minor's charter,
          #    not transferred to national. Prevents stale zones giving zone discounts post-conversion.
          @minor_track_rights.delete(corporation.id)

          # 7. Remove BBE hex markers owned by this corporation (§9.4 §1.3d)
          @bbe_hexes.delete_if { |_, corp| corp == corporation }
        end

        # ── Nationals: revenue ──────────────────────────────────────────────────

        # Zone-based virtual-token revenue formula (openpoints §1.4).
        # All zone cities/towns are always linked (no track connection required).
        # Excess capacity beyond zone stops fills at £60/city or £10/town.
        def national_revenue(entity)
          region = CORPORATIONS_TRACK_RIGHTS[entity.id] || @minor_floated_regions[entity.id]
          zone_hexes = NATIONAL_REGION_HEXES[region] || []

          # Capacity totals across all trains
          city_capacity = entity.trains.sum do |t|
            t.distance.find { |d| d['nodes'].include?('city') }&.dig('pay') || 0
          end
          town_capacity = entity.trains.sum do |t|
            t.distance.find { |d| d['nodes'] == ['town'] }&.dig('pay') || 0
          end

          linked_cities = []
          linked_towns  = []

          zone_hexes.each do |hex_name|
            hex = @hexes.find { |h| h.name == hex_name }
            next unless hex

            hex.tile.cities.each { |c| linked_cities << c.max_revenue }
            hex.tile.towns.each  { |t| linked_towns  << t.max_revenue }
          end

          linked_cities.sort!.reverse!
          linked_towns.sort!.reverse!

          has_d_train = entity.trains.any? { |t| t.name.end_with?('D') }
          revenue = 0

          # Fill city capacity: linked cities best-first (doubled with D-train), then £60 each for remainder
          taken_cities = [city_capacity, linked_cities.size].min
          linked_city_revenue = linked_cities.first(taken_cities).sum
          linked_city_revenue *= 2 if has_d_train
          revenue += linked_city_revenue
          city_capacity -= taken_cities
          revenue += city_capacity * 60 if city_capacity.positive?

          # Fill town capacity: linked towns best-first, then £10 each for remainder
          taken_towns = [town_capacity, linked_towns.size].min
          revenue += linked_towns.first(taken_towns).sum
          town_capacity -= taken_towns
          revenue += town_capacity * 10 if town_capacity.positive?

          # Inherent Pullman bonus: +£10 × level of highest non-rusted train (§1.5)
          highest_level = entity.trains.reject(&:obsolete).map { |t| train_level(t) }.max || 0
          revenue += highest_level * 10

          revenue
        end

        # Returns the numeric level of a train name (e.g. '4+4'→4, '4D'→4, '2+2'→2, '4'→4)
        def train_level(train)
          name = train.name
          return name.to_i if name.match?(/^\d+$/)
          return Regexp.last_match(1).to_i if name.match?(/^(\d+)[+D]/)

          0
        end

        # ── Nationals: routing / terrain / token overrides ──────────────────────

        # Nationals skip the Route step entirely; revenue is calculated in national_revenue.
        def can_run_route?(entity)
          return false if national?(entity)

          super
        end

        def national?(entity)
          entity.respond_to?(:type) && entity.type == :national
        end

        # True once MAX_FLOATED_REGIONALS have been floated and the 6 remaining
        # unfloated regionals have been closed. This is the correct trigger for
        # "Major Railroad Phase" entry: conversions and secondary-share purchases
        # become available from this point on.
        def major_phase?
          return false unless @regional_corps_floated >= self.class::MAX_FLOATED_REGIONALS

          total_minors = corporations.count { |c| c.type == :minor }
          @minor_floated_regions.size >= total_minors
        end

        def fulfilled_train_obligation?(entity)
          !phase.status.include?('train_obligation') || @fulfilled_train_obligation.include?(entity.id)
        end

        def rust(train)
          super
          train.owner = @depot
        end

        def fulfill_train_obligation!(entity)
          @fulfilled_train_obligation.add(entity.id)
        end

        def non_starter_trains_available?
          major_phase? && @first_or_complete
        end

        def operating_order
          base = @minor_regional_order + @corporations.select { |c| %i[major national].include?(c.type) && c.floated? }.sort
          golden_bell = golden_bell_entity
          return base if !golden_bell || !base.include?(golden_bell)

          case @golden_bell_position
          when :first then [golden_bell] + (base - [golden_bell])
          when :last  then (base - [golden_bell]) + [golden_bell]
          else base
          end
        end

        def golden_bell_entity
          corporations.find { |c| c.id == self.class::GOLDEN_BELL_CORP_ID && c.floated? && !c.closed? }
        end

        def hex_within_national_region?(entity, hex)
          return true if entity.type == :major # §11.1.4: majors unrestricted to any zone

          region = self.class::CORPORATIONS_TRACK_RIGHTS[entity.id] || @minor_floated_regions[entity.id]
          hexes = self.class::NATIONAL_REGION_HEXES[region]
          hexes&.include?(hex.coordinates) || false
        end

        def region_for_hex(hex)
          self.class::CITY_NATIONAL_ZONE[hex.coordinates] ||
            self.class::NATIONAL_REGION_HEXES.find { |_, hexes| hexes.include?(hex.coordinates) }&.first
        end

        def region_available?(region)
          @minor_available_regions.key?(region)
        end

        def track_rights_cost(region)
          self.class::TRACK_RIGHTS_COST[region] || 0
        end

        def claim_region!(entity, region)
          @minor_floated_regions[entity.id] = region
          @minor_available_regions[region] -= 1
          @minor_available_regions.delete(region) if @minor_available_regions[region].zero?

          return unless self.class::ASTERISKED_ZONES.include?(region)

          @minor_asterisked_selected += 1
          return unless @minor_asterisked_selected >= self.class::ASTERISKED_ZONES_CAP

          self.class::ASTERISKED_ZONES.each { |z| @minor_available_regions.delete(z) }
        end

        def home_token_locations(corporation)
          available_regions = self.class::NATIONAL_REGION_HEXES.select { |key, _| @minor_available_regions.include?(key) }
          region_hexes = available_regions.values.flatten

          @hexes
            .select { |hex| region_hexes.include?(hex.coordinates) }
            .reject { |hex| (z = self.class::CITY_NATIONAL_ZONE[hex.coordinates]) && !@minor_available_regions.key?(z) }
            .select { |hex| hex.tile.cities.any? { |city| city.tokenable?(corporation, free: true) } }
            .reject { |hex| metropolis_hex?(hex) }
            .reject { |hex| self.class::MINOR_EXCLUDED_HOME_CITIES.include?(hex.coordinates) }
        end

        def metropolis_hex?(hex)
          %w[A56 B41 C74 F87 K26 M28 M50 Q30 R55 Y14 AA82 AB51].include?(hex.coordinates)
        end

        def metropolis_tile?(tile)
          %w[OE4 OE5 OE6 OE7 OE8 OE12 OE13 OE14 OE15 OE16 OE17
             OE18 OE26 OE27 OE28 OE29 OE30 OE37 OE38 OE39 OE40 OE41].include?(tile.name.to_s)
        end

        def tile_point_budget(entity)
          self.class::TILE_POINT_BUDGET[entity.type] || 0
        end

        def can_buy_train_from_others?
          major_phase?
        end

        def train_obligation_active?
          phase.status.include?('train_obligation')
        end

        def upgrade_cost(tile, hex, entity, spender)
          base_cost = tile.upgrades.sum(&:cost)
          return super if base_cost.zero?
          return 0 if entity.type == :national

          if bbe_active_for_lay?(entity, hex)
            @log << "#{(spender || entity).name} uses B&B Engineers token: no terrain cost"
            return 0
          end

          entity_zone = entity_track_rights_zone(entity)
          hex_zone = region_for_hex(hex)
          zone_match = hex_zone && entity_zone == hex_zone &&
                       self.class::ZONE_DISCOUNT_ZONES.include?(hex_zone)

          return super unless zone_match

          # §11.1.5: 20% zone discount; E/F augment to 50% when terrain matches
          ef_corp = terrain_augmented_by?(entity, tile)
          rate = ef_corp ? self.class::ZONE_TERRAIN_DISCOUNT_RATE : self.class::ZONE_DISCOUNT_RATE
          cost = (base_cost * (1 - rate)).floor
          discount = base_cost - cost
          if discount.positive?
            pct = (rate * 100).to_i
            label = ef_corp ? "#{pct}% zone+#{ef_corp.name}" : "#{pct}% zone"
            @log << "#{spender.name} receives a #{label} discount of #{format_currency(discount)}"
          end
          cost
        end

        def revenue_stops(route)
          super.flat_map { |stop| stop.town? && stop.size > 1 ? Array.new(stop.size, stop) : [stop] }
        end

        def level8_train_available?
          return false if phase.name.to_i < 7
          return true if phase.name.to_i == 8

          next_train = @depot.upcoming.first
          next_train.index >= 4 || next_train.name != '7+7'
        end

        def event_remainder_cash_added!
          return if @remainder_cash_added

          @remainder_cash_added = true
          remainder = self.class::REMAINDER_CASH
          @bank.add_cash(remainder)
          @log << "-- Event: #{format_currency(remainder)} remainder cash added to bank;" \
                  ' game ends after one more full OR set (sooner if bank breaks) --'
        end

        def assign_krasnaya_strela!(train)
          @krasnaya_strela_train = train
          @krasnaya_strela_base_distance = train.distance.map(&:dup)
          train.distance = train.distance.map do |h|
            boosted = h.dup
            if boosted['nodes'] == ['town']
              boosted['pay'] += 1
            elsif !(boosted['nodes'] & %w[city offboard]).empty?
              boosted['pay'] += 1
              boosted['visit'] += 1 if boosted['visit'] < 99
            end
            boosted
          end
          @log << "#{train.name} train receives Krasnaya Strela +1+1 marker"
        end

        def restore_krasnaya_strela!
          return unless @krasnaya_strela_train

          @krasnaya_strela_train.distance = @krasnaya_strela_base_distance
          @krasnaya_strela_train = nil
          @krasnaya_strela_base_distance = nil
        end

        def after_end_of_operating_turn(operator)
          restore_krasnaya_strela! if @krasnaya_strela_train&.owner == operator
          super
        end
        def event_d_token_phase_change!
          return unless (bonus = d_corp_hex_bonus)

          bonus.hexes.clear
          bonus.amount = self.class::D_TOKEN_PHASE5_BONUS
          @log << "-- Event: Green Junction Mercantile +£20 marker removed; +£40 marker now available --"
        end

        def assign_d_token!(hex)
          return unless (bonus = d_corp_hex_bonus)

          bonus.hexes.replace([hex.coordinates])
          @log << "Green Junction Mercantile places +#{format_currency(bonus.amount)} marker on #{hex.name}"
        end

        def discounted_upgrade?(entity)
          self.class::DISCOUNTED_UPGRADE_CORPORATIONS.include?(entity.id)
        end

        def pay_mail_contract!
          k_corp = corporations.find { |c| c.id == self.class::MAIL_CONTRACT_CORP_ID && !c.closed? }
          return unless k_corp

          amount = self.class::MAIL_CONTRACT_REVENUE[@phase.name]
          return unless amount&.positive?

          @bank.spend(amount, k_corp)
          @log << "#{k_corp.name} receives mail contract of #{format_currency(amount)}"
        end

        def cache_objects
          super
          # 18OE: minors live in @corporations, not @minors. Re-bind after base
          # cache_objects overwrites the CACHABLE define_method.
          self.class.remove_method(:minor_by_id) if self.class.method_defined?(:minor_by_id)
          self.class.define_method(:minor_by_id) do |id|
            corp = corporation_by_id(id)
            corp if corp&.type == :minor
          end
        end

        def track_rights_for(corp)
          initial_zone = self.class::CORPORATIONS_TRACK_RIGHTS[corp.id] ||
                         @minor_floated_regions[corp.id]
          zones = Array(initial_zone) + Array(@minor_track_rights[corp.id])
          zones.compact.uniq
        end

        # §10.5 merger: transfer trains, tokens, cash, and track rights from a
        # floated minor into a floated major or national, then close the minor.
        def merge_minor!(minor, major)
          @log << "#{minor.name} merges into #{major.name}"
          share_given = minor_share_exchange!(minor, major)
          minor_cash_transfer!(minor, major, share_given)
          case major.type
          when :major
            transfer_minor_tokens!(minor, major)
            transfer_minor_trains!(minor, major)
            transfer_minor_track_rights!(minor, major)
          when :national
            transfer_minor_trains!(minor, major)
          else
            raise GameError, "Unexpected merge target type: #{major.type}"
          end
          close_minor!(minor)
        end

        def minor_share_exchange!(minor, major)
          treasury_share = major.ipo_shares.reject(&:president).first
          if treasury_share
            @share_pool.transfer_shares(treasury_share.to_bundle, minor.owner,
                                        allow_president_change: false)
            @log << "#{minor.owner.name} receives treasury share of #{major.name}"
            return true
          end

          market_share = @share_pool.shares_of(major).first
          if market_share
            @share_pool.transfer_shares(market_share.to_bundle, minor.owner,
                                        allow_president_change: false)
            @log << "#{minor.owner.name} receives market share of #{major.name}"
            return false
          end

          @log << "No shares of #{major.name} available; no share exchange"
          false
        end

        def minor_cash_transfer!(minor, major, treasury_share_given)
          cash = minor.cash
          return if cash.zero?

          if treasury_share_given && major.type == :major
            minor.spend(cash, major)
            @log << "#{minor.name} transfers #{format_currency(cash)} to #{major.name}"
          else
            minor.spend(cash, @bank)
            @log << "#{minor.name} forfeits #{format_currency(cash)} to bank"
          end
        end

        def transfer_minor_tokens!(minor, major)
          changed = false
          minor.tokens.select(&:used).each do |token|
            changed = true
            city = token.city
            if city.tokened_by?(major)
              token.remove!
              @log << "#{minor.name} token removed from #{city.hex.name} (conflict with #{major.name})"
            else
              major_token = major.tokens.find { |t| !t.used }
              if major_token
                token.swap!(major_token, check_tokenable: false)
                @log << "#{minor.name} token replaced by #{major.name} at #{city.hex.name}"
              else
                token.remove!
                @log << "#{minor.name} token removed from #{city.hex.name} (no spare #{major.name} token)"
              end
            end
          end
          @graph.clear if changed
        end

        def transfer_minor_trains!(minor, major)
          limit = train_limit(major)
          minor.trains.dup.each do |train|
            if major.trains.size < limit
              train.owner = major
              major.trains << train
              minor.trains.delete(train)
              @log << "#{minor.name} transfers #{train.name} to #{major.name}"
            else
              depot.reclaim_train(train)
              @log << "#{minor.name} #{train.name} returned to depot (#{major.name} at train limit)"
            end
          end
        end

        def transfer_minor_track_rights!(minor, major)
          zone = @minor_floated_regions[minor.id]
          return unless zone

          @minor_track_rights[major.id] ||= []
          @minor_track_rights[major.id] |= [zone]
          @log << "#{major.name} gains track rights in #{zone} zone from #{minor.name}"
        end

        def close_minor!(minor)
          @minor_regional_order.delete(minor)
          @minor_floated_regions.delete(minor.id)
          close_corporation(minor, quiet: true)
          @log << "#{minor.name} closed"
        end

        def abandon_minor!(minor)
          minor.trains.dup.each { |train| @depot.reclaim_train(train) }
          @minor_regional_order.delete(minor)
          @minor_floated_regions.delete(minor.id)
          close_corporation(minor, quiet: true)
          @log << "#{minor.name} abandoned"
        end

        def force_abandon_surviving_minors!
          @players.each do |player|
            minors = player.shares.filter_map(&:corporation)
                           .select { |c| c.type == :minor }
                           .uniq
            minors.each do |minor|
              @log << "#{player.name}: #{minor.name} not consolidated — force abandoned"
              abandon_minor!(minor)
            end

            regionals = player.shares.filter_map(&:corporation)
                              .select { |c| c.type == :regional }
                              .uniq
            regionals.each do |reg|
              @log << "#{player.name}: #{reg.name} not converted — see BUG-046"
            end
          end
        end

        # UP movement at end of SR: only for majors and nationals that are fully player-held
        def sold_out_increase?(corporation)
          %i[major national].include?(corporation.type)
        end

        def event_consolidation_triggered!
          @consolidation_triggered = true
          @log << '-- Event: Consolidation phase triggered --'
        end

        def sell_shares_and_change_price(bundle, allow_president_change: true, swap: nil, movement: nil)
          if @bbbt_protected_corp == bundle.corporation
            movement = :none
            @log << "#{bundle.corporation.name} share price DROP blocked by Barclay, Bevan, Barclay and Tritton"
          end
          super
        end

        def next_round!
          finish_bbbt_sr! if @round.is_a?(Engine::Round::Stock) && @bbbt_protected_corp
          @round =
            case @round
            when Engine::Round::Operating
              @first_or_complete = true # Rule 8.3/11.6: level 3+ trains unblocked after first OR
              if @round.round_num < @operating_rounds
                or_round_finished
                new_operating_round(@round.round_num + 1)
              elsif @consolidation_triggered && !@consolidation_complete
                @turn += 1
                or_round_finished
                or_set_finished
                @log << '-- Consolidation Phase --'
                new_consolidation_round
              else
                @turn += 1
                or_round_finished
                or_set_finished
                new_stock_round
              end
            when Round::G18OE::Consolidation
              force_abandon_surviving_minors!
              @consolidation_complete = true
              @turn += 1
              new_stock_round
            else
              super
            end
        end

        def new_consolidation_round
          Round::G18OE::Consolidation.new(self, [
            G18OE::Step::Consolidate,
          ])
        end

        def upgrades_to_correct_label?(from, to)
          chain = self.class::METROPOLIS_UPGRADE_CHAINS[from.hex&.coordinates]
          return (chain[chain.find_index(from.name) + 1] == to.name) if chain&.include?(from.name)

          super
        end

        def company_becomes_minor?(company)
          corp = @corporations.find { |c| c.name == company.sym }
          return false unless corp

          corp.type == :minor
        end

        def form_button_text(_entity)
          'Float'
        end

        def after_par(corporation)
          super
          # Spend the track rights zone fee when a regional pars.
          # Zones not yet in TRACK_RIGHTS_COST (or not in NATIONAL_REGION_HEXES) are skipped safely.
          region = CORPORATIONS_TRACK_RIGHTS[corporation.id]
          cost = TRACK_RIGHTS_COST[region]
          corporation.spend(cost, @bank) if cost&.positive?
        end

        def add_new_share(share)
          owner = share.owner
          corporation = share.corporation
          corporation.share_holders[owner] += share.percent if owner
          owner.shares_by_corporation[corporation] << share
          @_shares[share.id] = share
        end

        def issuable_shares(entity)
          return [] if !entity.corporation? || entity.type != :major

          bundles_for_corporation(entity, entity)
            .select { |bundle| @share_pool.fit_in_bank?(bundle) }
        end

        def redeemable_shares(entity)
          return [] if !entity.corporation? || entity.type != :major

          bundles_for_corporation(@share_pool, entity)
            .reject { |bundle| entity.cash < bundle.price }
        end

        def value_for_dumpable(player, corporation)
          return 0 if corporation.type == :regional

          super
        end

        def stock_round
          Engine::Round::Stock.new(self, [
            Engine::Step::DiscardTrain,
            G18OE::Step::HomeToken,
            G18OE::Step::BuySellParShares,
          ])
        end

        def new_auction_round
          Round::Auction.new(self, [
            G18OE::Step::WaterfallAuction,
          ])
        end

        def setup_cctc_revenue!(corp, hex)
          return unless corp.corporation?

          amount = self.class::CCTC_TOWN_REVENUE[@phase.name]
          corp.add_ability(Engine::Ability::HexBonus.new(
            type: :hex_bonus,
            hexes: [hex.coordinates],
            amount: amount,
            owner_type: :corporation,
          ))
          @cctc_corp = corp
          @cctc_hex = hex
          @log << "#{corp.name} receives CCTC revenue bonus: +#{format_currency(amount)} when routing through " \
                  "#{hex.name} (#{hex.location_name})"
          # TODO: CCTC hex should count as a town stop (not city) for routing purposes (§14.6).
          # Requires routing-graph change; hex_bonus approximation in place. See BUG-032.
        end

        def after_phase_change(name)
          super
          update_cctc_revenue!
        end

        def operating_round(round_num)
          Round::G18OE::Operating.new(self, [
            G18OE::Step::GoldenBellChoice,
            Engine::Step::Bankrupt,
            Engine::Step::Exchange,
            Engine::Step::DiscardTrain,
            Engine::Step::HomeToken,
            G18OE::Step::Track,
            G18OE::Step::DTokenPlacement,
            G18OE::Step::HochbergPlacement,
            G18OE::Step::Token,
            G18OE::Step::KrasnayaStrelaAssign,
            Engine::Step::Route,
            G18OE::Step::Dividend,
            G18OE::Step::BuyTrain,
            G18OE::Step::ConvertToNational,
            G18OE::Step::IssueShares,
          ], round_num: round_num)
        end

        def d_token_available?(entity)
          bonus = entity.all_abilities.find { |a| a.type == :hex_bonus }
          bonus&.hexes&.empty?
        end

        def valid_d_token_hex?(hex)
          !metropolis_hex?(hex) && hex.tile.color != :red && !hex.tile.cities.empty?
        end

        def hochberg_eligible_hex?(hex)
          hex.tile.upgrades.any? { |u| u.terrain && u.cost >= self.class::HMLC_MIN_TERRAIN_COST }
        end

        def check_route_token(route, token)
          super
          check_hochberg_exclusion!(route)
          check_bbe_exclusion!(route)
        end

        def num_corp_trains(entity)
          trains = entity.trains.reject { |t| @sml_trains.include?(t) }
          self.class::OBSOLETE_TRAINS_COUNT_FOR_LIMIT ? trains.size : trains.count { |t| !t.obsolete }
        end

        def can_claim_sml?(player)
          return false if @sml_claimed
          return false unless @phase.status.include?('sml_available')

          sml = company_by_id(self.class::SML_COMPANY_SYM)
          return false unless sml&.owner == player
          return false if sml_claimable_corps(player).empty?

          @depot.trains.any? { |t| t.rusted && t.owner == @depot && t.name == self.class::SML_TRAIN_NAME }
        end

        def sml_claimable_corps(player)
          corporations.select { |c| c.floated? && c.president?(player) }
        end

        def sml_train?(train)
          @sml_trains.include?(train)
        end

        def claim_sml_train!(corp)
          train = @depot.trains.find { |t| t.rusted && t.owner == @depot && t.name == self.class::SML_TRAIN_NAME }
          return unless train

          corp.trains << train
          train.owner = corp
          train.buyable = false
          @sml_trains << train
          @sml_claimed = true
          sml_name = company_by_id(self.class::SML_COMPANY_SYM)&.name || 'Swift Metropolitan Line'
          @log << "#{corp.name} receives a preserved #{train.name} train via #{sml_name} " \
                  '(outside train limit; cannot be sold)'
        end

        def bbe_active_for_lay?(entity, hex)
          return false unless entity.respond_to?(:companies)

          bbe = company_by_id(self.class::BBE_COMPANY_SYM)
          return false unless bbe&.owner == entity

          ability = abilities(bbe, :tile_lay, time: 'track')
          return false unless ability

          !hex.tile.terrain.empty?
        end

        def mark_bbe_hex!(hex, corp)
          @bbe_hexes[hex.id] = corp
          bbe_name = company_by_id(self.class::BBE_COMPANY_SYM)&.name || 'B&B Engineers'
          @log << "#{corp.name} places a #{bbe_name} token on #{hex.name} (#{hex.location_name}): "\
                  'only this RR may route here'
        end

        def can_use_bbbt_option3?(player)
          return false unless @round&.stock?

          bbbt = company_by_id(self.class::BBBT_COMPANY_SYM)
          return false unless bbbt&.owner == player
          return false if @bbbt_protected_corp

          corporations.any? { |c| c.share_price }
        end

        def bbbt_protectable_corps
          corporations.select { |c| c.share_price }
        end

        def bbbt_protect!(corp, player)
          @bbbt_protected_corp = corp
          bbbt_name = company_by_id(self.class::BBBT_COMPANY_SYM)&.name || 'Barclay, Bevan, Barclay and Tritton'
          @log << "#{player.name} uses #{bbbt_name}: #{corp.name} share price protected from DROP "\
                  'for the remainder of this SR'
        end

        private

        def update_cctc_revenue!
          return if !@cctc_corp || !@cctc_hex

          bonus = @cctc_corp.all_abilities.find do |a|
            a.type == :hex_bonus && a.hexes.include?(@cctc_hex.coordinates)
          end
          return unless bonus

          amount = self.class::CCTC_TOWN_REVENUE[@phase.name]
          bonus.amount = amount
          @log << "#{@cctc_corp.name} CCTC revenue updated to #{format_currency(amount)} (Phase #{@phase.name})"
        end

        def check_hochberg_exclusion!(route)
          hmlc = companies.find { |c| c.sym == self.class::HMLC_COMPANY_SYM }
          return unless hmlc

          hochberg_hexes = abilities(hmlc, :assign_hexes)&.hexes
          return if hochberg_hexes.nil? || hochberg_hexes.empty?

          routing_corp = route.train.owner
          hmlc_owner = hmlc.owner
          hmlc_owner_player = hmlc_owner.is_a?(Player) ? hmlc_owner : hmlc_owner&.owner
          return if hmlc_owner_player && routing_corp.player == hmlc_owner_player

          route.hexes.each do |hex|
            next unless hochberg_hexes.include?(hex.coordinates)

            raise GameError, "#{routing_corp.name} cannot route through Hochberg-marked hex #{hex.name}"
          end
        end

        def finish_bbbt_sr!
          @bbbt_protected_corp = nil
          bbbt = company_by_id(self.class::BBBT_COMPANY_SYM)
          return unless bbbt && !bbbt.closed?

          company_closing_after_using_ability(bbbt)
          bbbt.close!
          @log << "#{bbbt.name} closes (option 3 exercised this SR)"
        end

        def check_bbe_exclusion!(route)
          return if @bbe_hexes.empty?

          routing_corp = route.train.owner

          route.hexes.each do |hex|
            next unless (owner_corp = @bbe_hexes[hex.id])
            next if owner_corp == routing_corp

            raise GameError,
                  "#{routing_corp.name} cannot route through B&B Engineers-marked hex #{hex.name}"
          end
        end

        def d_corp_hex_bonus
          d_corp = corporations.find { |c| c.id == self.class::D_TOKEN_CORP_ID && !c.closed? }
          return unless d_corp

          d_corp.all_abilities.find { |a| a.type == :hex_bonus }
        end

        def entity_track_rights_zone(entity)
          corp = owning_corporation(entity)
          return nil unless corp

          self.class::CORPORATIONS_TRACK_RIGHTS[corp.id] || @minor_floated_regions[corp.id]
        end

        def terrain_augmented_by?(entity, tile)
          corp = owning_corporation(entity)
          return nil unless corp

          terrain = self.class::EF_TERRAIN_AUGMENT[corp.id]
          terrain && tile.terrain.include?(terrain) ? corp : nil
        end

        def owning_corporation(entity)
          resolved = entity.corporation? ? entity : entity.owner
          resolved&.corporation? ? resolved : nil
        end

        def resolve_corporation(entity)
          resolved = entity.corporation? ? entity : entity.owner
          resolved&.corporation? ? resolved : nil
        end
      end
    end
  end
end
