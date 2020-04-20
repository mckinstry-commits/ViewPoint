SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
/****** Object:  Stored Procedure dbo.vspPORecItemLineGet  ******/
CREATE    proc [dbo].[vspPORecItemLineGet]
/********************************************************
* CREATED BY:	GF 08/19/2011 TK-07650 TK-07879
* MODIFIED BY:
*
* USAGE:
* 	Called by PO Change Order or Receiving Entry to return current Item Line values
*	
* INPUT PARAMETERS:
* @POCo				PO Company number
* @PO				PO
* @POItem			PO Item
* @POItemLine		PO Item Line
* @RecvdDate		Receiving/Change Order Date - used for Tax Rate
* @Source			Source - PO Change or PO Receipt
*
* OUTPUT PARAMETERS:
*	none
*
* RETURNS:
* 	Record set of current PO Item information
*
**********************************************************/   
(@POCo bCompany = 0, @PO VARCHAR(30) = NULL, @POItem bItem = NULL,
 @POItemLine INT = NULL, @RecvdDate bDate = NULL,
 @Source bSource = NULL)
AS
SET NOCOUNT ON

declare @totunits bUnits, @totcost bDollar, @bounits bUnits, @bocost bDollar, @TaxRate bRate,
		@ErrMsg varchar(255), @TaxCode bTaxCode, @totunitcost bUnitCost, @tbounits bUnits,
		@ttotunits bUnits, @tcurunitcost bUnitCost, @tax VARCHAR(20), @TaxGroup bGroup,
		@invunits bUnits, @curunitcost bUnitCost, @invcost bDollar, @invunitscost bUnitCost,
		@Factor smallint

  
---- PO Receipt Source
if @Source = 'PO Receipt'
	BEGIN
	---- get net change to Item Line Received and BackOrdered Units and Cost from Receipts batch
	SELECT  @totunits = ISNULL(SUM(RecvdUnits),0) - ISNULL(SUM(OldRecvdUnits),0),
			@totcost  = ISNULL(SUM(RecvdCost),0) - ISNULL(SUM(OldRecvdCost),0),
			@bounits  = ISNULL(SUM(BOUnits),0) - ISNULL(SUM(OldBOUnits),0),
			@bocost   = ISNULL(SUM(BOCost),0) - ISNULL(SUM(OldBOCost),0)
	FROM dbo.bPORB
	WHERE Co = @POCo
		AND PO = @PO
		AND POItem = @POItem
		AND POItemLine = @POItemLine
		---- exclude deletes
		AND BatchTransType <> 'D'

	---- back out amounts from batch entries flagged for delete
	SELECT  @totunits = @totunits - ISNULL(SUM(OldRecvdUnits),0),
			@totcost  = @totcost - ISNULL(SUM(OldRecvdCost),0),
			@bounits  = @bounits - ISNULL(SUM(OldBOUnits),0),
			@bocost   = @bocost - ISNULL(SUM(OldBOCost),0)
	FROM dbo.bPORB
	WHERE Co = @POCo
		AND OldPO = @PO 
		AND OldPOItem = @POItem
		AND OldPOItemLine = @POItemLine
		AND BatchTransType = 'D'

	---- initalize tax variables
	SET @TaxCode = NULL
	SET @TaxRate = 0
	SET @Factor = 1
 	
 	---- get info from PO Item Line
 	SELECT @TaxGroup = TaxGroup, @TaxCode = TaxCode, @TaxRate = TaxRate
 	FROM dbo.vPOItemLine
 	WHERE POCo = @POCo
 		AND PO = @PO
 		AND POItem = @POItem
 		AND POItemLine = @POItemLine
 	
 	---- get Factor from PO Item
 	SELECT @Factor = CASE CurECM WHEN 'M' THEN 1000 WHEN 'C' THEN 100 WHEN 'E' THEN 1 ELSE 1 END
	FROM dbo.bPOIT
	WHERE POCo = @POCo
		AND PO = @PO
		AND POItem = @POItem
		---- Item must be flagged for Receiving
		AND RecvYN = 'Y'

   
   	---- create recordset of Item Line values 
	SELECT line.PostToCo,
			'ItemType' = line.ItemType,
			'Material' = item.Material,
			'UM' = item.UM,
			'Loc' = line.Loc,
			'Job' = line.Job,
			'Phase' = line.Phase,
			'JCCType' = line.JCCType,
			'Equip' = line.Equip,
			'CostCode' = line.CostCode,
			'EMCType' = line.EMCType,
			'WO' =line.WO,
			'WOItem' = line.WOItem,
			'GLCo' = line.GLCo,
			'GLAcct' = line.GLAcct,
			'TaxCode' = isnull(line.TaxCode,''),
			'TaxGroup' = isnull(line.TaxGroup,''),
			'OrigUnits' = line.OrigUnits,
			'OrigUnitCost' = item.OrigUnitCost,
     		'OrigECM' = item.OrigECM,
     		'OrigCost' = line.OrigCost,
     		'OrigTax' = line.OrigTax,
     		'CurUnits' = line.CurUnits,
     		'CurUnitCost' = item.CurUnitCost,
     		'CurECM' = item.CurECM,
   			'CurCost' = line.CurCost,
   			'CurTax' = line.CurTax,
   			'RecvdUnits' = (line.RecvdUnits + @totunits),
   			'RecvdCost'  = CASE item.UM WHEN 'LS'
   							THEN (line.RecvdCost + @totcost)
   							ELSE ((line.RecvdUnits + @totunits) * item.CurUnitCost) / @Factor
   							END,
     		'BOUnits' = (line.BOUnits + @bounits),
   			'BOCost'  = CASE item.UM WHEN 'LS'
   							THEN (line.BOCost + @bocost)
   							ELSE ((line.BOUnits + @bounits) * item.CurUnitCost) / @Factor
   							END,
     		'TotalUnits' = (line.BOUnits + @bounits + line.RecvdUnits + @totunits),
   			'TotalCost'  = CASE item.UM WHEN 'LS'
   							THEN (line.BOCost + @bocost + line.RecvdCost + @totcost)
   							ELSE ((line.BOUnits + @bounits + line.RecvdUnits + @totunits) * item.CurUnitCost) / @Factor
   							END, 
     		'TotalTax' = CASE item.UM WHEN 'LS'
     						THEN (@TaxRate * (@bocost + line.BOCost + @totcost + line.RecvdCost))
							ELSE (@TaxRate * ((line.BOUnits + @bounits + line.RecvdUnits + @totunits) * item.CurUnitCost) / @Factor)
							END,
   			'InvUnits' = line.InvUnits,
   			'InvCost'  = line.InvCost,
   			'InvTax'   = line.InvTax,
   			'RemUnits' = (line.BOUnits + @bounits + line.RecvdUnits + @totunits - line.InvUnits),
     		'RemCost'  = CASE item.UM WHEN 'LS'
     						THEN (line.BOCost + @bocost + line.RecvdCost + @totcost - line.InvCost)
							ELSE (((line.BOUnits + @bounits + line.RecvdUnits + @totunits - line.InvUnits) * item.CurUnitCost) / @Factor)
							END,
     		'RemTax'   = CASE item.UM WHEN 'LS'
							THEN @TaxRate * (line.BOCost + @bocost + line.RecvdCost + @totcost - line.InvCost)
							ELSE(@TaxRate * (((line.BOUnits + @bounits + line.RecvdUnits + @totunits - line.InvUnits) * item.CurUnitCost) / @Factor))
							END
   	FROM dbo.vPOItemLine line
   	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
   	WHERE line.POCo = @POCo
		AND line.PO = @PO
		AND line.POItem = @POItem
		AND line.POItemLine = @POItemLine
   	END
   
   
   
---- Change Orders
IF @Source = 'PO Change'
	BEGIN
	select  @totunits = 0, @totcost = 0, @totunitcost = 0, @bounits = 0, @bocost = 0,
			@invunits = 0, @curunitcost = 0, @invunitscost = 0, @invcost = 0

	---- get net change to Item's Units and Cost from Change Order batch
 	SELECT  @totunits = ISNULL(SUM(ChangeCurUnits),0) - ISNULL(SUM(OldCurUnits),0),
			@totcost = ISNULL(SUM(ChangeCurCost),0) - ISNULL(SUM(OldCurCost),0),
			@totunitcost = ISNULL(SUM(CurUnitCost),0) - ISNULL(SUM(OldUnitCost),0),
			@bounits = ISNULL(SUM(ChangeBOUnits),0) - ISNULL(SUM(OldBOUnits),0),
			@bocost = ISNULL(SUM(ChangeBOCost),0) - ISNULL(SUM(OldBOCost),0)
 	FROM dbo.bPOCB
	WHERE Co = @POCo AND PO = @PO
		AND POItem = @POItem
		---- exclude deletes
		AND BatchTransType <> 'D'

	---- back out amounts from batch entries flagged for delete
	SELECT  @totunits = @totunits - ISNULL(SUM(OldCurUnits),0),
			@totcost = @totcost - ISNULL(SUM(OldCurCost),0),
			@totunitcost = @totunitcost - ISNULL(SUM(OldUnitCost),0),
			@bounits = @bounits - ISNULL(SUM(OldBOUnits),0),
			@bocost = @bocost - ISNULL(SUM(OldBOCost),0)
	FROM dbo.bPOCB
	where Co = @POCo
		AND OldPO = @PO
		AND OldPOItem = @POItem
		---- exclude deletes
		AND BatchTransType = 'D'
	
 	---- get Item line info from PO Item Line
 	SET @TaxCode = NULL
 	SET @TaxRate = 0
 	SET @Factor = 1
 	
 	SELECT  @TaxCode = l.TaxCode, @TaxGroup = l.TaxGroup, @TaxRate = l.TaxRate,
			@Factor  = CASE i.CurECM WHEN 'M' THEN 1000 WHEN 'C' THEN 100 WHEN 'E' THEN 1 ELSE 1 END
	FROM dbo.vPOItemLine l
	INNER JOIN dbo.bPOIT i ON i.POCo=l.POCo AND i.PO=l.PO AND i.POItem=l.POItem
	WHERE l.POCo = @POCo AND l.PO = @PO
		AND l.POItem = @POItem
		AND l.POItemLine = 1


	---- create recordset of Item and item line values
	select  line.PostToCo,
			'ItemType' = line.ItemType, 
			'Material' = item.Material,
			'UM' = item.UM,
			'Loc' = line.Loc,
			'Job' = line.Job,
			'Phase' = line.Phase,
			'JCCType' = line.JCCType,
			'Equip' = line.Equip,
			'CostCode' = line.CostCode,
			'EMCType' = line.EMCType,
			'WO' = line.WO,
			'WOItem' = line.WOItem,
			'GLCo' = line.GLCo,
			'GLAcct' = line.GLAcct,
			'TaxCode' = isnull(line.TaxCode,''),
			'TaxGroup' = isnull(line.TaxGroup,''),
			'OrigUnits' = line.OrigUnits,
			'OrigUnitCost' = item.OrigUnitCost,
			'OrigECM'  = item.OrigECM,
			'OrigCost' = line.OrigCost,
			'OrigTax'  = line.OrigTax,
			'CurUnits' = line.CurUnits + @totunits,
			'CurUnitCost' = item.CurUnitCost + @totunitcost,
			'CurECM' = item.CurECM,
			'CurCost'= CASE item.UM WHEN 'LS' THEN (line.CurCost + @totcost)
					   ELSE ((line.CurUnits + @totunits) * (item.CurUnitCost + @totunitcost)) / @Factor
					   END,
			'CurTax' = CASE item.UM WHEN 'LS' THEN (line.CurCost + @totcost) * @TaxRate
					   ELSE ((line.CurUnits + @totunits) * (item.CurUnitCost + @totunitcost) / @Factor) * @TaxRate
					   END,
			'RecvdUnits' = line.RecvdUnits,
			'RecvdCost'  = CASE item.UM WHEN 'LS' THEN line.RecvdCost
						   ELSE line.RecvdUnits * (item.CurUnitCost + @totunitcost) / @Factor
						   END,
			'BOUnits'    = line.BOUnits + @bounits,
			'BOCost'     = CASE item.UM WHEN 'LS' THEN line.BOCost + @bocost
						   ELSE (line.BOUnits + @bounits) * (item.CurUnitCost + @totunitcost) / @Factor
						   END,
			'TotalUnits' = line.BOUnits + @bounits + line.RecvdUnits, 
			'TotalCost'  = CASE item.UM WHEN 'LS' THEN line.BOCost + @bocost + line.RecvdCost
						   ELSE (line.BOUnits + @bounits + line.RecvdUnits) * (item.CurUnitCost + @totunitcost) / @Factor
						   END,
			'TotalTax'   = CASE item.UM WHEN 'LS' THEN (@bocost + line.BOCost + line.RecvdCost) * @TaxRate
						   ELSE (@bounits + line.BOUnits + line.RecvdUnits) * (item.CurUnitCost + @totunitcost) / @Factor * @TaxRate
						   END,
			'InvUnits' = line.InvUnits,
			'InvCost'  = line.InvCost,
			'InvTax'   = line.InvTax,
			'RemUnits' = (line.BOUnits + @bounits + line.RecvdUnits - line.InvUnits),
			'RemCost'  = CASE item.UM WHEN 'LS' THEN (line.BOCost + @bocost + line.RecvdCost - line.InvCost)
						 ELSE ((line.BOUnits + @bounits + line.RecvdUnits - line.InvUnits) * (item.CurUnitCost + @totunitcost)) / @Factor
						 END,
			'RemTax'   = CASE item.UM WHEN 'LS' THEN (@TaxRate * (line.BOCost + @bocost + line.RecvdCost - line.InvCost))
						 ELSE @TaxRate * (((line.BOUnits + @bounits + line.RecvdUnits - line.InvUnits) * (item.CurUnitCost + @totunitcost)) / @Factor)
						 END
   	FROM dbo.vPOItemLine line
   	INNER JOIN dbo.bPOIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
   	WHERE line.POCo = @POCo
		AND line.PO = @PO
		AND line.POItem = @POItem
		AND line.POItemLine = 1
	END



bspexit:
	return



GO
GRANT EXECUTE ON  [dbo].[vspPORecItemLineGet] TO [public]
GO
