SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesItemsGet]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get the meeting minutes item(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @MeetingType bDocType, @Meeting INT, @MinutesType TINYINT, @VendorGroup bGroup, @KeyID BIGINT = NULL)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT i.KeyID, 
		i.PMCo, 
		i.Project, 
		i.MeetingType, 
		i.Meeting, 
		i.MinutesType, 
		CAST(i.Item AS VARCHAR(10)) AS 'Item', 
		i.OriginalItem, 
		i.Minutes, 
		i.VendorGroup, 
		i.InitFirm, 
		i.Initiator, 
		m.FirstName + ' ' + m.LastName AS 'InitiatorName',
		i.ResponsibleFirm, i.ResponsiblePerson, 
		m2.FirstName + ' ' + m2.LastName AS 'ResPersonName',
		i.InitDate, 
		i.DueDate, 
		i.FinDate, 
		c.Description AS 'StatusDescription',
		i.Status, 
		i.Issue, 
		s.Description AS 'IssueDescription', 
		i.UniqueAttchID,
		f.FirmName AS 'InitFirmName', 
		f2.FirmName AS 'ResFirmName',
		CASE i.MinutesType 
			WHEN 0 THEN 'Agenda' 
			ELSE 'Minutes' 
			END AS 'MeetingMinutesDescription',
		SUBSTRING(Minutes, 1, 90) AS 'MinutesTrunc'

	FROM PMMI i WITH (NOLOCK)
		LEFT JOIN PMSC c WITH (NOLOCK) ON i.Status = c.Status
		LEFT JOIN PMPM m WITH (NOLOCK) ON i.VendorGroup = m.VendorGroup AND i.InitFirm = m.FirmNumber AND i.Initiator = m.ContactCode
		LEFT JOIN PMPM m2 WITH (NOLOCK) ON i.VendorGroup = m2.VendorGroup AND i.ResponsibleFirm = m2.FirmNumber AND i.ResponsiblePerson = m2.ContactCode
		LEFT JOIN PMIM s WITH (NOLOCK) ON i.PMCo = s.PMCo AND i.Project = s.Project AND i.Issue = s.Issue
		LEFT JOIN PMFM f WITH (NOLOCK) ON i.VendorGroup = f.VendorGroup AND i.InitFirm = f.FirmNumber
		LEFT JOIN PMFM f2 WITH (NOLOCK) ON i.VendorGroup = f2.VendorGroup AND i.ResponsibleFirm = f2.FirmNumber

	WHERE i.PMCo = @JCCo 
		AND i.Project = @Job 
		AND i.VendorGroup = @VendorGroup
		AND i.MeetingType = @MeetingType 
		AND i.Meeting = @Meeting 
		AND i.MinutesType = @MinutesType
		AND i.KeyID = ISNULL(@KeyID, i.KeyID)

END
GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesItemsGet] TO [VCSPortal]
GO
