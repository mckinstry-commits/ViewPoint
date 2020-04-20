SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMMyPOChangeOrderGet] 
/************************************************************
* CREATED:		10/24/07	CHS
* Modified:		07/17/2008	CHS
*
* USAGE:
*   Returns PM Purchase Orders
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID int = Null)

AS
SET NOCOUNT ON;

select 
c.POCo, c.PO, c.ChangeOrder, c.ActDate, c.Job, c.SumChangeCurCost, c.KeyID,
c.Phase, c.Material, c.MaterialDesc

from pvPMMyPOChangeOrder c with (nolock)

Where c.POCo=@JCCo and c.Job = @Job and c.ChangeOrder <> ''
and KeyID = IsNull(@KeyID, c.KeyID)
GO
GRANT EXECUTE ON  [dbo].[vpspPMMyPOChangeOrderGet] TO [VCSPortal]
GO
