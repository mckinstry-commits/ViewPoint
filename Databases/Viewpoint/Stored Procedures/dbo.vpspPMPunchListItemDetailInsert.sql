SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMPunchListItemDetailInsert]
/************************************************************
* CREATED:     3/29/06  CHS
* Modified:		5/21/07 chs
*				GF 12/06/2011 TK-10599
*
* USAGE:
*   Inserts PM Punch List Item Detail
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
(
	@PMCo bCompany,
	@Project bJob,
	@PunchList bDocument,
	@Item smallint,
	@ItemLine tinyint,
	@Description VARCHAR(255),
	@Location varchar(10),
	@VendorGroup bGroup,
	@ResponsibleFirm bFirm,
	@DueDate bDate,
	@FinDate bDate,
	@UniqueAttchID uniqueidentifier,
	@ItemLineDescription VARCHAR(255)
)
AS
	SET NOCOUNT ON;

IF @ResponsibleFirm = -1 SET @ResponsibleFirm = NULL

Set @ItemLine = (Select IsNull((Max(ItemLine)+1),1) from PMPD with (nolock) 
	where PMCo = @PMCo 
	and Project = @Project 
	and PunchList = @PunchList
	and Item = @Item  )

INSERT 
INTO PMPD(PMCo, Project, PunchList, Item, ItemLine, Description, Location, 
VendorGroup, ResponsibleFirm, DueDate, FinDate, UniqueAttchID) 

VALUES (@PMCo, @Project, @PunchList, @Item, @ItemLine, @ItemLineDescription, 
@Location, @VendorGroup, @ResponsibleFirm, @DueDate, @FinDate, @UniqueAttchID);


DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspPMPunchListItemDetailGet @PMCo, @Project, @PunchList, @Item, @VendorGroup, @KeyID

/*	SELECT PMCo, Project, PunchList, Item, ItemLine, Description, Location, 
	VendorGroup, ResponsibleFirm, DueDate, FinDate, UniqueAttchID 

	FROM PMPD with (nolock)*/



GO
GRANT EXECUTE ON  [dbo].[vpspPMPunchListItemDetailInsert] TO [VCSPortal]
GO
