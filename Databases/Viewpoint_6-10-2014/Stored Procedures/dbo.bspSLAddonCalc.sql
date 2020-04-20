SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLAddonCalc    Script Date: 8/28/99 9:33:40 AM ******/
CREATE      proc [dbo].[bspSLAddonCalc]
/***********************************************************
* CREATED BY: kf 7/18/97
* MODIFIED By : kf 7/18/97
*				 MV 09/09/03 - #21976 Addon percentage calculations should not
*					exceed the amount (CurCost) of the contract.  Performance enhancements.
*				 MV 08/02/05 - #28964 - update WCToDate and WCPctComplete with amounts and
*					added cursor to cycle through all Addon items not just the first one 
*				 MV 08/17/05 - #29615 - 'A'mount type addons - include prev invcd in calcs
*				DC	08/07/07 - #123569 - Add-on calculating wrong if apply percentage = 'N'
*				TJL 09/30/08 - Issue #130049, Error Null not allowed into SLWI.WCCost on Worksheet Init
*				DC  11/17/08 - Issue #122711 - Problem with billing over 100% on add-on items
*				DC 06/29/09 -  #134485 - Initialize Subcontract does not show W/C % to Date in Info or Grid
*				DC 06/24/10 -  #135813 - expand subcontract number
*
*
* USAGE:
* this procedure is called from the SL Worksheet.
* When a regular or changeorder item is updated in the worksheet,
* the 'ThisInvoice' for percent type addon lines, where the
* percent is applied per invoice, is updated.
* an error is returned if any goes wrong.
*
*  INPUT PARAMETERS
*   @co= Company
*   @sl= from SLWorksheet
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@co bCompany, @sl VARCHAR(30), @msg VARCHAR(60) OUTPUT)  --DC #135813  (bSL)
as
   
set nocount on
   
declare @rcode int, @opencursor tinyint, @slitem bItem, @thisinvoice bDollar,
   	@itemtype tinyint, @pct bPct, @addontype char(1),@amount bDollar,
   	@applypct bYN, @slwisum bDollar, @slitcurcost bDollar,@wccost bDollar, @wctodate bDollar,
   	@wcpctcomplete float,  --@wcpctcomplete bPct,  DC #134485
   	@prevwccost bDollar
   
select @rcode=0, @opencursor=0
   /*cycle through ALL Addon items in SLWI, there may be more than one and they need to be handled separately*/
   
declare bcSLWI cursor LOCAL FAST_FORWARD for
select SLAD.Type, SLWI.SLItem from SLWI WITH (NOLOCK)
join SLIT WITH (NOLOCK) on SLIT.SLCo=SLWI.SLCo and SLIT.SL=SLWI.SL and SLIT.SLItem=SLWI.SLItem
join SLAD WITH (NOLOCK) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
where SLWI.SLCo=@co and SLWI.SL=@sl and SLWI.ItemType=4
/* open cursor */
open bcSLWI
/* set open cursor flag to true */
select @opencursor=1
/* get first addon */
SLWI_Loop: 
fetch next from bcSLWI into @addontype,@slitem	
   
   	/* loop through all rows */
   	while (@@fetch_status = 0)
   	BEGIN
   
   -- if @@rowcount=0
   -- 	begin
   -- 	goto bspexit
   -- 	end
   
	if @addontype='P'
		begin
	   	
   		/***********first see if there are any addon items for this SL and if they are percent types
   		and if the percent is applied per invoice - if not then exit out, no updates to be made.*********/
	   -- 	select @opencursor = 0
	   
	   -- 	declare bcSLWI cursor LOCAL FAST_FORWARD for  
	   -- 		select SLWI.SLItem, SLWI.ItemType, SLIT.Addon, SLIT.AddonPct, SLAD.ApplyPct, SLIT.CurCost, SLWI.PrevWCCost
	   -- 		from SLWI WITH (NOLOCK)
	   -- 		join SLIT WITH (NOLOCK) on SLIT.SLCo=SLWI.SLCo and SLIT.SL=SLWI.SL and SLIT.SLItem=SLWI.SLItem
	   -- 		join SLAD WITH (NOLOCK) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
	   -- 		where SLWI.SLCo=@co and SLWI.SL=@sl and SLWI.ItemType=4 and SLAD.Type='P' and SLWI.SLItem=@slitem
	   -- 
	   -- 		/* open cursor */
	   -- 
	   -- 		open bcSLWI
	   -- 
	   -- 		/* set open cursor flag to true */
	   -- 		select @opencursor = 1
	   -- 
	   -- 
	   -- 		/* get first row */
	   -- 		fetch next from bcSLWI into @slitem, @itemtype, @addon, @pct, @applypct, @slitcurcost,@prevwccost
	   -- 
	   -- 		/* loop through all rows */
	   -- 		while (@@fetch_status = 0)
	   -- 			begin
	   
		select @itemtype=SLWI.ItemType,@pct=SLIT.AddonPct, @applypct=SLAD.ApplyPct, @slitcurcost=SLIT.CurCost,
   			@prevwccost=SLWI.PrevWCCost
		from SLWI WITH (NOLOCK)
		join SLIT WITH (NOLOCK) on SLIT.SLCo=SLWI.SLCo and SLIT.SL=SLWI.SL and SLIT.SLItem=SLWI.SLItem
		join SLAD WITH (NOLOCK) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
		where SLWI.SLCo=@co and SLWI.SL=@sl and SLWI.ItemType=4 and SLAD.Type='P' and SLWI.SLItem=@slitem
	   
		if @applypct='N'
			begin
			select @thisinvoice= sum(SLIT.CurCost), @slwisum=sum(SLWI.WCCost) 
			from SLIT WITH (NOLOCK)
			join SLWI WITH (NOLOCK) on SLWI.SLCo=SLIT.SLCo and SLWI.SL=SLIT.SL and SLWI.SLItem=SLIT.SLItem
			where SLIT.SLCo=@co and SLIT.SL=@sl and SLIT.ItemType<3
			if @slwisum=0 select @thisinvoice=0
			select @wccost = isnull(@thisinvoice, 0) * isnull(@pct, 0)
			select @wctodate = isnull(@prevwccost, 0) + isnull(@wccost, 0)					
			select @wcpctcomplete = case when isnull(@slitcurcost, 0) <> 0 then @wctodate/@slitcurcost else 0 end
			--#21976 WCCost should not exceed the current cost of the addon
			--#123569 Should not update once WCPctComplete is 100%
			if (select WCPctComplete from SLWI where SLCo=@co and SL=@sl and SLItem=@slitem and ItemType=4) < 1
				BEGIN   					
				update SLWI set WCCost= case when abs(@wccost) > abs(isnull(@slitcurcost, 0)) then isnull(@slitcurcost,0) else @wccost end,
						AmtClaimed = case when abs(@wccost) > abs(isnull(@slitcurcost, 0)) then isnull(@slitcurcost,0) else @wccost end,  --DC #134485
					WCToDate = @wctodate, WCPctComplete = @wcpctcomplete
					/*update SLWI set WCCost=@thisinvoice*@pct*/
				where SLCo=@co and SL=@sl and SLItem=@slitem and ItemType=4
				END
			end
		else
			begin
			select @thisinvoice= sum(SLWI.WCCost) from SLWI WITH (NOLOCK)where SLCo=@co and SL=@sl and ItemType<3
			select @wccost = isnull(@thisinvoice, 0) * isnull(@pct, 0)
			select @wctodate = isnull(@prevwccost, 0) + isnull(@wccost, 0)
			
			select @wcpctcomplete = case when isnull(@slitcurcost, 0) <> 0 then @wctodate/@slitcurcost else 0 end						
			
			--DC #134485
			IF @wcpctcomplete > 99.9999 or @wcpctcomplete < -99.9999
				BEGIN
				SELECT @wcpctcomplete = 0
				END

			-- #21976 WCCost should not exceed the current cost of the addon			
			update SLWI	set WCCost= @wccost,  --DC #122711
					AmtClaimed = @wccost,  --DC #134485
				WCToDate = @wctodate, WCPctComplete = @wcpctcomplete
				/*update SLWI set WCCost=@thisinvoice*@pct*/
			where SLCo=@co and SL=@sl and SLItem=@slitem and ItemType=4
			
			/*  OLD CODE BEFORE fix for #122711
			-- #21976 WCCost should not exceed the current cost of the addon			
			update SLWI	set WCCost= case when abs(@wccost) > abs(isnull(@slitcurcost, 0)) then isnull(@slitcurcost, 0) else @wccost end,
				WCToDate = @wctodate, WCPctComplete = @wcpctcomplete
				/*update SLWI set WCCost=@thisinvoice*@pct*/
			where SLCo=@co and SL=@sl and SLItem=@slitem and ItemType=4
			*/
			end
	   
	   -- 			GetNext:
	   -- 			fetch next from bcSLWI into @slitem, @itemtype, @addon, @pct, @applypct,@slitcurcost,@prevwccost
	   
	   -- 		end
	   -- 
	   -- 		if @opencursor=1
	   -- 			begin
	   -- 			close bcSLWI
	   -- 
	   -- 			deallocate bcSLWI
	   -- 			select @opencursor=0
	   -- 			end
		end
   
	if @addontype='A'
   		begin
   	/*cycle through Addon items in SLWI, there may be more than one and they need to be handled separately*/
   
   -- 	select @opencursor = 0
   -- 
   -- 	declare bcSLWI cursor LOCAL FAST_FORWARD for
   -- 		select SLWI.SLItem, SLWI.ItemType, SLIT.Addon, SLIT.CurCost from SLWI WITH (NOLOCK)
   -- 		join SLIT WITH (NOLOCK) on SLIT.SLCo=SLWI.SLCo and SLIT.SL=SLWI.SL and SLIT.SLItem=SLWI.SLItem
   -- 		join SLAD WITH (NOLOCK) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
   -- 		where SLWI.SLCo=@co and SLWI.SL=@sl and SLWI.ItemType=4 and SLAD.Type='A' 
   -- 		/* open cursor */
   -- 
   -- 		open bcSLWI
   -- 
   -- 		/* set open cursor flag to true */
   -- 		select @opencursor = 1
   -- 
   -- 
   -- 		/* get first row */
   -- 		fetch next from bcSLWI into @slitem, @itemtype, @addon, @amount
   -- 
   -- 		/* loop through all rows */
   -- 		while (@@fetch_status = 0)
   -- 			begin
   		--#
		select @prevwccost=SLWI.PrevWCCost, @slitcurcost=SLIT.CurCost
   		from SLWI WITH (NOLOCK)
   		join SLIT WITH (NOLOCK) on SLIT.SLCo=SLWI.SLCo and SLIT.SL=SLWI.SL and SLIT.SLItem=SLWI.SLItem
   		join SLAD WITH (NOLOCK) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
   		where SLWI.SLCo=@co and SLWI.SL=@sl and SLWI.ItemType=4 and SLAD.Type='A' and SLWI.SLItem=@slitem
   		select @amount = isnull(@slitcurcost, 0) - isnull(@prevwccost, 0)		--#29615
   		select @wctodate = isnull(@prevwccost, 0) + isnull(@amount, 0)		--#29615
   		select @wcpctcomplete = case when isnull(@slitcurcost, 0) <> 0 then (@wctodate/@slitcurcost) else 0 end
		update SLWI set WCCost=@amount, 
					AmtClaimed = @amount,
					WCToDate=@wctodate, WCPctComplete=@wcpctcomplete
   		where SLCo=@co and SL=@sl and SLItem=@slitem and ItemType=4
   
   		end
   
	goto SLWI_Loop
   
   -- 			GetNext2:
   -- 			fetch next from bcSLWI into @slitem, @itemtype, @addon, @amount
   -- 
   -- 			end
   -- 
   -- 		if @opencursor=1
   -- 			begin
   -- 			close bcSLWI
   -- 			deallocate bcSLWI
   -- 			select @opencursor=0
   -- 			end
   	
   
   	END
   
bspexit:
if @opencursor=1
	begin
	close bcSLWI
	deallocate bcSLWI
	select @opencursor=0
	end

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLAddonCalc] TO [public]
GO
