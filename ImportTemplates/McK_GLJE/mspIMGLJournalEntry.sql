USE Viewpoint
go

IF EXISTS (SELECT 1 FROM sysobjects WHERE type='P' AND name='mspIMGLJournalEntry')
BEGIN
PRINT 'DROP proc mspIMGLJournalEntry'
DROP proc mspIMGLJournalEntry
END 
GO

PRINT 'CREATE proc mspIMGLJournalEntry'
go

CREATE proc mspIMGLJournalEntry
/***********************************************************
* CREATED BY: Bill Orebaugh
* (Based on default proc provided by Viewpoint)
*
* Usage:
*	Used by Imports to create values for needed or missing
*  data based upon Bidtek default rules. 
*  This is designed to be used for import progress entries.
*
* This specific procedute to process McKinstry GL Journal Entries.  Its
* function is to programatically create a GL Reference Record and assign it 
* to the import batch.  Assumption is that all items in an import batch
* will be for a single Month, Journal, GL Reference.
*
* Input params:
*  @Company		Current Company
*	@ImportId	   	Import Identifier
*	@ImportTemplate	Import ImportTemplate
*  @Form  			Imporrt Form
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure

2014.11.01 - LWO -- Added ReadUncommitted to aid in parallel 
					processing.
2014.11.25 - LWO -- Added isnumeric check to ensure we get a numeric value to increment.
************************************************************/

(@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @msg varchar(120) output)

as

set nocount on

declare @rcode int, @desc varchar(120)

/* check required input params */

if @ImportId is null
 begin
 select @desc = 'Missing ImportId.', @rcode = 1
 goto bspexit
 end
if @ImportTemplate is null
 begin
 select @desc = 'Missing ImportTemplate.', @rcode = 1
 goto bspexit
 end

if @Form is null
 begin
 select @desc = 'Missing Form.', @rcode = 1
 goto bspexit
end



/*
2014.10.13 - LWO -
Review the Import Data and use the Company, Journal and Month to get the next available 
GL Reference Number from GLRF and update teh Import table with the appropriate value.
Needed for the automated generation of GL References.
*/


DECLARE @CompanyIdentifier int
DECLARE @JournalIdentifier int
DECLARE @MonthIdentifier INT
DECLARE @ReferenceIdentifier int

DECLARE @CompanyID bCompany
DECLARE @Journal bJrnl
DECLARE @Month bMonth

DECLARE  @company_count int
DECLARE  @month_count int
DECLARE  @journal_count int

DECLARE @ReferenceID int --VARCHAR(10)
DECLARE @ReferenceName VARCHAR(30)

select 
	@CompanyIdentifier = DDUD.Identifier 
From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Co'

select 
	@MonthIdentifier = DDUD.Identifier 
From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Mth'

select 
	@JournalIdentifier = DDUD.Identifier 
From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Jrnl'

select 
	@ReferenceIdentifier = DDUD.Identifier 
From IMTD
inner join DDUD on IMTD.Identifier = DDUD.Identifier and DDUD.Form = @Form
Where IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'GLRef'


SELECT @company_count=COUNT(DISTINCT ImportedVal) from IMWE WHERE Identifier=@CompanyIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'
SELECT @month_count=COUNT(DISTINCT ImportedVal) from IMWE WHERE Identifier=@MonthIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'
SELECT @journal_count=COUNT(DISTINCT ImportedVal) from IMWE WHERE Identifier=@JournalIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'

IF @company_count > 1 OR @month_count > 1 OR @journal_count > 1
BEGIN
	select @desc = 'Multiple Companies, Months, Journals not allowed.', @rcode = 1
	goto bspexit
END

SELECT @CompanyID=MAX(CAST(ImportedVal AS int)) from IMWE WHERE Identifier=@CompanyIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'
SELECT @Month=MAX(CAST(ImportedVal AS datetime)) from IMWE WHERE Identifier=@MonthIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'
SELECT @Journal=MAX(CAST(ImportedVal AS VARCHAR(10))) from IMWE WHERE Identifier=@JournalIdentifier AND ImportId=@ImportId --ImportTemplate='McK_GLJE'

--2014.11.25 - LWO - Added isnumeric check to ensure we get a numeric value to increment.
IF EXISTS ( SELECT 1 FROM GLRF WHERE GLCo=@CompanyID and Jrnl=@Journal AND Mth=@Month and isnumeric(GLRef)=1 )
BEGIN
	
	SELECT @ReferenceID = MAX(t1.GLRef) + 1
	from
	(
	SELECT 
		CAST(GLRef AS INT) AS GLRef
	FROM
		dbo.GLRF WITH (READUNCOMMITTED)
	WHERE GLCo=@CompanyID and Jrnl=@Journal AND Mth=@Month AND isnumeric(GLRef)=1	
	) t1	
	
	SELECT @ReferenceName = @Journal + ' Ref : ' + CONVERT(VARCHAR(10),@Month,102) 
	--SELECT COALESCE(GLRef,'None') AS GLRef, @Journal + ' Ref : ' + CONVERT(VARCHAR(10),@Month,102) AS GLRefDesc FROM GLRF WHERE GLCo=@CompanyID and Jrnl=@Journal AND Mth=@Month
END
ELSE
BEGIN
	SELECT @ReferenceID=1 , @ReferenceName = @Journal + ' Ref : ' + CONVERT(VARCHAR(10),@Month,102) 
END

--PRINT
--	CAST(@CompanyID AS char(20))
--+	CAST(@Month AS char(20))
--+	CAST(@Journal AS char(20))
--+	CAST(@ReferenceID AS char(40))
--+	CAST(@ReferenceName AS char(50))


BEGIN TRAN 

--- Erroring Here ---- This sucks!!!!
INSERT GLRF WITH (HOLDLOCK) ( GLCo, Mth, Jrnl, GLRef, Description, Adjust, Notes )
SELECT @CompanyID, @Month, @Journal, CAST(@ReferenceID AS VARCHAR(10)), @ReferenceName, NULL, 'IM Generated - ' + @ReferenceName


--SELECT * FROM IMWE WHERE ImportTemplate='McK_GLJE' --RecordType='GLDB'

UPDATE IMWE
SET IMWE.UploadVal = @ReferenceID
where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId  and
IMWE.Identifier = @ReferenceIdentifier 

IF @@ERROR <> 0
BEGIN
    ROLLBACK TRAN    
END
ELSE
BEGIN
	COMMIT TRAN 
END
bspexit:
   select @msg = isnull(@desc,'User Routine') + char(13) + char(10) + '[bspIMUserRoutineSample]'

   return @rcode
go




--DECLARE	@return_value int,
--		@msg varchar(120)

--EXEC	@return_value = [dbo].[mspIMGLJournalEntry]
--		@Company = 1,
--		@ImportId = N'5',
--		@ImportTemplate = N'MCKGLJE',
--		@Form = N'GLJE',
--		@msg = @msg OUTPUT

--SELECT	@return_value, @msg as N'@msg'

