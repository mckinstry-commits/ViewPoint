SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  PROCEDURE [dbo].[vpspPMPunchListItemDelete]
/************************************************************
* CREATED:     2/22/06  CHS
* Modified By:	GF 11/11/2011 TK-09953
*
*
* USAGE:
*   Deletes PM Punch List Items
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


DELETE FROM dbo.PMPI WHERE [KeyID] = @KeyID;


--(
--	@Original_Item smallint,
--	@Original_PMCo bCompany,
--	@Original_Project bJob,
--	@Original_PunchList bDocument,
--	@Original_BillableFirm bFirm,
--	@Original_BillableYN bYN,
--	@Original_Description char(255),
--	@Original_DueDate bDate,
--	@Original_FinDate bDate,
--	@Original_Issue bIssue,
--	@Original_Location varchar(10),
--	@Original_ResponsibleFirm bFirm,
--	@Original_UniqueAttchID uniqueidentifier,
--	@Original_VendorGroup bGroup
--)
--AS
--	SET NOCOUNT ON;


--IF @Original_Issue = -1 SET @Original_Issue = NULL
--IF @Original_BillableFirm = -1 SET @Original_BillableFirm = NULL
--IF @Original_ResponsibleFirm = -1 SET @Original_ResponsibleFirm = NULL

--DELETE FROM PMPI 

--WHERE (Item = @Original_Item) 
--AND (PMCo = @Original_PMCo) 
--AND (Project = @Original_Project) 
--AND (PunchList = @Original_PunchList) 
--AND (BillableFirm = @Original_BillableFirm OR @Original_BillableFirm IS NULL AND BillableFirm IS NULL) 
--AND (BillableYN = @Original_BillableYN) 
--AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL) 
--AND (DueDate = @Original_DueDate OR @Original_DueDate IS NULL AND DueDate IS NULL) 
--AND (FinDate = @Original_FinDate OR @Original_FinDate IS NULL AND FinDate IS NULL) 
--AND (Issue = @Original_Issue OR @Original_Issue IS NULL AND Issue IS NULL) 
--AND (Location = @Original_Location OR @Original_Location IS NULL AND Location IS NULL) 
--AND (ResponsibleFirm = @Original_ResponsibleFirm OR @Original_ResponsibleFirm IS NULL AND ResponsibleFirm IS NULL) 
--AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
--AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemDelete] TO [VCSPortal]
GO
