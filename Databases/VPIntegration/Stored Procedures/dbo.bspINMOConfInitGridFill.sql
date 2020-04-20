SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    Proc [dbo].[bspINMOConfInitGridFill]
   /*************************************
   	Created: 05/02/02 RM
   	Modified 02/16/06 TRL for VP6...Added alias names for columns.
   		5/21/12 JB - Modified to correct the totals
   	Usage:
   		Used to fill confirmations initialization grid.
   
   	In:
   		@co		IN Company
   		@mo		Material Order
   		@all	Confirm All (Y/N)
   	
   	Out:
   		Recordset of Items
   	
   *************************************/
   (@co bCompany,@mo bMO,@all bYN)
   AS
  
SELECT	i.MOItem AS Item,
		i.Loc AS Location,
		i.Material,
		i.[Description],
		i.UM, 
		ISNULL(i.OrderedUnits,0) AS Ordered, 
		(i.ConfirmedUnits + (SELECT ISNULL(SUM(ConfirmUnits), 0) FROM INCB WHERE MO = i.MO AND MOItem = i.MOItem)) AS ConfirmedToDate,
		CASE @all WHEN 'Y' THEN (i.RemainUnits + (SELECT ISNULL(SUM(RemainUnits), 0) FROM INCB WHERE MO = i.MO AND MOItem = i.MOItem)) ELSE 0 END AS ConfirmThisTime,
		CASE @all WHEN 'N' THEN (i.RemainUnits + (SELECT ISNULL(SUM(RemainUnits), 0) FROM INCB WHERE MO = i.MO AND MOItem = i.MOItem)) ELSE 0 END AS Remaining, 
		(i.ConfirmedUnits + (SELECT ISNULL(SUM(ConfirmUnits), 0) FROM dbo.INCB WHERE MO = i.MO AND MOItem = i.MOItem) + i.RemainUnits + (SELECT ISNULL(SUM(RemainUnits), 0) FROM dbo.INCB WHERE MO = i.MO AND MOItem = i.MOItem)) AS Total
FROM dbo.INMI i WHERE INCo = @co AND MO = @mo

GO
GRANT EXECUTE ON  [dbo].[bspINMOConfInitGridFill] TO [public]
GO
