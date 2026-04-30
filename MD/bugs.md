● Here are the findings before any fixes:                                                                                             
                                                                                                                                      
  ---                                                                                                                                 
  Phase transition — no bug                                                                                                           
                                                                                                                                      
  major_phase? correctly requires both @regional_corps_floated >= 18 AND all minors having placed home tokens                         
  (@minor_floated_regions.size >= total_minors). close_corporation removes from @corporations, so the ratio stays correct if a minor  
  is abandoned. process_par properly closes the 6 remaining unfloated regionals and calls pass! on the 18th par.
                                                                                                                                      
  ---                                                   
  Bug 1 — can_buy? blocks non-presidents from buying secondary shares in Major Phase (HIGH)
                                                                                                                                      
  buy_sell_par_shares.rb:60–72:
                                                                                                                                      
  if !@converted && bundle.corporation.type == :regional &&
     bundle.corporation.ipoed && bundle.owner == bundle.corporation                                                                   
    return false unless bundle.corporation.president?(entity)  # ← too broad
                                                                                                                                      
  §8.3 says "Secondary shares of regionals are available" in Major Phase — no president restriction. The guard is meant to enforce    
  §9.3 step 1 (only the president may buy one share before converting). But !@converted fires in both the @converting state AND normal
   Major Phase. In normal Major Phase, a non-president can never buy secondary shares of an unConverted regional.                     
                                                        
  Fix: replace !@converted && bundle.corporation.type == :regional && bundle.corporation.ipoed && bundle.owner == bundle.corporation  
  with @converting == bundle.corporation.
                                                                                                                                      
  ---                                                   
  Bug 2 — @bought ivar removed but still referenced; pre-conversion double-buy not blocked (HIGH)
                                                                                                                                      
  buy_sell_par_shares.rb:68:
                                                                                                                                      
  return false if @bought == bundle.corporation         

  @bought was removed in the bought_corporation refactor. It's always nil, so this check never fires. A president can buy multiple    
  treasury shares before triggering conversion, violating §9.3 step 1 ("the player may purchase one share").
                                                                                                                                      
  Fix: @bought == bundle.corporation → bought_corporation == bundle.corporation.

  ---
  Bug 3 — Post-conversion sell window skipped when player is already president (MEDIUM)
                                                                                                                                      
  buy_sell_par_shares.rb:267–273:
                                                                                                                                      
  def pass!                                             
    complete_conversion if @converting   # sets @converted
    raise GameError, "..." if @converted && !@converted.president?                                                                    
    super   # ← always ends the turn if no error
  end                                                                                                                                 
                                                        
  §9.3 (after step 2, the expand): "Optional — the active player may sell any number of shares of any RR they already own (not the    
  newly floated major)." When the player is already the president, pass! calls complete_conversion then super immediately — turn ends.
   The sell window and the optional post-conversion share purchase (step 5) are never offered.                                        
                                                        
  Fix: after complete_conversion, return instead of falling through to super. A second pass (with @converting nil and @converted set) 
  calls super to end the turn.
                                                                                                                                      
  ---                                                   
  Bug 4 — can_sell? blocks ALL regional share selling including in Major Phase (MEDIUM, needs rule verification)

  return false if bundle.corporation.type == :regional
                                                                                                                                      
  In Major Phase, secondary shares can be bought. They should be sellable too. This also means the §9.3 post-conversion sell window   
  can never include other regionals' secondary shares. Intent was probably to prevent president-share dumps but the block is too      
  broad. Needs confirmation that §10 doesn't explicitly prohibit selling regional shares before fixing.                               
                                                        
  ---
  Ready to proceed with fixes for Bugs 1–3 immediately (clearly rule-backed), and Bug 4 once you confirm selling regional secondary
  shares is allowed.                                                                                                                  
   
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
 Ready to code?                                                                           

 Here is Claude's plan:                                                                                                               
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
 Plan: Phase Transition & Share-Buying Bug Audit                                                                                      
                                                        
 Context

 Audit of §5.1/5.2 (RR phases), §8.2/8.3/8.4 (Regional/Minor and Major RR Phase rules),
 and §9.3 (floating a major by conversion) against the current implementation in:
 - lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb
 - lib/engine/game/g_18_oe/game.rb (major_phase?)

 Note: setup is called per-player-turn (base BuySellParShares#setup resets
 @round.current_actions; the 18OE override resets @converting, @converted, @sold).
 All instance-variable bugs below are therefore scoped to the active player's turn.

 ---
 FINDING 1 — can_buy? blocks non-presidents from buying secondary shares in Major Phase  [HIGH]

 Rule §8.3: "Secondary shares of regionals are available [in the Major RR Phase]." No
 president-only restriction on general secondary share purchases.

 Code buy_sell_par_shares.rb:60–72:
 def can_buy?(entity, bundle)
   return false if @converted && bundle.corporation != @converted

   if !@converted && bundle.corporation.type == :regional &&
      bundle.corporation.ipoed && bundle.owner == bundle.corporation
     return false unless bundle.corporation.president?(entity)   # <-- too broad
     return false if @bought == bundle.corporation
   end
   super
 end

 The !@converted condition matches BOTH:
 - @converting state (pre-conversion §9.3 step 1 — president-only is correct), AND
 - Normal Major Phase (no conversion in progress — president-only is WRONG)

 When @converting is nil and a non-president player tries to buy a secondary share of
 an unConverted regional from its IPO in Major Phase, the check fires and blocks them.

 Fix: Scope the restriction to the pre-conversion state only — replace
 !@converted && bundle.corporation.type == :regional && bundle.corporation.ipoed && bundle.owner == bundle.corporation
 with @converting == bundle.corporation.

 ---
 FINDING 2 — @bought ivar removed but still referenced; pre-conversion double-buy not blocked  [HIGH]

 Rule §9.3 step 1: "the player may purchase ONE share prior to step 2."

 Code buy_sell_par_shares.rb:68:
 return false if @bought == bundle.corporation

 @bought was removed in the bought_corporation refactor (commit doc says
 "@bought ivar removed in favour of bought_corporation helper"). @bought is never
 set anywhere; it is always nil. nil == corporation is always false → the one-share
 limit is never enforced. A president can buy multiple treasury shares before converting.

 Fix: Replace @bought with bought_corporation:
 return false if bought_corporation == bundle.corporation

 ---
 FINDING 3 — Post-conversion sell window skipped when player is already president  [MEDIUM]

 Rule §9.3 (after step 2/expand): "Optional — the active player may sell any number
 of shares of any RR they already own (this player may not sell shares of the newly
 floated major)." This sell window exists regardless of whether the converter was
 already the president.

 Code buy_sell_par_shares.rb:267–273:
 def pass!
   complete_conversion if @converting    # sets @converted, clears @converting
   raise GameError, "..." if @converted && !@converted.president?(current_entity)
   super                                  # always reached if no error → ends turn immediately
 end

 When the player IS already president of the converting regional:
 1. complete_conversion runs → @converted set
 2. @converted.president?(current_entity) → true → no error
 3. super → turn ends

 The player never gets the post-conversion action window (sell other RRs, optional buy).

 Fix: After complete_conversion, return instead of falling through to super.
 Let the player take post-conversion actions; only the second pass (when @converting
 is nil and @converted is set) calls super to end the turn.

 def pass!
   if @converting
     complete_conversion
     raise GameError, "..." if @converted && !@converted.president?(current_entity)
     return   # stay in player's turn for post-conversion actions
   end
   raise GameError, "..." if @converted && !@converted.president?(current_entity)
   super
 end

 ---
 FINDING 4 — can_sell? blocks ALL regional share selling including in Major Phase  [MEDIUM/needs verification]

 Rule §8.3 makes secondary shares AVAILABLE; §9.3 post-conversion sell window
 explicitly allows selling shares of OTHER RRs (which can be regionals with secondary
 shares). No rule text found explicitly prohibiting selling regional secondary shares.

 Code buy_sell_par_shares.rb:74–80:
 def can_sell?(entity, bundle)
   return false unless bundle
   return false if bundle.corporation.type == :regional   # blocks ALL regional sells
   return false if bundle.corporation == @converted
   super
 end

 This blanket block prevents:
 - Selling secondary shares acquired in Major Phase
 - Selling other regionals' shares during the §9.3 post-conversion sell window

 The intent seems to be preventing president-share dumps (sensible), but the block is
 too broad — it should allow secondary (non-president) shares to be sold in Major Phase.

 Proposed fix: Allow non-president regional share sales in Major Phase:
 return false if bundle.corporation.type == :regional &&
                 (bundle.presidents_share? || !@game.major_phase?)
 (Block president regional shares always; block ALL regional shares in Regional/Minor Phase;
 allow secondary regional shares in Major Phase.)

 Needs rule confirmation before fixing — verify §10 contains no explicit prohibition.

 ---
 FINDING 5 — Phase transition gate: correct  [NO BUG]

 major_phase? (game.rb:811–816):
 def major_phase?
   return false unless @regional_corps_floated >= MAX_FLOATED_REGIONALS  # 18
   total_minors = corporations.count { |c| c.type == :minor }
   @minor_floated_regions.size >= total_minors
 end

 - close_corporation removes corps from @corporations, so total_minors shrinks
 when minors are merged/abandoned → ratio stays correct.
 - process_par correctly closes 6 unfloated regionals and calls pass! on 18th par.
 - Both conditions (18 regionals + all minors with home tokens) must be true before
 Major Phase begins → matches rule §5.1.3.

 No fix needed.

 ---
 FINDING 6 — can_buy_any_from_ipo? gating: correct  [NO BUG]

 def can_buy_any_from_ipo?(entity)
   return false unless @game.major_phase?
   super
 end

 Correctly blocks all secondary-share purchases (from IPO) during Regional/Minor Phase
 and opens them when Major Phase begins. Aligns with §8.3.

 No fix needed.

 ---
 Files to Modify

 ┌─────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
 │                        File                         │                                  Change                                  │
 ├─────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
 │ lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb │ Fix F1 (can_buy? scope), F2 (@bought→bought_corporation), F3 (pass! sell │
 │                                                     │  window)                                                                 │
 ├─────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
 │ lib/engine/game/g_18_oe/step/buy_sell_par_shares.rb │ Fix F4 (can_sell? regional — after rule verification)                    │
 └─────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘

 ---
 Verification

 After fixes:
 1. Start a 3-player game, auction all minors + several regionals
 2. Float all 12 minors and 18 regionals → confirm major_phase? becomes true
 3. Non-president player buys a secondary share of a regional → should succeed (F1)
 4. President triggers conversion, tries to buy two treasury shares → second should be blocked (F2)
 5. President triggers conversion, passes → conversion completes, sell window offered → player can sell
 other RRs' shares → player passes again → turn ends (F3)
 6. Player buys secondary share of regional, later tries to sell it → should succeed (F4, after verification)
