SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOITTotalGet    Script Date: 8/28/99 9:34:02 AM ******/
   CREATE  proc [dbo].[bspAPPOITTotalGet]
   /********************************************************
   * CREATED BY: 	SE 2/25/98
   * MODIFIED BY:  kb 1/6/99
   *               GR 6/18/99
   *               TV 08/06/01 - Was not leaving backordered amount at 0 if the PO had not been recieved
   *              kb 10/28/2 - issue #18878 - fix double quotes
   *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *
   * USAGE:
   * 	Retrieves the total cost for a PO item 
   *       the total for a PO is the  Sum of the Items in the 
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
   	(@apco  bCompany, @mth bMonth, @batchid bBatchID, @po varchar(30),  @poitem bItem, @source char(1))
   as
   	set nocount on
   	declare @rcode int, @msg varchar(100), @lbunits bUnits, @lboldunits bUnits, @lbnewunits bUnits, 
   		@lbcost bDollar, @lboldcost bDollar, @lbnewcost bDollar, @lbtax bDollar
   	declare  @curunits bUnits, @curunitcost bUnitCost,@curecm bECM,@curcost bDollar,
                    @curtax bDollar, @recvdunits bUnits, @recvdcost bDollar,
                    @bounits bUnits, @bocost bUnitCost, @totalunits bUnits,
                    @totalcost bDollar,@totaltax bDollar, @invunits bUnits,
                    @invcost bDollar,@invtax bDollar, @remunits bUnits, @remcost bDollar,
                    @remtax bDollar, @recvyn bYN, @um bUM
   
      
   
   if @apco is null
   	begin
   	select @msg = 'Missing AP Company', @rcode = 1
   	goto bspexit
   	end
   if @po is null
   	begin
   	select @msg = 'Missing po#', @rcode = 1
   	goto bspexit
   	end
   
   
   
   select @curunits=CurUnits,@curunitcost=CurUnitCost,@curecm=CurECM,@curcost=CurCost,
          @curtax=CurTax, @recvdunits=RecvdUnits, @recvdcost=RecvdCost,@bounits=BOUnits,
          @bocost=BOCost, @invunits=InvUnits,@invcost=InvCost, @invtax=InvTax, 
          @remunits=RemUnits,@remcost=RemCost,@remtax=RemTax, @recvyn=RecvYN, @um=UM
       from POIT
      where POCo=@apco and PO=@po and POItem=@poitem
   
   /*Now get amounts from batch */
   if @source = 'E'
   	begin
   	/* get old amounts and old units from changed and deleted entries*/
   	select @lboldunits=isnull(sum(OldUnits), 0),
   		@lboldcost=isnull(sum(OldGrossAmt), 0)
   	from bAPLB
    	 where Co=@apco and Mth=@mth and BatchId=@batchid and 
            OldPO=@po and OldPOItem=@poitem and BatchTransType in ('C', 'D')
            
            /*get new amounts and units from added and changed entries*/
            select @lbnewunits=isnull(sum(Units), 0),
            	@lbnewcost=isnull(sum(GrossAmt), 0)
            from bAPLB
    	 where Co=@apco and Mth=@mth and BatchId=@batchid and 
            PO=@po and POItem=@poitem and BatchTransType in ('C', 'A')
   		     
    	select @lbtax=sum(case BatchTransType 
   		      WHEN 'A' THEN TaxAmt
   		      WHEN 'C' THEN TaxAmt-OldTaxAmt
   		      WHEN 'D' THEN OldTaxAmt
   		     END)
   	 from bAPLB
    	 where Co=@apco and Mth=@mth and BatchId=@batchid and 
            PO=@po and POItem=@poitem
           end
           
   select @lbcost=@lbnewcost-@lboldcost
   select @lbunits=@lbnewunits-@lboldunits
   
   if @source = 'U'  --unapproved invoices
   	begin
   	select 	@lbunits= sum(Units), @lbcost=sum(GrossAmt), @lbtax=sum(TaxAmt)
   	 from bAPUL
    	 where APCo=@apco and UIMth=@mth and UISeq=@batchid and 
            PO=@po and POItem=@poitem
           end
           
   /* include month and batch to speed up query */  
   	
   if @recvyn='N' 
		begin
      select @recvdunits=@recvdunits+isnull(@lbunits,0), @recvdcost=@recvdcost+isnull(@lbcost,0),
             @bounits=@bounits-isnull(@lbunits,0)--, @bocost=@bocost-isnull(@lbcost,0)as per issue #14211 TV 08/06/01
		end

   select @invunits=@invunits+isnull(@lbunits,0),@invcost=@invcost+isnull(@lbcost,0),
          @invtax = @invtax + isnull(@lbtax,0)
          
   select @remunits = CASE @um WHEN 'LS' THEN 0 
   		         ELSE @recvdunits+@bounits-@invunits END,
          @remcost= CASE @um WHEN 'LS' THEN @recvdcost+@bocost-@invcost
   			 ELSE case @curecm when 'E' then ((@recvdunits+@bounits-@invunits)*@curunitcost)
   			 when 'C' then ((@recvdunits+@bounits-@invunits)*@curunitcost/100) when 
   			 'M' then ((@recvdunits+@bounits-@invunits)*@curunitcost/1000) end  END,
          @remtax=@remtax-isnull(@lbtax,0)
   			 
   
   select  'CurUnits'=@curunits,'CurUnitCost'=@curunitcost,'CurECM'=@curecm,
   	'CurCost'=@curcost,'CurTax'=@curtax, 'RecvdUnits'=@recvdunits,
   	'RecvdCost'=@recvdcost,'BOUnits'=@bounits, 'BOCost'=@bocost, 
           'InvUnits'=@invunits,'InvCost'=@invcost,'InvTax'=@invtax, 
           'RemUnits'=@remunits,
           'RemCost'=@remcost,'RemTax'=@remtax
           
   
   bspexit:
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPOITTotalGet] TO [public]
GO
