SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPMTestLogDelete]
/************************************************************
* CREATED:     1/10/06  CHS
*
* USAGE:
*   Deletes the PM Test Logs	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@Original_PMCo nvarchar(50),
	@Original_Project nvarchar(50),
	@Original_TestType nvarchar(50),
	@Original_TestCode nvarchar(50),
	@Original_Description nvarchar(50),
	@Original_Location varchar(10),
	@Original_TestDate bDate,
	@Original_VendorGroup nvarchar(50),
	@Original_TestFirm nvarchar(50),
	@Original_TestContact nvarchar(50),
	@Original_TesterName nvarchar(50),
	@Original_Status nvarchar(50),
	@Original_Issue nvarchar(50),
	@Original_Notes nvarchar(50),
	@Original_UniqueAttchID uniqueidentifier
)

AS
	SET NOCOUNT ON;
	
DELETE FROM PMTL
	
WHERE
	(PMCo = @Original_PMCo)
	AND (Project = @Original_Project)
	AND (TestType = @Original_TestType)
	AND (TestCode = @Original_TestCode)

	




GO
GRANT EXECUTE ON  [dbo].[vpspPMTestLogDelete] TO [VCSPortal]
GO
