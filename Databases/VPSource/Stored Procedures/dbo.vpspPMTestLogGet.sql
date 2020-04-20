SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMTestLogGet]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get PM Test Log.
************************************************************/
(@JCCo bCompany, @Job bJob, @VendorGroup bGroup, @KeyID INT = Null)
AS
SET NOCOUNT ON;

	SELECT t.KeyID
		,t.KeyID AS TestLogID
		,t.PMCo
		,t.Project
		,t.TestType
		,d.Description AS 'TestTypeDescription'
		,t.TestCode
		,t.Description
		,t.Location
		,l.Description AS 'Location Description'
		,t.TestDate
		,t.VendorGroup
		,t.TestFirm
		,f.FirmName
		,t.TestContact
		,m.FirstName + ' ' + m.LastName AS 'ContactName'
		,m.Phone
		,m.PhoneExt
		,m.Fax 
		,m.MobilePhone
		,m.EMail
		,t.TesterName
		,t.Status
		,c.Description AS 'TestStatusDescription'
		,t.Issue
		,i.Description AS 'Issue Description'
		,t.Notes
		,t.UniqueAttchID
		
	FROM PMTL t WITH (NOLOCK)
		Left Join PMDT d WITH (NOLOCK) ON t.TestType=d.DocType
		Left  Join PMPL l WITH (NOLOCK) ON t.PMCo=l.PMCo and t.Project=l.Project and t.Location=l.Location
		Left  Join PMFM f WITH (NOLOCK) ON t.VendorGroup=f.VendorGroup and t.TestFirm=f.FirmNumber
		Left  Join PMPM m WITH (NOLOCK) ON t.VendorGroup=m.VendorGroup and t.TestFirm=m.FirmNumber and t.TestContact=m.ContactCode
		Left  Join PMSC c WITH (NOLOCK) ON t.Status=c.Status
		Left  Join PMIM i WITH (NOLOCK) ON t.PMCo=i.PMCo and t.Project=i.Project and t.Issue=i.Issue
		
	WHERE t.PMCo=@JCCo and t.Project=@Job
	and t.KeyID = IsNull(@KeyID, t.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogGet] TO [VCSPortal]
GO
