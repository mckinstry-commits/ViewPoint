SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[vpspHRDependentsItemDelete]
/************************************************************
* CREATED:     SDE 6/6/2006
* MODIFIED:    
*
* USAGE:
*   Deletes an HR Resource Dependent
*	
*
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*            
*
* OUTPUT PARAMETERS
*   
* RETURN VALUE
*   
************************************************************/
(
	@Original_HRCo bCompany,
	@Original_HRRef bHRRef,
	@Original_Seq smallint,
	@Original_Address varchar(60),
	@Original_BirthDate bDate,
	@Original_City varchar(30),
	@Original_HistSeq int,
	@Original_Name varchar(30),
	@Original_Phone bPhone,
	@Original_Relationship varchar(30),
	@Original_SSN char(11),
	@Original_Sex char(1),
	@Original_State bState,
	@Original_UniqueAttchID uniqueidentifier,
	@Original_WorkPhone bPhone,
	@Original_Zip bZip
)
AS
	SET NOCOUNT OFF;
DELETE FROM HRDP WHERE (HRCo = @Original_HRCo) AND (HRRef = @Original_HRRef) AND (Seq = @Original_Seq) AND (Address = @Original_Address OR @Original_Address IS NULL AND Address IS NULL) AND (BirthDate = @Original_BirthDate OR @Original_BirthDate IS NULL AND BirthDate IS NULL) AND (City = @Original_City OR @Original_City IS NULL AND City IS NULL) AND (HistSeq = @Original_HistSeq OR @Original_HistSeq IS NULL AND HistSeq IS NULL) AND (Name = @Original_Name) AND (Phone = @Original_Phone OR @Original_Phone IS NULL AND Phone IS NULL) AND (Relationship = @Original_Relationship OR @Original_Relationship IS NULL AND Relationship IS NULL) AND (SSN = @Original_SSN OR @Original_SSN IS NULL AND SSN IS NULL) AND (Sex = @Original_Sex) AND (State = @Original_State OR @Original_State IS NULL AND State IS NULL) AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) AND (WorkPhone = @Original_WorkPhone OR @Original_WorkPhone IS NULL AND WorkPhone IS NULL) AND (Zip = @Original_Zip OR @Original_Zip IS NULL AND Zip IS NULL)



GO
GRANT EXECUTE ON  [dbo].[vpspHRDependentsItemDelete] TO [VCSPortal]
GO
