SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vpspPMMeetingMinutesLinesGet]
/***********************************************************
* Created:     9/1/09		JB		Rewrote SP/cleanup
* Modified:	
* 
* Description:	Get the meeting minutes Line(s).
************************************************************/
(@JCCo bCompany, @Job bJob, @MeetingType bDocType, @Meeting INT, @MinutesType TINYINT, @Item TINYINT, @VendorGroup bGroup, @KeyID BIGINT = NULL)
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT i.KeyID
		, i.PMCo
		, i.Project
		, i.MeetingType
		, i.Meeting
		, i.MinutesType
		, i.Item
		, CAST(i.ItemLine AS VARCHAR(3)) AS 'ItemLine'
		, RTRIM(i.Description) AS Description
		, i.VendorGroup
		, i.ResponsibleFirm
		, i.ResponsiblePerson
		, i.InitDate
		, i.DueDate
		, i.FinDate
		, i.Status
		, i.UniqueAttchID
		, i.Notes
		, c.Description AS 'StatusDescription'
		, f2.FirmName AS 'ResFirmName'
		, m2.FirstName + ' ' + m2.LastName AS 'ResPersonName'
		, CASE i.MinutesType WHEN 0 THEN 'Agenda' ELSE 'Minutes' END AS'MeetingMinutesDescription'
		, SUBSTRING(i.Description, 1, 50) AS 'DescriptionTrunc'

	FROM PMML i WITH (NOLOCK)
		LEFT JOIN PMSC c WITH (NOLOCK) ON i.Status = c.Status
		LEFT JOIN PMFM f2 WITH (NOLOCK) ON i.VendorGroup = f2.VendorGroup AND i.ResponsibleFirm = f2.FirmNumber
		LEFT JOIN PMPM m2 WITH (NOLOCK) ON i.VendorGroup = m2.VendorGroup AND i.ResponsibleFirm = m2.FirmNumber AND i.ResponsiblePerson = m2.ContactCode

	WHERE i.PMCo = @JCCo 
		AND i.Project = @Job
		AND i.MeetingType = @MeetingType 
		AND i.Meeting = @Meeting 
		AND i.MinutesType = @MinutesType
		AND i.Item = @Item
		AND i.KeyID = ISNULL(@KeyID, i.KeyID)
END
GO
GRANT EXECUTE ON  [dbo].[vpspPMMeetingMinutesLinesGet] TO [VCSPortal]
GO
