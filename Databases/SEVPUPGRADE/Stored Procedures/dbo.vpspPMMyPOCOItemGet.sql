SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMMyPOCOItemGet]
/************************************************************
* CREATED:		10/24/07	CHS
* MODIFIED:		07/17/2008	CHS	issue #12597
*	TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
* USAGE:
*   Returns PM Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
************************************************************/
(@JCCo bCompany, @Job bJob, @PO varchar(30), @KeyID int = Null)

AS
SET NOCOUNT ON;

select
c.POCo, c.Mth, c.POTrans, c.PO, c.POItem, c.ChangeOrder, c.ActDate, 
c.Description, c.UM, c.ChangeCurUnits, c.CurUnitCost, c.ECM, 
c.ChangeCurCost, c.ChangeBOUnits, c.ChangeBOCost, c.BatchId, 
c.PostedDate, c.InUseBatchId, c.Notes, c.UniqueAttchID, c.Seq, 
c.ChgTotCost, c.PurgeYN, c.KeyID, i.Phase, i.JCCType as 'CostType', i.Material,
i.UM, m.Description as 'MaterialDesc'

from POCD c with (nolock)
	left join POIT i with (nolock) on c.POCo = i.POCo and c.PO = i.PO and c.POItem = i.POItem
	left join HQMT m with (nolock) on i.MatlGroup = m.MatlGroup and i.Material = m.Material

Where c.POCo=@JCCo and i.Job = @Job and @PO = c.PO and c.KeyID = IsNull(@KeyID, c.KeyID)



GO
GRANT EXECUTE ON  [dbo].[vpspPMMyPOCOItemGet] TO [VCSPortal]
GO
