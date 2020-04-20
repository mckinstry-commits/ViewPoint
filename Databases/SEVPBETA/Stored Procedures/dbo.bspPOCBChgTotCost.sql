SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
   CREATE      procedure [dbo].[bspPOCBChgTotCost]
   /**********************************************
   *	CREATED BY	: MV 10/10/03
  *	Modified by	:	DC 04/29/08 -#120634: Add a column to POCD for ChgToTax
   *					DC 10/6/2009 - #122288:  Store tax rate in POItem
   *					TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
   *				GF 08/22/2011 - TK-07650 PO ITEM LINE
   *
   *
   *	USED BY
   *		PO Change Orders
   *
   *	USAGE
   *		Calculates the change to total cost for non LS change orders and returns the value.	
   *			per ISSUE 22320
   *	
   *	INPUT PARAMETERS
   *		Co, Mth, BatchId, Seq,PO, POItem, ChgCurUnits, CurUnitCost
   *
   *	OUTPUT PARAMETERS
   *		@chgtotcost, @msg error message if doesnt pass validation
   *
   *	RETURN VALUE
   *		0	success
   *		1 	Failure
   ************************************************************/
   (@co bCompany, @mth bMonth,@batchid int, @seq int, @po varchar(30) = null, @poitem bItem = null,
     @changecurunits bUnits, @curunitcost bUnitCost, 
	@um bUM, --DC #120634
	@chgtotcost bDollar output, 
	@chgtotax bDollar = null output,  --DC #120634
	@msg varchar(250) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @poitcurunitcost bUnitCost,@poitcurunits bUnits,@factor int, @oldcurunits bUnits,
		@poitcurecm bECM, @oldunitcost bUnitCost, @origcost bDollar, @changecost bDollar,
		@taxrate bRate --DC #120634
		      
	select @rcode=0, @oldunitcost = 0, @oldcurunits = 0
	select @factor = 1  --DC #120634

   
	IF @co is null
		BEGIN
		select @msg = 'Missing PO Company!', @rcode = 1
		goto bspexit
		END
   
	IF @po is null
   		BEGIN   
   		select @msg = 'Missing PO!', @rcode = 1
   		goto bspexit
   		END
      
	IF @poitem is null
   		BEGIN
   		select @msg = 'Missing PO Item#!', @rcode = 1
   		goto bspexit
   		END
   
   -- Get POIT values
	SELECT @poitcurunitcost=CurUnitCost, @poitcurecm=CurECM, @taxrate = TaxRate,  --DC #122288
			@poitcurunits = CurUnits	
	FROM dbo.bPOIT
	WHERE POCo=@co and PO=@po and POItem=@poitem

	---- get item line 1 current units if exists TK-07650
	IF EXISTS(SELECT 1 FROM dbo.vPOItemLine WHERE POCo=@co AND PO=@po
					AND POItem=@poitem AND POItemLine=1)
		BEGIN
		SELECT @poitcurunits = CurUnits
		FROM dbo.vPOItemLine
		WHERE POCo=@co AND PO=@po
			AND POItem=@poitem
			AND POItemLine=1
		END

   -- Get old values from bPOCB if it exists 
	IF exists (select 1 from bPOCB with (nolock) where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq)
   		BEGIN
   		select @oldunitcost= isnull(OldUnitCost,0), @oldcurunits = isnull(OldCurUnits,0) 
   		from bPOCB with (nolock)
   		where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
   		END
   
	/* Calculate change to total cost */
	select @factor = case @poitcurecm when 'C' then 100 when 'M' then 1000 else 1 end
	-- Calculate change to original units
	select @origcost =  ((@poitcurunits - @oldcurunits) * @curunitcost) / @factor
	-- Calculate change to new units
	select @changecost = (@changecurunits * (@poitcurunitcost + (@curunitcost - @oldunitcost))) / @factor
	
	IF @um <> 'LS'
		BEGIN
		-- Add orig and change
		select @chgtotcost = @origcost + @changecost
		--Calculate change to Tax  --DC #120634
		select @chgtotax = @chgtotcost * @taxrate  
		END
	ELSE
		BEGIN		
		--Calculate change to Tax  --DC #120634
		select @chgtotax = @chgtotcost * @taxrate  
		END	
   
   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPOCBChgTotCost] TO [public]
GO
