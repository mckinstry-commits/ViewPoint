SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPunchListDelete]
/************************************************************
* CREATED:     2/22/06  CHS
*			GF 11/11/2011 TK-09953 TK-10410
*
* USAGE:
*   Deletes PM Punch List
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;

---- TK-09953
DECLARE @rcode int, @Message varchar(255),
		@Original_PunchList nvarchar(50),
		@Original_PMCo nvarchar(50),
		@Original_Project nvarchar(50)
SET @rcode = 0
SET @Message = ''

---- GET DRAWING KEY DATA
SELECT 	@Original_PunchList = PunchList,
		@Original_PMCo = PMCo,
		@Original_Project = Project
FROM dbo.PMPU WHERE KeyID = @KeyID
IF @@ROWCOUNT = 0 RETURN

---- check for punch list items TK-10410
IF EXISTS(SELECT 1 FROM dbo.PMPI WHERE PMCo = @Original_PMCo AND Project = @Original_Project
				AND PunchList = @Original_PunchList)
	BEGIN
	SET @rcode = 1
	SET @Message = 'Punch List Items exist for this Punch List!'
	GoTo bspmessage
	END

DELETE FROM dbo.PMPU WHERE [KeyID] = @KeyID;

RETURN


bspmessage:
	RAISERROR(@Message, 11, -1);
	return @rcode


--(
--	@Original_PMCo bCompany,
--	@Original_Project bJob,
--	@Original_PunchList bDocument,
--	@Original_Description bDesc,
--	@Original_PrintOption char(1),
--	@Original_PunchListDate bDate,
--	@Original_UniqueAttchID uniqueidentifier
--)
--AS
--	SET NOCOUNT ON;
	
--DELETE FROM PMPU 

--WHERE (PMCo = @Original_PMCo) 
--AND (Project = @Original_Project) 
--AND (PunchList = @Original_PunchList) 
--AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) 
--AND (PrintOption = @Original_PrintOption) 
--AND (PunchListDate = @Original_PunchListDate OR @Original_PunchListDate IS NULL AND PunchListDate IS NULL) 
--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListDelete] TO [VCSPortal]
GO
