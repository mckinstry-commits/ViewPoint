SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMMyPOItemCOGet]
/************************************************************
* CREATED:		10/25/2007	CHS
* MODIFIED:		07/22/2008	CHS #125923
*		TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
* USAGE:
*   Returns PM Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, PO, POItem
************************************************************/
(@JCCo bCompany, @PO varchar(30), @POItem bItem, @KeyID int = Null)

AS
SET NOCOUNT ON;

select
c.POCo, c.Mth, c.POTrans, c.PO, c.POItem, c.ChangeOrder, c.ActDate, 
c.Description, c.UM, c.ChangeCurUnits, c.CurUnitCost, c.ECM, 
c.ChangeCurCost, c.ChangeBOUnits, c.ChangeBOCost, c.BatchId, 
c.PostedDate, c.InUseBatchId, c.Notes, c.UniqueAttchID, c.Seq, 
c.ChgTotCost, c.PurgeYN, c.KeyID,
i.Phase, p.Description as 'PhaseDesc', i.JCCType, i.Material, m.Description as 'MaterialDesc'

from POCD c with (nolock)
	left join POIT i with (nolock) on c.POCo=i.POCo and c.PO=i.PO and c.POItem=i.POItem 
	left join HQMT m with (nolock) on i.MatlGroup = m.MatlGroup and i.Material = m.Material
	Left Join JCJP p with (nolock) on p.JCCo=c.POCo and p.Job=i.Job and p.PhaseGroup=i.PhaseGroup and p.Phase=i.Phase

Where c.POCo=@JCCo and c.PO=@PO and c.POItem=@POItem and c.KeyID = IsNull(@KeyID, c.KeyID)


GO
GRANT EXECUTE ON  [dbo].[vpspPMMyPOItemCOGet] TO [VCSPortal]
GO
