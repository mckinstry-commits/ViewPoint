SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRProcessRateBased]
/***********************************************************
* CREATED BY: 	GG  02/16/1998
* MODIFIED BY:	GG  04/18/1998
*               GG	01/12/2000	- Fixed rounding errors in eligible amount calculations
*				GG	01/23/2002	- #15986 fix limit check
*				EN	10/09/2002	- issue 18877 change double quotes to single
*				EN	03/24/2003	- issue 11030 rate of earnings liability limit
*				EN	03/16/2005	- issue 27287 return @calcbasis (elig amt) even IF @calcamt = 0
*				GG	05/09/2005	- #28381 - alter subject and calculated basis limit checks
*				CHS	05/04/2011	- #141353 D-01067 fixed for negative earnings
*
* USAGE:
* Calculates Rate based deductions and liabilities (e.g. Rate per Day, Factored rate per Hour, Rate of Gross
* Rate per Hour, or Rate of a Dedn).
* Called from various bspPRProcess procedures.
*
* INPUT PARAMETERS
*  	@calcbasis	        calculation basis - may be Earnings, Hours, Days, etc.
*  	@rate    		    effective rate
*  	@limitbasis	        basis to apply limit - 'N' none, 'S' subject amount, 'C' calculated amount
*  	@limitamt	        limit amount
*  	@ytdcorrect	        use year-to-date accums to correct for rounding errors - 'Y' or 'N'
*  	@limitcorrect	    correct calculated amount IF limit exceeded - 'Y' or 'N'
*  	@accumelig	        accumulated eligible amount based on limit period
*  	@accumsubj 	        accumulated subject amount based on limit period
*  	@accumamt	        accumulated DL amount based on limit period
*  	@ytdelig	        year-to-date eligible amount
*  	@ytdactual	        year-to-date DL amount
*	@accumbasis			used with @calcbasis to calculate basis amount for rate of earnings limit (includes subject-only earnings)
*  	@limitrate			limit rate used for rate of earnings limit
*
* OUTPUT PARAMETERS
*	@accumbasis	accum basis may be adjusted for liabilities with rate of earnings limit
*  	@calcamt	calculated DL amount
*  	@eligamt	eligible amount
*  	@errmsg	error message
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@calcbasis bDollar, @rate bUnitCost, @limitbasis CHAR(1), @limitamt bDollar, @ytdcorrect CHAR(1),
	@limitcorrect CHAR(1), @accumelig bDollar, @accumsubj bDollar, @accumamt bDollar, @ytdelig bDollar,
	@ytdactual bDollar, @accumbasis bDollar, @limitrate bRate, @outaccumbasis bDollar OUTPUT,
	@calcamt bDollar OUTPUT, @eligamt bDollar OUTPUT, @errmsg VARCHAR(255) OUTPUT
   	 
    AS
    SET NOCOUNT ON
    
   
    DECLARE @rcode INT, @accurcalc FLOAT, @subjonlybasis bDollar
   
    SELECT @rcode = 0, @calcamt = 0.00, @eligamt = 0.00, @accurcalc = 0.00, @subjonlybasis = 0.00
   
    SELECT @outaccumbasis = @accumbasis --issue 11030 init output accum basis value
   
    --issue 11030  rate of earnings limit
    IF @limitbasis = 'R'	-- Rate of Earnings Limit
   		BEGIN
   		SELECT @subjonlybasis = @accumbasis - @calcbasis	-- basis for this limit is based on 'subject-only' earnings
   		IF @subjonlybasis = 0.00	-- set eligible and calculated amounts to 0.00 IF no basis amount
   			BEGIN
   			SELECT @eligamt = 0.00, @calcamt = 0.00
   			GOTO bspexit
   			END
   		SELECT @eligamt = @calcbasis	-- eligible amount is first based on basis earnings
   		SELECT @calcamt = @eligamt * @rate
   		SELECT @outaccumbasis = @eligamt
   		IF @subjonlybasis * @limitrate < @calcamt	-- then is limited to rate of earnings
   			BEGIN
   			SELECT @calcamt = @subjonlybasis * @limitrate
   			SELECT @eligamt = @calcamt / @rate
   			END
	   		
   		GOTO bspexit
		END
   
   
    IF @calcbasis = 0.00   	-- set eligible and calculated amounts to 0.00 IF no basis amount
    	BEGIN
    	SELECT @eligamt = 0.00, @calcamt = 0.00
    	GOTO bspexit
    	END
   
    IF @limitbasis = 'N'	-- No Limit - calculated the same for positive and negative basis amounts
    	BEGIN
    	SELECT @eligamt = @calcbasis
        SELECT @calcamt = @calcbasis * @rate
        -- year-to-date corrections use current rate - should not be used unless rate
        -- remains unchanged throughout the year
    	IF  @ytdcorrect = 'Y' SELECT @calcamt = ((@ytdelig + @eligamt) * @rate) - @ytdactual
    	END
   
    IF @limitbasis = 'S'	-- Subject Amount Limit
    	BEGIN    	
    	
    	-- #141353 when the user insert a negtive earnings amount (@calcbasis) but were are still over the limit 
    	--			amount, then we will set the @eligamt = 0 and @calcamt = 0    	
    	IF (@calcbasis < 0) AND (@accumsubj >= @limitamt)
    		BEGIN
    		SELECT @eligamt = 0, @calcamt = 0
    		END
    		
    	-- #141353 function as before IF @calcbasis >= 0
		ELSE   
			BEGIN 		
    		SELECT @eligamt = @calcbasis
	    	
    		-- #28381 apply 'normal' limit check IF the sign on basis and limit are equal, removed #15986 and incorporated #27287
    		IF (@calcbasis >=0 and @limitamt > 0) or (@calcbasis < 0 and @limitamt < 0)	-- 
   				BEGIN
    			IF abs(@accumelig + @eligamt) > abs(@limitamt)
    				BEGIN
    				SELECT @eligamt = @limitamt - @accumelig
    				IF @limitcorrect = 'N'
   						BEGIN
   						IF @limitamt > 0 and @eligamt < 0.00 SELECT @eligamt = 0.00
   						IF @limitamt < 0 and @eligamt > 0.00 SELECT @eligamt = 0.00
   						END
    				END
    			END
	    		
			-- #28381 apply 'correcting' limit check IF the sign on rate and limit differ, removed #15986 
			ELSE	
    			BEGIN
    			IF abs(@accumsubj) >= abs(@limitamt)
    				BEGIN
    				SELECT @eligamt = @accumsubj + @calcbasis - @limitamt
    				IF @limitamt > 0 and @eligamt > 0.00 SELECT @eligamt = 0.00
					IF @limitamt < 0 and @eligamt < 0.00 SELECT @eligamt = 0.00
    				END
    			END
	    		
    		-- calculate DL amount
    		SELECT @calcamt = @eligamt * @rate
    		IF  @ytdcorrect = 'Y' SELECT @calcamt = ((@ytdelig + @eligamt) * @rate) - @ytdactual
	    	    		
    		END    	
    	
    	END
    	
   
    IF @limitbasis = 'C'	-- Calculated Amount Limit
    	BEGIN

    	-- #141353 when the user insert a negtive earnings amount (@calcbasis) but were are still over the limit 
    	--			amount, then we will set the @eligamt = 0 and @calcamt = 0     	
		IF (@calcbasis < 0) AND (@accumamt >= @limitamt)
    		BEGIN
    		SELECT @eligamt = 0, @calcamt = 0
    		END
    		
    	-- #141353 function as before IF @calcbasis >= 0
		ELSE 
			BEGIN
			-- #28381 apply 'normal' limit check IF the sign on basis times rate equals limit, removed #15986 
			IF ((@calcbasis * @rate) > 0.00 and @limitamt > 0) or ((@calcbasis * @rate) < 0 and @limitamt < 0)		
				BEGIN
				SELECT @accurcalc = @calcbasis * @rate  -- use variable with greater percision
				SELECT @calcamt = @accurcalc
	   
    			IF abs(@accumamt + @calcamt) > abs(@limitamt)
					BEGIN
					SELECT @calcamt = @limitamt - @accumamt
					IF @limitcorrect = 'N'
						BEGIN
						IF @limitamt > 0 and @calcamt < 0.00 SELECT @calcamt = 0.00
						IF @limitamt < 0 and @calcamt > 0.00 SELECT @calcamt = 0.00
						END
						
					SELECT @accurcalc = @calcamt    -- reduced because limit has been met or exceeded
					END
					
				-- calculate eligible amount
				SELECT @eligamt = 0.00
				IF @rate <> 0.00 SELECT @eligamt = @accurcalc / @rate -- use greater percision to avoid rounding errors
				END
	            
			-- #28381 apply 'correcting' limit check IF the sign on basis times rate differs from limit, removed #15986 
			ELSE
    			BEGIN
    			IF abs(@accumamt) < abs(@limitamt)
    				BEGIN
    				SELECT @eligamt = @calcbasis
    				END
	    			
    			ELSE
    				BEGIN    -- over the limit, use inferred subject limit
   					IF @rate <> 0
   						BEGIN 
   						SELECT @eligamt = (@accumsubj + @calcbasis) - (@limitamt / @rate)
    					IF (@limitamt / @rate) > 0 and @eligamt > 0.00 SELECT @eligamt = 0.00
   						IF (@limitamt / @rate) < 0 and @eligamt < 0.00 SELECT @eligamt = 0.00
   						END
	   					
    				END
				
				SELECT @calcamt = @eligamt * @rate
				END
					
			IF  @ytdcorrect = 'Y' SELECT @calcamt = ((@ytdelig + @eligamt) * @rate) - @ytdactual
			END			
			
			
		END
    	
    	

   
    bspexit:
    	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessRateBased] TO [public]
GO
