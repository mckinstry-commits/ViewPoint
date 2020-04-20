SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.vspSLMaxRetgCheck    Script Date: 02/23/2010 9:36:38 AM ******/
CREATE proc [dbo].[vspSLMaxRetgCheck]      
/***********************************************************
* CREATED BY: DC	2/23/10 - SL - Handle max retainage
* MODIFIED By : DC 6/29/10 - #135813 - expand subcontract number
*
*
*
* USAGE:
* Called from bspSLWHAddSingleSL to check the amount of retainage
*		to be withheld for a single subcontract
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
*		2			Max Retainage needs to be adjusted
*****************************************************/   
	(@slco bCompany, @sl VARCHAR(30), --bSL,   DC #135813
	@msg varchar(255) output)
	as
	set nocount on
		
	DECLARE @retgamtwithheld bDollar, @rc int, @slwiretgamt bDollar, @totalretamt bDollar,
			@maxretgamt bDollar, @amounttobewithheld bDollar, @diststyle char(1),
			@CountItemsToAdjust int, @RemainingItemRetg bDollar, @wccost bDollar,
			@slwiwcretamt bDollar 

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
	
	--Find out what is defaulted into SLWorksheet to be withheld
	SELECT @slwiretgamt = sum(isnull(w.WCRetAmt,0))
	FROM bSLWI w with (nolock)
		join bSLIT i with (nolock) on i.SLCo = w.SLCo and i.SL = w.SL and i.SLItem = w.SLItem and i.WCRetPct <> 0	
	WHERE w.SLCo = @slco and w.SL = @sl
	GROUP BY w.SLCo, w.SL	

	--Add what has been withheld to what is defaulted to be withheld
	SELECT @totalretamt = @slwiretgamt + @retgamtwithheld
	
	--If totalretamt is greater then the maxretgamt, then we have a problem
	IF @totalretamt > @maxretgamt 
		BEGIN
		SELECT @msg = 'Exceeds maximum retainage limits.', @rc = 2				
		END						

vspExit:
	RETURN @rc
GO
GRANT EXECUTE ON  [dbo].[vspSLMaxRetgCheck] TO [public]
GO
