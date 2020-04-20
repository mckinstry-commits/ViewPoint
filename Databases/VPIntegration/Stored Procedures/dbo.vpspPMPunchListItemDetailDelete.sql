SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPunchListItemDetailDelete]
/************************************************************
* CREATED:     3/29/06  CHS
* Modified BY:	GF 11/11/2011 TK-09953
*
*
* USAGE:
*   Deletes PM Punch List Item Detail
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(@KeyID BIGINT)

AS
SET NOCOUNT ON;


DELETE FROM dbo.PMPD WHERE [KeyID] = @KeyID;


----(
----	@Original_PMCo bCompany,
----	@Original_Project bJob,
----	@Original_PunchList bDocument,
----	@Original_Item smallint,
----	@Original_ItemLine tinyint,
----	@Original_Description char(255),
----	@Original_Location varchar(10),
----	@Original_VendorGroup bGroup,
----	@Original_ResponsibleFirm bFirm,
----	@Original_DueDate bDate,
----	@Original_FinDate bDate,
----	@Original_UniqueAttchID uniqueidentifier
----)

----AS
----SET NOCOUNT ON;

----DELETE FROM PMPD

----WHERE
----(PMCo = @Original_PMCo)
----AND (Project = @Original_Project)
----AND (PunchList = @Original_PunchList)
----AND (Item = @Original_Item)
----AND (ItemLine = @Original_ItemLine)
----AND (Description = @Original_Description OR @Original_Description IS NULL AND Description IS NULL)
----AND (Location = @Original_Location OR @Original_Location IS NULL AND Location IS NULL)
----AND (VendorGroup = @Original_VendorGroup OR @Original_VendorGroup IS NULL AND VendorGroup IS NULL)
----AND (ResponsibleFirm = @Original_ResponsibleFirm OR @Original_ResponsibleFirm IS NULL AND ResponsibleFirm IS NULL)
----AND (DueDate = @Original_DueDate OR @Original_DueDate IS NULL AND DueDate IS NULL)
----AND (FinDate = @Original_FinDate OR @Original_FinDate IS NULL AND FinDate IS NULL)
----AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL)


GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemDetailDelete] TO [VCSPortal]
GO
