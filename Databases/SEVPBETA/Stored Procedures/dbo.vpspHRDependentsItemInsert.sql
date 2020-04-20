SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRDependentsItemInsert]
/************************************************************
* CREATED:		6/6/2006	SDE 
* MODIFIED:		6/12/07		CHS   
*				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*
* USAGE:
*   Inserts a new HR Resource Dependent
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
	@HRCo bCompany,
	@HRRef bHRRef,
	--@Seq smallint,
	@Seq varchar(5),
	@Name varchar(30),
	@Relationship varchar(30),
	@BirthDate bDate,
	@SSN char(11),
	@Sex char(1),
	@HistSeq int,
	@Address varchar(60),
	@City varchar(30),
	@State bState,
	@Zip bZip,
	@Phone bPhone,
	@WorkPhone bPhone,
	@Notes VARCHAR(MAX),
	@UniqueAttchID uniqueidentifier
)
AS
	SET NOCOUNT ON;

--if @Seq is null
if (isnull(@Seq,'') = '') or @Seq = '+' or @Seq = 'n' or @Seq = 'N'
	begin
	set @Seq = (Select IsNull((Max(Seq)+1),1) from HRDP with (nolock) 
					where HRCo = @HRCo and HRRef = @HRRef)
	end

INSERT INTO 
	HRDP(HRCo, HRRef, Seq, Name, Relationship, BirthDate, SSN, Sex, 
	HistSeq, Address, City, State, Zip, Phone, WorkPhone, Notes, UniqueAttchID) 

VALUES (@HRCo, @HRRef, @Seq, @Name, @Relationship, @BirthDate, @SSN, @Sex, 
	@HistSeq, @Address, @City, @State, @Zip, @Phone, @WorkPhone, @Notes, @UniqueAttchID);

DECLARE @KeyID int
SET @KeyID = SCOPE_IDENTITY()
execute vpspHRDependentsItemGet @HRCo, @HRRef, @KeyID
	



GO
GRANT EXECUTE ON  [dbo].[vpspHRDependentsItemInsert] TO [VCSPortal]
GO
