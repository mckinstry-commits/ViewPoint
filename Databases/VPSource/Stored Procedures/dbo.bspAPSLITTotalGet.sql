SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPSLITTotalGet    Script Date: 8/28/99 9:34:04 AM ******/
   
    CREATE proc [dbo].[bspAPSLITTotalGet]
    /********************************************************
    * CREATED BY: 	SE 2/25/98
    * MODIFIED BY:  kb 1/6/99
    *		 GR 6/18/99
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *               MV 07/14/08 - #128288 SL Tax 
    *				GP 6/28/10 - #135813 change bSL to varchar(30) 
    * USAGE:
    * 	Retrieves the total cost for a Subcontract item
    *       the total for a Subcontract is the  Sum of the Items in the
    *       SLIT + adjustment in the batch
    *
    * USED IN
    *       APEntry
    *
    * INPUT PARAMETERS:
    *	APCO
    *       Mth
    *       BatchId
    *	SL
    *
    * OUTPUT PARAMETERS:
    *	returns the amounts in a recordset
    *	Error Message, if one
    *
    * RETURN VALUE:
    * 	0 	    Success
    *	1 & message Failure
    *
    **********************************************************/
    	(@apco  bCompany, @mth bMonth, @batchid bBatchID, @sl varchar(30),  @slitem bItem, @source char(1))
    as
    	set nocount on
    	declare @rcode int, @msg varchar(100)
    	declare @origunits bUnits, @origunitcost bUnitCost, @origcost bDollar,
                @curunits bUnits, @curunitcost bUnitCost, @curcost bDollar,
           		@invunits bUnits, @invcost bDollar,
           		@lbunits bUnits, @lboldunits bUnits, @lbnewunits bUnits, 
           		@lbcost bDollar, @lboldcost bDollar, @lbnewcost bDollar,
                @origtax bDollar, @curtax bDollar, @invtax bDollar
   
    	select @rcode = 0
   
    if @apco is null
    	begin
    	select @msg = 'Missing SL Company', @rcode = 1
    	goto bspexit
    	end
    if @sl is null
    	begin
    	select @msg = 'Missing SL#', @rcode = 1
   
    	goto bspexit
    	end
   
   
    select 	@origunits=OrigUnits, @origunitcost = OrigUnitCost,@origcost=OrigCost,
    	@curunits=CurUnits, @curunitcost=CurUnitCost, @curcost=CurCost,@invunits=InvUnits,
        @invcost=InvCost,@origtax=OrigTax,@curtax=CurTax,@invtax=InvTax
    	from SLIT
       where SLCo=@apco and SL=@sl and SLItem=@slitem
   
   
    /*Now get amounts from batch */
    if @source = 'E'
    	begin
    	/* get oldamounts and oldunits from changed and deleted entries */
    	  select @lboldcost = isnull(sum(OldGrossAmt), 0),
    	  	@lboldunits = isnull(sum(OldUnits), 0)
    	  from bAPLB
    	  where Co=@apco and Mth=@mth and BatchId=@batchid and
             OldSL=@sl and OldSLItem=@slitem and BatchTransType in ('C', 'D')
             
             /* get new amounts and newunits from changed and deleted entries*/
             select @lbnewcost = isnull(sum(GrossAmt), 0),
             	@lbnewunits = isnull(sum(Units), 0)
             from bAPLB
    	  where Co=@apco and Mth=@mth and BatchId=@batchid and
             SL=@sl and SLItem=@slitem and BatchTransType in ('C', 'A')
    	end
    	
    select @lbcost = @lbnewcost-@lboldcost
    select @lbunits = @lbnewunits-@lboldunits
   
    if @source = 'U' -- unapproved invoices
    	begin
    	select 	@lbunits=sum(Units),@lbcost=sum(GrossAmt)
    	 from bAPUL
     	 where APCo=@apco and UIMth=@mth and UISeq=@batchid and
             SL=@sl and SLItem=@slitem
    	end
   
   
    select 'OrigUnits'=@origunits,'OrigUnitCost'=@origunitcost, 'OrigCost'=@origcost,
           'CurUnits'=@curunits, 'CurUnitCost'=@curunitcost, 'CurCost'=@curcost,
           'InvUnits'=@invunits+isnull(@lbunits,0),'InvCost'=@invcost + isnull(@lbcost,0),
            'OrigTax' = @origtax,'CurTax'=@curtax,'InvTax'=@invtax
   
   
    bspexit:
   
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLITTotalGet] TO [public]
GO
