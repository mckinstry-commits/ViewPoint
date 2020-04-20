SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspSLWIRetgPctUpdate    Script Date: 8/28/99 9:36:38 AM ******/
CREATE proc [dbo].[vspSLWIRetgPctUpdate]      
/***********************************************************
* CREATED BY: DC	2/15/10 - SL - Handle max retainage
* MODIFIED By : GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*
*
*
* USAGE:
* Called from SL Worksheet to set the amount of retainage
*		to be withheld for a subcontract
*
*
*  INPUT PARAMETERS
*	@slco		Current SL Co#
*	@sl		Subcontract to add
*
* OUTPUT PARAMETERS
*		@maxretgamt maximum amount of retainage that can be withheld on the subcontract
*   	@msg     	error message if error occurs
*
* RETURN VALUE
*   	0         	success
*   	1         	failure
*****************************************************/   
	(@slco bCompany, @sl VARCHAR(30), @msg varchar(255) output)
	as
	set nocount on
		
	DECLARE @retgamtwithheld bDollar, @rc int, @slwiretgamt bDollar, @totalretamt bDollar,
			@maxretgamt bDollar, @amounttobewithheld bDollar, @diststyle char(1),
			@wccost bDollar,
			@slwiwcretamt bDollar, @slinvoice bDollar, @slwiwcpct bPct

	DECLARE @iNextRowIdItem int,		--Used to loop through Subcontracts Items
		@iCurrentRowIdItem int,		--Used to loop through Subcontracts Items 
		@iLoopControlItem int		--Used to loop through Subcontracts Items	     	          

	SELECT @rc = 0

	IF @slco is null
		BEGIN
		SELECT @msg = 'Missing SL Company.', @rc = 1
		GOTO vspExit
		END
	IF @sl is null
		BEGIN
		SELECT @msg = 'Missing Subcontract.', @rc = 1
		GOTO vspExit
		END

	--Find out what has been set as the maximum amount to be withheld from the subcontract header
	EXEC @rc = vspSLMaxRetgAmt @slco, @sl , @maxretgamt output, @msg output
	--If @maxretgamt = 0 then no max retainage amount has been setup for the subcontract.
	IF @maxretgamt = 0 
		BEGIN
		SELECT @msg = 'Maximum Retainage limits have not been set on this subcontract.', @rc = 0
		GOTO vspExit
		END
		
	--Get Distribution Style from SLHD
	SELECT @diststyle = MaxRetgDistStyle
	FROM bSLHD with (nolock)
	WHERE SLCo = @slco and @sl = SL
		
	--Find out what has already been withheld	
	EXEC @rc = vspSLRetgWithheld @slco, @sl, @retgamtwithheld output, @msg output
	--if we have already passed the max retainage amount setup then set WCRetPct and WCRetAmt = 0
	IF @retgamtwithheld >= @maxretgamt
		BEGIN
		UPDATE bSLWI
		SET WCRetPct = 0, WCRetAmt = 0
		WHERE SLCo = @slco and SL = @sl
		SELECT @rc = 0
		GOTO vspExit
		END
	
	--Find out what is defaulted into SLWorksheet to be withheld
	SELECT @slwiretgamt = sum(isnull(w.WCRetAmt,0))
	FROM bSLWI w with (nolock)
		join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0	
	WHERE w.SLCo = @slco and w.SL = @sl
	GROUP BY w.SLCo, w.SL

	--Add what has been withheld to what is defaulted to be withheld
	SELECT @totalretamt = @slwiretgamt + @retgamtwithheld
	
	--If the totalretamt is less then the maxretgamt then exit
	IF @totalretamt <= @maxretgamt 
		BEGIN
		SELECT @rc = 0
		GOTO vspExit
		END

	--If totalretamt is greater then the maxretgamt, then we have a problem
	IF @totalretamt > @maxretgamt 
		BEGIN
		--get the amount left to be withheld by withheld - maxretgamt
		SELECT @amounttobewithheld = @maxretgamt - @retgamtwithheld 
		
		--distribute the amount remaining for retainage to SLWI items
		--If MaxRetgDistStyle = C then spread the remaining retainage amount equally
		IF @diststyle = 'C' 
			BEGIN
			
			SELECT @slinvoice = sum(isnull(w.WCCost,0))
			FROM bSLWI w with (nolock)
				join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0
			WHERE w.SLCo = @slco and w.SL = @sl
			GROUP BY w.SLCo, w.SL
			
			SELECT @slwiwcpct = @amounttobewithheld/ @slinvoice
								
			--loop through all SL Items setting the WCRetAmt and the WCRetPct			
			SELECT @iLoopControlItem = 0 
			 
			--Get keyid to loop through bSLWI table   			  		   						
			SELECT @iNextRowIdItem = MIN(w.KeyID)
			FROM   bSLWI w with (nolock)
				join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0			
			WHERE w.SLCo = @slco and w.SL = @sl and w.WCCost <> 0
			
			IF ISNULL(@iNextRowIdItem,0) = 0
				--no SLWI records for the subcontract.
				BEGIN		
				SELECT @msg = 'No Item(s) initialized into the worksheet.', @rc = 0, @iLoopControlItem = 1	  
				GOTO vspExit			
				END	
				
			WHILE @iLoopControlItem = 0  -- start the main (header) processing loop.
				BEGIN
								
				--Get info from the first record in SLWI
				SELECT @iCurrentRowIdItem = KeyID, @wccost = WCCost
				FROM bSLWI
				WHERE KeyID = @iNextRowIdItem
								
				--update SLWI, set the WCRetPct and WCRetAmt
				UPDATE bSLWI
				Set WCRetAmt = @wccost * @slwiwcpct, WCRetPct = @slwiwcpct
				WHERE KeyID = @iNextRowIdItem								 
				
				SELECT @amounttobewithheld = @amounttobewithheld - (@wccost * @slwiwcpct)
				
				Get_Next_Item1:	

				-- Reset looping variables.           
				SELECT @iNextRowIdItem = NULL
											
				-- get the next iRowId
				SELECT @iNextRowIdItem = MIN(w.KeyID)
				FROM bSLWI w
					join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0							
				WHERE w.SLCo = @slco and w.SL = @sl and w.WCCost <> 0 and w.KeyID > @iCurrentRowIdItem
				
				-- did we get a valid next row id?
				IF ISNULL(@iNextRowIdItem,0) = 0
					BEGIN
					SELECT @iLoopControlItem = 1
					END				
				END	
							
			--Check to see if there is any remaining amount not counted for because of rounding issues.
			--Find out what is defaulted into SLWorksheet to be withheld
			SELECT @slwiretgamt = sum(isnull(w.WCRetAmt,0))
			FROM bSLWI w with (nolock)
				join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0										
			WHERE w.SLCo = @slco and w.SL = @sl
			GROUP BY w.SLCo, w.SL

			--Add what has been withheld to what is defaulted to be withheld
			SELECT @totalretamt = @slwiretgamt + @retgamtwithheld
			
			--get the amount left to be withheld by withheld - maxretgamt
			SELECT @amounttobewithheld = @maxretgamt - @totalretamt 
						
			IF @amounttobewithheld <> 0									
				BEGIN
				SELECT @iNextRowIdItem = MIN(w.KeyID)
				FROM   bSLWI w with (nolock)
					join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0							
				WHERE w.SLCo = @slco and w.SL = @sl and w.WCCost <> 0
				
				--Get info from the first record in SLWI
				SELECT @slwiwcretamt = WCRetAmt
				FROM bSLWI
				WHERE KeyID = @iNextRowIdItem								

				--update SLWI, set the WCRetPct and WCRetAmt
				UPDATE bSLWI
				Set WCRetAmt = @slwiwcretamt + @amounttobewithheld, WCRetPct = (@slwiwcretamt + @amounttobewithheld) / WCCost
				WHERE KeyID = @iNextRowIdItem
				END											
			END
			
		-- IF MaxRetgDistStyle = I then spread the remaining retainage to each item until the remaining retainage amount is used up.
		IF @diststyle = 'I'
			BEGIN
			--loop through all SL Items setting the WCRetAmt and WCRetPct			
			SELECT @iLoopControlItem = 0 
			
			--Get keyid to loop through bSLWI table   			  		   						
			SELECT @iNextRowIdItem = MIN(w.KeyID)
			FROM   bSLWI w with (nolock)
				join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0										
			WHERE w.SLCo = @slco and w.SL = @sl and w.WCCost <> 0
			
			IF ISNULL(@iNextRowIdItem,0) = 0
				--no SLWI records for the subcontract.
				BEGIN		
				SELECT @msg = 'No Item(s) initialized into the worksheet.', @rc = 0, @iLoopControlItem = 1	  
				GOTO vspExit			
				END			

			WHILE @iLoopControlItem = 0  -- start the main (header) processing loop.
				BEGIN
				
				--Get info from the first record in SLWI
				SELECT @iCurrentRowIdItem = KeyID, @wccost = WCCost, @slwiwcretamt = WCRetAmt
				FROM bSLWI
				WHERE KeyID = @iNextRowIdItem						
											
				--compare the amount of retainage for the first item to the amount of retainage remaining
				IF @slwiwcretamt <= @amounttobewithheld
					BEGIN-- if the retainage for the first item is less then the amount of retainage remaining, then skip to the next item.
					SELECT @amounttobewithheld = @amounttobewithheld - @slwiwcretamt
					GOTO Get_Next_Item2
					END
					
				--If the amount to be withheld = 0 then set the retainage amount to 0
				IF @amounttobewithheld = 0
					BEGIN
					UPDATE bSLWI
					SET WCRetAmt = 0, WCRetPct = 0
					WHERE KeyID = @iNextRowIdItem 
					GOTO Get_Next_Item2
					END
					
				--if the amount of retainage is less then the defaulted amount of retainage in the worksheet, then 
				--update the amount of retainage for the item to what is remaining.
				IF @slwiwcretamt > @amounttobewithheld
					BEGIN
					UPDATE bSLWI
					SET WCRetAmt = @amounttobewithheld, WCRetPct = @amounttobewithheld / @wccost
					WHERE KeyID = @iNextRowIdItem 
					
					SELECT @amounttobewithheld = 0
					END
				
				Get_Next_Item2:	

				-- Reset looping variables.           
				SELECT @iNextRowIdItem = NULL
											
				-- get the next iRowId
				SELECT @iNextRowIdItem = MIN(w.KeyID)
				FROM bSLWI w
					join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0														
				WHERE w.SLCo = @slco and w.SL = @sl and w.WCCost <> 0 and w.KeyID > @iCurrentRowIdItem
				
				-- did we get a valid next row id?
				IF ISNULL(@iNextRowIdItem,0) = 0
					BEGIN
					SELECT @iLoopControlItem = 1
					END				
			
				END
			END						
						
		END						

vspExit:
	RETURN @rc
GO
GRANT EXECUTE ON  [dbo].[vspSLWIRetgPctUpdate] TO [public]
GO
