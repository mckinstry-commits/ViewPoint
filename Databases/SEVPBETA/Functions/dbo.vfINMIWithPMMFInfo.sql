SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfINMIWithPMMFInfo](@Company int, @MaterialOrder varchar(30), @MOItem smallint)
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/15/2010 - issue #138434
* Modified By:
*
* returns PM Material Detail for MO items
* used in view IHMIPM.
*
********************************************/

RETURN (SELECT top 1 f.InterfaceDate, f.ACO, f.ACOItem, f.PCOType, f.PCO, f.PCOItem
			FROM dbo.bPMMF f with (nolock)
			where f.INCo=@Company and f.MO=@MaterialOrder and f.MOItem=@MOItem and InterfaceDate is not null
			order by f.InterfaceDate desc, f.ACO desc, f.ACOItem desc, f.PCOType desc,
			f.PCO desc, f.PCOItem desc)
GO
GRANT SELECT ON  [dbo].[vfINMIWithPMMFInfo] TO [public]
GO
