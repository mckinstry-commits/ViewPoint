SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vfSLITWithPMSLInfo](@Company int, @Subcontract varchar(30), @SLItem smallint)
RETURNS TABLE
AS
/********************************************
* Created By:	GF 04/15/2010 - issue #138434
* Modified By:
*
* returns PM Subcontract Detail for SL items
* used in view SLITPM.
*
********************************************/

RETURN (SELECT top 1 f.InterfaceDate, f.ACO, f.ACOItem, f.PCOType, f.PCO, f.PCOItem, f.SubCO
			FROM dbo.bPMSL f with (nolock)
			where f.SLCo=@Company and f.SL=@Subcontract and f.SLItem=@SLItem and InterfaceDate is not null
			order by f.InterfaceDate desc, f.ACO desc, f.ACOItem desc, f.PCOType desc,
			f.PCO desc, f.PCOItem desc, f.SubCO)
GO
GRANT SELECT ON  [dbo].[vfSLITWithPMSLInfo] TO [public]
GO
