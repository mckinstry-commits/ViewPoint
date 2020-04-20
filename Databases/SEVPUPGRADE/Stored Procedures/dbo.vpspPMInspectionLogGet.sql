SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMInspectionLogGet]
/***********************************************************
* Created:     8/26/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get inspection log(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @KeyID int = Null)
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	SET NOCOUNT ON;
	


	SELECT t.KeyID
		,t.KeyID AS InspectionLogID
		,t.PMCo
		,t.Project
		,t.InspectionType
		,d.Description AS 'InspectionTypeDescription'
		,t.InspectionCode
		,t.Description
		,t.Location
		,l.Description AS 'Location Description'
		,t.InspectionDate
		,t.VendorGroup
		,t.InspectionFirm
		,f.FirmName
		,t.InspectionContact
		,m.FirstName + ' ' + m.LastName AS 'ContactName'
		,m.Phone
		,m.PhoneExt
		,m.Fax
		,m.MobilePhone
		,m.EMail
		,t.InspectorName
		,t.Status
		,c.Description AS 'StatusDescription'
		,t.Issue
		,i.Description AS 'Issue Description'
		,t.Notes
		,t.UniqueAttchID
		
		
	FROM PMIL t WITH (NOLOCK)
		INNER JOIN PMDT d WITH (NOLOCK) ON t.InspectionType=d.DocType
		LEFT JOIN PMPL l WITH (NOLOCK) ON t.PMCo=l.PMCo AND t.Project=l.Project AND t.Location=l.Location
		LEFT JOIN PMFM f WITH (NOLOCK) ON t.VendorGroup=f.VendorGroup AND t.InspectionFirm=f.FirmNumber
		LEFT JOIN PMPM m WITH (NOLOCK) ON t.VendorGroup=m.VendorGroup AND t.InspectionFirm=m.FirmNumber AND t.InspectionContact=m.ContactCode
		LEFT JOIN PMSC c WITH (NOLOCK) ON t.Status=c.Status
		LEFT JOIN PMIM i WITH (NOLOCK) ON t.PMCo=i.PMCo AND t.Project=i.Project AND t.Issue=i.Issue

	WHERE t.PMCo=@JCCo AND t.Project=@Job AND t.KeyID = ISNULL(@KeyID, t.KeyID)

	
END



GO
GRANT EXECUTE ON  [dbo].[vpspPMInspectionLogGet] TO [VCSPortal]
GO
