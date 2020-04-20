
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPORBGridRecAll    Script Date: 02/09/2000 9:36:08 AM ******/
CREATE  proc [dbo].[bspPORBGridRecAll]
/****************************************************************************
* CREATED BY: 	DANF 02/07/2000
* MODIFIED BY:	MV 03/17/03 - #20615 added vendor material to the select.
*				DC 08/11/06 - The duplicate column name 'RecvdUnits' was causing a
*								problem with the grid and it is easy enough to change
*				DANF 08/15/06 - #122169 Incorrect syntax error near b - moved the end to before the bspexit.
*				DC 7/10/07 - #28538 - added OrigUnitCost to the select statement
*				DC 8/9/07 - #28538 - added CostThisTime to the select statement
*				DC 03/26/08 - #127596  -Rounding problems on Units Recv'd This Time, Backordered
*				DC 10/30/08 - #30224  - Rounding problems with 3 digit units causing incorrect backorder
*				DC 1/27/09  - #130559 - open notes field in PO Init
*				DC 5/6/2009 - #132430 - Add grid columns to PO Init Grid
*				DC 08/24/09 - #134137 - When using PO Init Receipts, Cost This Time in grid does not look at ECM
*				DC 01/29/10 - #136933 - PO's with a 7 digit curcost causes arithmatic overflow error
*										For this issue I replaced every instance of Decimal(11,3) and Decimal(9,3) with Decimal(15,3)
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 08/22/2011 - TK-07879 PO ITEM LINE
*				DKS 6/24/13 - Bug 52677 - SM PO's now show up in Initialize Receipts
*				DKS 07/18/13 - Removed another exclusion of SM PO's
*
*
* USAGE:
* 	Fills grid in PO Receipts
*
* INPUT PARAMETERS:
*
* OUTPUT PARAMETERS:
*
*	See Select statement below
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@POCo bCompany = null, @PO varchar(30), @Rec bYN)

as
set nocount on

declare @rcode as integer

SET @rcode = 0

BEGIN

----TK-07879
IF @Rec = 'Y'
	BEGIN
	SELECT  line.POItem,
			line.POItemLine,
			item.VendMatId,
			item.Material,
			item.Description,
			item.UM, 
			item.OrigUnitCost,				
			CurUnits = CASE item.UM WHEN 'LS' THEN line.CurCost ELSE line.CurUnits END, 
			item.OrigECM,  --DC #134137			
			--DC #30224
			RecvdUnits = CASE item.UM WHEN 'LS' THEN CAST(line.RecvdCost + ISNULL(SUM(b.RecvdCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.RecvdUnits + ISNULL(SUM(b.RecvdUnits), 0) AS DECIMAL(15,3)) END,				
			--DC #30224					
			RecvdUnitsNow = CASE item.UM WHEN 'LS' THEN CAST(line.BOCost + ISNULL(SUM(b.BOCost), 0) AS DECIMAL(15,5))
							ELSE CAST(line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END,
			CostThisTime = 0.000,			
			--DC #30224
			OldBOUnits = CASE item.UM WHEN 'LS' THEN CAST(line.BOCost + ISNULL(SUM(b.BOCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END, 				
			BOUnits =0.000,			
			--DC #30224
			TotalUnits = CASE item.UM WHEN 'LS' THEN CAST(line.RecvdCost + ISNULL(SUM(b.RecvdCost), 0) + line.BOCost + isnull(sum(b.BOCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.RecvdUnits + ISNULL(SUM(b.RecvdUnits), 0) + line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END, 
			line.JCCo, line.Job,
			m.Description as 'JobDesc',	--DC #132430			
			Notes = ''	
	FROM dbo.POItemLine line
	INNER JOIN dbo.POIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem	
	LEFT OUTER JOIN dbo.PORB b on b.Co=line.POCo and b.PO=line.PO and b.POItem=line.POItem AND b.POItemLine=line.POItemLine
	LEFT OUTER JOIN dbo.JCJM m on m.JCCo = line.JCCo and m.Job = line.Job  --DC #132430						
	----FROM POIT t with (nolock) 
	WHERE line.POCo= @POCo 
		AND line.PO= @PO 
		AND item.RecvYN='Y'
	GROUP BY line.POItem, line.POItemLine, item.VendMatId, item.Material, line.BOCost, line.BOUnits,
		item.Description , item.UM, line.RecvdCost, line.RecvdUnits, line.CurUnits, line.CurCost, 
		item.OrigUnitCost, line.Notes, line.JCCo, line.Job, m.Description,  --DC #130559
		item.OrigECM  --DC #134137
	END
ELSE
	BEGIN
	SELECT  line.POItem,
			line.POItemLine,
			item.VendMatId,
			item.Material,
			item.Description,
			item.UM, 
			item.OrigUnitCost,						
			CurUnits = CASE item.UM WHEN 'LS' THEN line.CurCost ELSE line.CurUnits END,
			item.OrigECM,  --DC #134137			 
			--DC #30224
			RecvdUnits = CASE item.UM WHEN 'LS' THEN CAST(line.RecvdCost + ISNULL(SUM(b.RecvdCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.RecvdUnits + ISNULL(SUM(b.RecvdUnits), 0) AS DECIMAL(15,3)) END, 				
			RecvdUnitsNow =0.000,
			CostThisTime = 0.000,			
			--DC #30224
			OldBOUnits = CASE item.UM WHEN 'LS' THEN CAST(line.BOCost + ISNULL(SUM(b.BOCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END,				
			--DC #30224
			BOUnits = CASE item.UM WHEN 'LS' THEN CAST(line.BOCost + ISNULL(SUM(b.BOCost),0) AS DECIMAL(15,5))
					  ELSE CAST(line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END,				
			--DC #30224
			TotalUnits = CASE item.UM WHEN 'LS' THEN CAST(line.RecvdCost + ISNULL(SUM(b.RecvdCost), 0) + line.BOCost + ISNULL(SUM(b.BOCost), 0) AS DECIMAL(15,5))
						 ELSE CAST(line.RecvdUnits + ISNULL(SUM(b.RecvdUnits), 0) + line.BOUnits + ISNULL(SUM(b.BOUnits), 0) AS DECIMAL(15,3)) END, 
			line.JCCo, line.Job,
			m.Description as 'JobDesc',	--DC #132430			
			Notes = ''
	FROM dbo.POItemLine line
	INNER JOIN dbo.POIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem	
	LEFT OUTER JOIN dbo.PORB b on b.Co=line.POCo and b.PO=line.PO and b.POItem=line.POItem AND b.POItemLine=line.POItemLine
	LEFT OUTER JOIN dbo.JCJM m on m.JCCo = line.JCCo and m.Job = line.Job  --DC #132430						
	----FROM POIT t with (nolock) 
	WHERE line.POCo= @POCo 
		AND line.PO= @PO 
		AND item.RecvYN='Y'
	GROUP BY line.POItem, line.POItemLine, item.VendMatId, item.Material, line.BOCost, line.BOUnits,
		item.Description , item.UM, line.RecvdCost, line.RecvdUnits, line.CurUnits, line.CurCost, 
		item.OrigUnitCost, line.Notes, line.JCCo, line.Job, m.Description,  --DC #130559
		item.OrigECM  --DC #134137										
	--FROM POIT t with (nolock) 
	--	left outer join PORB b on b.Co=POCo and b.PO=t.PO and b.POItem=t.POItem
	--	left outer join JCJM m on m.JCCo = t.JCCo and m.Job = t.Job  --DC #132430
	--WHERE t.POCo= @POCo and t.PO=@PO and t.RecvYN='Y' 
	--GROUP BY
	--	t.POItem,t.VendMatId, t.Material, t.BOCost, t.BOUnits,
	--	t.Description , t.UM, t.RecvdCost, t.RecvdUnits, t.CurUnits, t.CurCost,
	--	t.OrigUnitCost,t.Notes, t.JCCo, t.Job, m.Description,  --DC #130559
	--	t.OrigECM  --DC #134137
	END
END



bspexit:
	return @rcode


GO

GRANT EXECUTE ON  [dbo].[bspPORBGridRecAll] TO [public]
GO
