SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[bspIMUserRoutinePRTBEquip]
/***********************************************************
 * CREATED BY: 
 * MODIFIED BY: AMR 01/12/11 - Issue #142350, making case sensitive by removing unused vars and renaming same named variables
 *
 * Usage:
 *    Used by Imports to update class, rate, and amount by equipment if available
 *
 * Input params:
 *  @Company		Current Company
 *	@ImportId	   	Import Identifier
 *	@ImportTemplate	Import ImportTemplate
 *  @Form  			Import Form
 *
 * Output params:
 *	@msg		error message
 *
 * Return code:
 *	0 = success, 1 = failure
 ************************************************************/

 (@Company bCompany, @ImportId VARCHAR(20), @ImportTemplate VARCHAR(20), @Form VARCHAR(20), @msg VARCHAR(120) OUTPUT)

AS

SET NOCOUNT ON

--standard routine varibles
--#142350 removed @importid
DECLARE	@rcode int, 
		@desc VARCHAR(120), -- error description
		@recseq int, -- current record
		@tablename VARCHAR(20), 
		@column VARCHAR(30),  
		@importval VARCHAR(60),
		@uploadVal VARCHAR(62),
		@opencursor int

--unique varibles per routine
DECLARE @EquipmentID int, @EMCompanyID int,@ClassID int, @EMCategory bCat, 
		@Equipment bEquip, @EMCompany bCompany, @Class bClass, 
		@RateID int, @Rate bUnitCost, @Employee bEmployee, @PostDate bDate,
		@Craft bCraft, @Shift tinyint, @EarnCode bEDLCode, @JCCo bCompany, 
		@Job bJob, @crafttemplate smallint, @Amt bDollar, @Hours bHrs, @PRGroup bGroup,
		@PREndDate bDate

DECLARE @EmployeeID int, @PostDateID int, @CraftID int, 
		@ShiftID int, @EarnCodeID int, @JCCoID int, 
		@JobID int, @AmtID int, @HoursID int, @PRGroupID int, @PREndDateID int

SELECT @rcode=0

/* check required input params */

IF @ImportId IS NULL
BEGIN
  SELECT @desc = 'Missing ImportId.', @rcode = 1
  GOTO bspexit
END

IF @ImportTemplate IS NULL
BEGIN
  SELECT @desc = 'Missing ImportTemplate.', @rcode = 1
  GOTO bspexit
END

IF @Form IS NULL
BEGIN
  SELECT @desc = 'Missing Form.', @rcode = 1
  GOTO bspexit
END

SELECT @EquipmentID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Equipment'

SELECT @EMCompanyID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EMCo'

SELECT @ClassID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Class'

SELECT @RateID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Rate'

SELECT @EmployeeID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Employee'

SELECT @PostDateID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PostDate'

SELECT @CraftID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Craft'

SELECT @ShiftID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Shift'

SELECT @EarnCodeID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'EarnCode'

SELECT @JobID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Job'

SELECT @JCCoID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'JCCo'

SELECT @AmtID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Amt'

SELECT @HoursID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'Hours'

SELECT @PRGroupID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PRGroup'

SELECT @PREndDateID=DDUD.Identifier FROM IMTD WITH (NOLOCK)
      INNER JOIN DDUD WITH (NOLOCK) on IMTD.Identifier = DDUD.Identifier AND DDUD.Form = @Form
      WHERE IMTD.ImportTemplate=@ImportTemplate AND DDUD.ColumnName = 'PREndDate'

DECLARE WorkEditCursor CURSOR FOR
 SELECT DISTINCT IMWE.RecordSeq
 FROM IMWE WITH (NOLOCK) 
 WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form
 ORDER BY IMWE.RecordSeq

OPEN WorkEditCursor
-- SET OPEN CURSOR flag
SET @opencursor=1

FETCH NEXT FROM WorkEditCursor INTO @recseq
-- WHILE CURSOR is not empty
WHILE @@fetch_status = 0
BEGIN
	--reset values FROM prev record
	SELECT @EMCompany=NULL,@Equipment=NULL,@EMCategory=NULL,@Class=NULL

	--EMCO
    SELECT @EMCompany=UploadVal 
	FROM IMWE 
    WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@EMCompanyID

	--Equipment
	SELECT @Equipment=UploadVal 
	FROM IMWE 
    WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@EquipmentID

	--Rate
	SELECT @Rate = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@RateID

	--Employee
	SELECT @Employee = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@EmployeeID

	--PostDate
	SELECT @PostDate = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@PostDateID

	--Craft
	SELECT @Craft = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@CraftID

	--Shift
	SELECT @Shift = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@ShiftID

	--EarnCode
	SELECT @EarnCode = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@EarnCodeID

	--JCCo
	SELECT @JCCo= UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@JCCoID

	--Job
	SELECT @Job= UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@JobID

	--Hours
	SELECT @Hours = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@HoursID	

	--PRGroup
	SELECT @PRGroup = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@PRGroupID

	--PREndDate
	SELECT @PREndDate = UploadVal
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@PREndDateID

	--CraftTemplate
	SELECT @crafttemplate=CraftTemplate 
	FROM JCJM WITH (NOLOCK) 
	WHERE JCCo=@JCCo AND Job=@Job

	--Category
	SELECT @EMCategory=Category 
	FROM EMEM 
	WHERE EMCo=@EMCompany AND Equipment=@Equipment

	--Class
	SELECT @Class=PRClass 
	FROM EMCM 
	WHERE EMCo=@EMCompany AND Category=@EMCategory


  --UPDATE if class found
  IF @@rowcount=1 AND ISNULL(@Class,'')<>'' AND ISNULL(@Equipment,'')<>'' AND ISNULL(@Craft, '')<>'' AND ISNULL(@Company,'') <> '' AND ISNULL(@Employee,'') <> '' AND ISNULL(@EarnCode,'') <> ''
  BEGIN
	UPDATE IMWE SET UploadVal=@Class
	FROM IMWE
	WHERE IMWE.ImportId = @ImportId AND IMWE.ImportTemplate = @ImportTemplate AND IMWE.Form = @Form AND IMWE.RecordSeq=@recseq AND IMWE.Identifier=@ClassID
		
	EXEC bspPRRateDefault @Company, @Employee, @PostDate, @Craft, @Class, @crafttemplate, @Shift, @EarnCode, @Rate output, @desc output		 
 
	UPDATE IMWE
	SET IMWE.UploadVal = @Rate
	WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@recseq AND IMWE.Identifier = @RateID
 
	EXEC @rcode = bspIMPRTB_AMT @Company, @Employee, @EarnCode, @Hours, @PRGroup, @PREndDate, @Rate output, @Amt output,  @desc output
 
	IF ISNULL(@Amt,0) = 0 SELECT @Amt = 0

	UPDATE IMWE
	SET IMWE.UploadVal = @Amt
	WHERE IMWE.ImportTemplate=@ImportTemplate AND IMWE.ImportId=@ImportId AND IMWE.RecordSeq=@recseq AND IMWE.Identifier = @AmtID
					
  END
	-- loop through each identifier in this record
  FETCH NEXT FROM WorkEditCursor INTO @recseq
END

CLOSE WorkEditCursor
DEALLOCATE WorkEditCursor
SET @opencursor=0

bspexit:
  --in case we exit out early clear CURSOR
  IF @opencursor = 1
  BEGIN
    CLOSE WorkEditCursor
    DEALLOCATE WorkEditCursor
  END
  SELECT @msg = ISNULL(@desc,'User Routine') + ' ' + 'bspIMUserRoutinePRTBEquip'
  RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMUserRoutinePRTBEquip] TO [public]
GO
