SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
 CREATE PROCEDURE [dbo].[vpspHRResourceItemUpdate]
 /************************************************************
 * CREATED:     SDE 6/12/2006
 * MODIFIED:    AR 12/6/2010 - 142422 - removing depreciated call to bspHRPRUpdate 
					because this is done in triggers now
				AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
 *
 * USAGE:
 *   Updates the HR Resource 
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
	@HRCo bCompany, 
	@HRRef bHRRef, 
	@PRCo bCompany, 
	@PREmp bEmployee, 
	@LastName varchar(30),
	@FirstName varchar(30),
	@MiddleName varchar(15),
	@SortName varchar(15),
	@Address varchar(60),
	@City varchar(30),
	@State bState,
	@Zip bZip,
	@Address2 varchar(60),
	@Phone bPhone,
	@WorkPhone bPhone,
	@Pager bPhone,
	@CellPhone bPhone,
	@SSN char(11),
	@Sex char(1),
	@Race char(2),
	@BirthDate smalldatetime,
	@HireDate bDate,
	@TermDate bDate,
	@TermReason varchar(20),
	@ActiveYN bYN,
	@Status varchar(10),
	@PRGroup bGroup,
	@PRDept bDept,
	@StdCraft bCraft,
	@StdClass bClass,
	@StdInsCode bInsCode,
	@StdTaxState bStatus,
	@StdUnempState bState,
	@StdInsState bState,
	@StdLocal bLocalCode,
	@W4CompleteYN bYN,
	@PositionCode varchar(10),
	@NoRehireYN bYN,
	@MaritalStatus char(1),
	@MaidenName varchar(20),
	@SpouseName varchar(30),
	@PassPort bYN,
	@RelativesYN bYN,
	@HandicapYN bYN,
	@HandicapDesc bDesc,
	@VetJobCategory varchar(1),
	@PhysicalYN bYN,
	@PhysDate bDate,
	@PhysExpireDate bDate,
	@PhysResults VARCHAR(MAX),
	@LicNumber varchar(20),
	@LicType varchar(20),
	@LicState bState,
	@LicExpDate bDate, 
	@DriveCoVehiclesYN bYN,
	@I9Status varchar(20),
	@I9Citizen varchar(20),
	@I9ReviewDate bDate,
	@TrainingBudget bDollar,
	@CafeteriaPlanBudget bDollar,
	@HighSchool varchar(30),
	@HSGradDate bDate,
	@College1 varchar(30),
	@College1BegDate bDate,
	@College1EndDate bDate,
	@College1Degree varchar(20),
	@College2 varchar(30),
	@College2BegDate bDate,
	@College2EndDate bDate,
	@College2Degree varchar(20),
	@ApplicationDate bDate,
	@AvailableDate bDate,
	@LastContactDate bDate,
	@ContactPhone bPhone,
	@AltContactPhone bPhone,
	@ExpectedSalary bDollar,
	@Source bDesc,
	@SourceCost bDollar,
	@CurrentEmployer varchar(20),
	@CurrentTime varchar(20),
	@PrevEmployer bDesc,
	@PrevTime varchar(20),
	@NoContactEmplYN bYN,
	@HistSeq int,
	@Notes VARCHAR(MAX),
	@ExistsInPR bYN,
	@EarnCode bEDLCode,
	@PhotoName varchar(255),
	@UniqueAttchID uniqueidentifier,
	@TempWorker bYN,
	@Email varchar(50),
	@Suffix varchar(4),
	@DisabledVetYN bYN,	
	@VietnamVetYN bYN,
	@OtherVetYN bYN,
	@VetDischargeDate bDate,
	@OccupCat varchar(10),
	@CatStatus char(1),
	@LicClass char(1),
	@DOLHireState bState,
	@Original_HRCo bCompany, 
	@Original_HRRef bHRRef, 
	@Original_PRCo bCompany, 
	@Original_PREmp bEmployee, 
	@Original_LastName varchar(30),
	@Original_FirstName varchar(30),
	@Original_MiddleName varchar(15),
	@Original_SortName varchar(15),
	@Original_Address varchar(60),
	@Original_City varchar(30),
	@Original_State bState,
	@Original_Zip bZip,
	@Original_Address2 varchar(60),
	@Original_Phone bPhone,
	@Original_WorkPhone bPhone,
	@Original_Pager bPhone,
	@Original_CellPhone bPhone,
	@Original_SSN char(11),
	@Original_Sex char(1),
	@Original_Race char(2),
	@Original_BirthDate smalldatetime,
	@Original_HireDate bDate,
	@Original_TermDate bDate,
	@Original_TermReason varchar(20),
	@Original_ActiveYN bYN,
	@Original_Status varchar(10),
	@Original_PRGroup bGroup,
	@Original_PRDept bDept,
	@Original_StdCraft bCraft,
	@Original_StdClass bClass,
	@Original_StdInsCode bInsCode,
	@Original_StdTaxState bStatus,
	@Original_StdUnempState bState,
	@Original_StdInsState bState,
	@Original_StdLocal bLocalCode,
	@Original_W4CompleteYN bYN,
	@Original_PositionCode varchar(10),
	@Original_NoRehireYN bYN,
	@Original_MaritalStatus char(1),
	@Original_MaidenName varchar(20),
	@Original_SpouseName varchar(30),
	@Original_PassPort bYN,
	@Original_RelativesYN bYN,
	@Original_HandicapYN bYN,
	@Original_HandicapDesc bDesc,
	@Original_VetJobCategory varchar(1),
	@Original_PhysicalYN bYN,
	@Original_PhysDate bDate,
	@Original_PhysExpireDate bDate,
	@Original_PhysResults VARCHAR(MAX),
	@Original_LicNumber varchar(20),
	@Original_LicType varchar(20),
	@Original_LicState bState,
	@Original_LicExpDate bDate, 
	@Original_DriveCoVehiclesYN bYN,
	@Original_I9Status varchar(20),
	@Original_I9Citizen varchar(20),
	@Original_I9ReviewDate bDate,
	@Original_TrainingBudget bDollar,
	@Original_CafeteriaPlanBudget bDollar,
	@Original_HighSchool varchar(30),
	@Original_HSGradDate bDate,
	@Original_College1 varchar(30),
	@Original_College1BegDate bDate,
	@Original_College1EndDate bDate,
	@Original_College1Degree varchar(20),
	@Original_College2 varchar(30),
	@Original_College2BegDate bDate,
	@Original_College2EndDate bDate,
	@Original_College2Degree varchar(20),
	@Original_ApplicationDate bDate,
	@Original_AvailableDate bDate,
	@Original_LastContactDate bDate,
	@Original_ContactPhone bPhone,
	@Original_AltContactPhone bPhone,
	@Original_ExpectedSalary bDollar,
	@Original_Source bDesc,
	@Original_SourceCost bDollar,
	@Original_CurrentEmployer varchar(20),
	@Original_CurrentTime varchar(20),
	@Original_PrevEmployer bDesc,
	@Original_PrevTime varchar(20),
	@Original_NoContactEmplYN bYN,
	@Original_HistSeq int,
	@Original_Notes VARCHAR(MAX),
	@Original_ExistsInPR bYN,
	@Original_EarnCode bEDLCode,
	@Original_PhotoName varchar(255),
	@Original_UniqueAttchID uniqueidentifier,
	@Original_TempWorker bYN,
	@Original_Email varchar(50),
	@Original_Suffix varchar(4),
	@Original_DisabledVetYN bYN,	
	@Original_VietnamVetYN bYN,
	@Original_OtherVetYN bYN,
	@Original_VetDischargeDate bDate,
	@Original_OccupCat varchar(10),
	@Original_CatStatus char(1),
	@Original_LicClass char(1),
	@Original_DOLHireState bState	
 )
 AS
 	SET NOCOUNT ON;
	
 	
UPDATE HRRM 
 
SET HRCo = @HRCo, HRRef = @HRRef, PRCo = @PRCo, PREmp = @PREmp, 
LastName = @LastName, FirstName = @FirstName, MiddleName = @MiddleName, 
SortName = @SortName, Address = @Address, City = @City, State = @State, 
Zip = @Zip, Address2 = @Address2, Phone = @Phone, WorkPhone = @WorkPhone, 
Pager = @Pager, CellPhone = @CellPhone, SSN = @SSN, Sex = @Sex, Race = @Race, 
BirthDate = @BirthDate, HireDate = @HireDate, TermDate = @TermDate, 
TermReason = @TermReason, ActiveYN = @ActiveYN, Status = @Status, 
PRGroup = @PRGroup, PRDept = @PRDept, StdCraft = @StdCraft, StdClass = @StdClass, 
StdInsCode = @StdInsCode, StdTaxState = @StdTaxState, StdUnempState = @StdUnempState, 
StdInsState = @StdInsState, StdLocal = @StdLocal, W4CompleteYN = @W4CompleteYN, 
PositionCode = @PositionCode, NoRehireYN = @NoRehireYN, MaritalStatus = @MaritalStatus, 
MaidenName = @MaidenName, SpouseName = @SpouseName, PassPort = @PassPort, 
RelativesYN = @RelativesYN, HandicapYN = @HandicapYN, HandicapDesc = @HandicapDesc, 
VetJobCategory = @VetJobCategory, PhysicalYN = @PhysicalYN, PhysDate = @PhysDate, 
PhysExpireDate = @PhysExpireDate, PhysResults = @PhysResults, LicNumber = @LicNumber, 
LicType = @LicType, LicState = @LicState, LicExpDate = @LicExpDate, 
DriveCoVehiclesYN = @DriveCoVehiclesYN, I9Status = @I9Status, I9Citizen = @I9Citizen, 
I9ReviewDate = @I9ReviewDate, TrainingBudget = @TrainingBudget, 
CafeteriaPlanBudget = @CafeteriaPlanBudget, HighSchool = @HighSchool, 
HSGradDate = @HSGradDate, College1 = @College1, College1BegDate = @College1BegDate, 
College1EndDate = @College1EndDate, College1Degree = @College1Degree, 
College2 = @College2, College2BegDate = @College2BegDate, College2EndDate = @College2EndDate, 
College2Degree = @College2Degree, ApplicationDate = @ApplicationDate, 
AvailableDate = @AvailableDate, LastContactDate = @LastContactDate, ContactPhone = @ContactPhone, 
AltContactPhone = @AltContactPhone, ExpectedSalary = @ExpectedSalary, Source = @Source, 
SourceCost = @SourceCost, CurrentEmployer = @CurrentEmployer, 
CurrentTime = @CurrentTime, PrevEmployer = @PrevEmployer, PrevTime = @PrevTime, 
NoContactEmplYN = @NoContactEmplYN, HistSeq = @HistSeq, Notes = @Notes, 
ExistsInPR = @ExistsInPR, EarnCode = @EarnCode, PhotoName = @PhotoName, 
UniqueAttchID = @UniqueAttchID, TempWorker = @TempWorker, Email = @Email, 
Suffix = @Suffix, DisabledVetYN = @DisabledVetYN, VietnamVetYN = @VietnamVetYN, 
OtherVetYN = @OtherVetYN, VetDischargeDate = @VetDischargeDate, OccupCat = @OccupCat, 
CatStatus = @CatStatus, LicClass = @LicClass, DOLHireState = @DOLHireState 

WHERE (HRCo = @Original_HRCo) 
AND (HRRef = @Original_HRRef) 
AND (ActiveYN = @Original_ActiveYN) 
AND (Address = @Original_Address OR @Original_Address IS NULL AND Address IS NULL) 
AND (Address2 = @Original_Address2 OR @Original_Address2 IS NULL AND Address2 IS NULL) 
AND (AltContactPhone = @Original_AltContactPhone OR @Original_AltContactPhone IS NULL AND AltContactPhone IS NULL) 
AND (ApplicationDate = @Original_ApplicationDate OR @Original_ApplicationDate IS NULL AND ApplicationDate IS NULL) 
AND (AvailableDate = @Original_AvailableDate OR @Original_AvailableDate IS NULL AND AvailableDate IS NULL) 
AND (BirthDate = @Original_BirthDate OR @Original_BirthDate IS NULL AND BirthDate IS NULL) 
AND (CafeteriaPlanBudget = @Original_CafeteriaPlanBudget OR @Original_CafeteriaPlanBudget IS NULL AND CafeteriaPlanBudget IS NULL) 
AND (CatStatus = @Original_CatStatus OR @Original_CatStatus IS NULL AND CatStatus IS NULL) 
AND (CellPhone = @Original_CellPhone OR @Original_CellPhone IS NULL AND CellPhone IS NULL) 
AND (City = @Original_City OR @Original_City IS NULL AND City IS NULL) 
AND (College1 = @Original_College1 OR @Original_College1 IS NULL AND College1 IS NULL) 
AND (College1BegDate = @Original_College1BegDate OR @Original_College1BegDate IS NULL AND College1BegDate IS NULL) 
AND (College1Degree = @Original_College1Degree OR @Original_College1Degree IS NULL AND College1Degree IS NULL) 
AND (College1EndDate = @Original_College1EndDate OR @Original_College1EndDate IS NULL AND College1EndDate IS NULL) 
AND (College2 = @Original_College2 OR @Original_College2 IS NULL AND College2 IS NULL) 
AND (College2BegDate = @Original_College2BegDate OR @Original_College2BegDate IS NULL AND College2BegDate IS NULL) 
AND (College2Degree = @Original_College2Degree OR @Original_College2Degree IS NULL AND College2Degree IS NULL) 
AND (College2EndDate = @Original_College2EndDate OR @Original_College2EndDate IS NULL AND College2EndDate IS NULL) 
AND (ContactPhone = @Original_ContactPhone OR @Original_ContactPhone IS NULL AND ContactPhone IS NULL) 
AND (CurrentEmployer = @Original_CurrentEmployer OR @Original_CurrentEmployer IS NULL AND CurrentEmployer IS NULL) 
AND (CurrentTime = @Original_CurrentTime OR @Original_CurrentTime IS NULL AND CurrentTime IS NULL) 
AND (DOLHireState = @Original_DOLHireState OR @Original_DOLHireState IS NULL AND DOLHireState IS NULL) 
AND (DisabledVetYN = @Original_DisabledVetYN OR @Original_DisabledVetYN IS NULL AND DisabledVetYN IS NULL) 
AND (DriveCoVehiclesYN = @Original_DriveCoVehiclesYN) 
AND (EarnCode = @Original_EarnCode OR @Original_EarnCode IS NULL AND EarnCode IS NULL) 
AND (Email = @Original_Email OR @Original_Email IS NULL AND Email IS NULL) 
AND (ExistsInPR = @Original_ExistsInPR) 
AND (ExpectedSalary = @Original_ExpectedSalary OR @Original_ExpectedSalary IS NULL AND ExpectedSalary IS NULL) 
AND (FirstName = @Original_FirstName OR @Original_FirstName IS NULL AND FirstName IS NULL) 
AND (HSGradDate = @Original_HSGradDate OR @Original_HSGradDate IS NULL AND HSGradDate IS NULL) 
AND (HandicapDesc = @Original_HandicapDesc OR @Original_HandicapDesc IS NULL AND HandicapDesc IS NULL) 
AND (HandicapYN = @Original_HandicapYN) 
AND (HighSchool = @Original_HighSchool OR @Original_HighSchool IS NULL AND HighSchool IS NULL) 
AND (HireDate = @Original_HireDate OR @Original_HireDate IS NULL AND HireDate IS NULL) 
AND (HistSeq = @Original_HistSeq OR @Original_HistSeq IS NULL AND HistSeq IS NULL) 
AND (I9Citizen = @Original_I9Citizen OR @Original_I9Citizen IS NULL AND I9Citizen IS NULL) 
AND (I9ReviewDate = @Original_I9ReviewDate OR @Original_I9ReviewDate IS NULL AND I9ReviewDate IS NULL) 
AND (I9Status = @Original_I9Status OR @Original_I9Status IS NULL AND I9Status IS NULL) 
AND (LastContactDate = @Original_LastContactDate OR @Original_LastContactDate IS NULL AND LastContactDate IS NULL) 
AND (LastName = @Original_LastName) AND (LicClass = @Original_LicClass OR @Original_LicClass IS NULL AND LicClass IS NULL) 
AND (LicExpDate = @Original_LicExpDate OR @Original_LicExpDate IS NULL AND LicExpDate IS NULL) 
AND (LicNumber = @Original_LicNumber OR @Original_LicNumber IS NULL AND LicNumber IS NULL) 
AND (LicState = @Original_LicState OR @Original_LicState IS NULL AND LicState IS NULL) 
AND (LicType = @Original_LicType OR @Original_LicType IS NULL AND LicType IS NULL) 
AND (MaidenName = @Original_MaidenName OR @Original_MaidenName IS NULL AND MaidenName IS NULL) 
AND (MaritalStatus = @Original_MaritalStatus OR @Original_MaritalStatus IS NULL AND MaritalStatus IS NULL) 
AND (MiddleName = @Original_MiddleName OR @Original_MiddleName IS NULL AND MiddleName IS NULL) 
AND (NoContactEmplYN = @Original_NoContactEmplYN) AND (NoRehireYN = @Original_NoRehireYN) 
AND (OccupCat = @Original_OccupCat OR @Original_OccupCat IS NULL AND OccupCat IS NULL) 
AND (OtherVetYN = @Original_OtherVetYN OR @Original_OtherVetYN IS NULL AND OtherVetYN IS NULL) 
AND (PRCo = @Original_PRCo OR @Original_PRCo IS NULL AND PRCo IS NULL) 
AND (PRDept = @Original_PRDept OR @Original_PRDept IS NULL AND PRDept IS NULL) 
AND (PREmp = @Original_PREmp OR @Original_PREmp IS NULL AND PREmp IS NULL) 
AND (PRGroup = @Original_PRGroup OR @Original_PRGroup IS NULL AND PRGroup IS NULL) 
AND (Pager = @Original_Pager OR @Original_Pager IS NULL AND Pager IS NULL) 
AND (PassPort = @Original_PassPort) AND (Phone = @Original_Phone OR @Original_Phone IS NULL AND Phone IS NULL) 
AND (PhotoName = @Original_PhotoName OR @Original_PhotoName IS NULL AND PhotoName IS NULL) 
AND (PhysDate = @Original_PhysDate OR @Original_PhysDate IS NULL AND PhysDate IS NULL) 
AND (PhysExpireDate = @Original_PhysExpireDate OR @Original_PhysExpireDate IS NULL AND PhysExpireDate IS NULL) 
AND (PhysicalYN = @Original_PhysicalYN) 
AND (PositionCode = @Original_PositionCode OR @Original_PositionCode IS NULL AND PositionCode IS NULL) 
AND (PrevEmployer = @Original_PrevEmployer OR @Original_PrevEmployer IS NULL AND PrevEmployer IS NULL) 
AND (PrevTime = @Original_PrevTime OR @Original_PrevTime IS NULL AND PrevTime IS NULL) 
AND (Race = @Original_Race OR @Original_Race IS NULL AND Race IS NULL) 
AND (RelativesYN = @Original_RelativesYN) 
AND (SSN = @Original_SSN OR @Original_SSN IS NULL AND SSN IS NULL) 
AND (Sex = @Original_Sex) 
AND (SortName = @Original_SortName) 
AND (Source = @Original_Source OR @Original_Source IS NULL AND Source IS NULL) 
AND (SourceCost = @Original_SourceCost OR @Original_SourceCost IS NULL AND SourceCost IS NULL) 
AND (SpouseName = @Original_SpouseName OR @Original_SpouseName IS NULL AND SpouseName IS NULL) 
AND (State = @Original_State OR @Original_State IS NULL AND State IS NULL) 
AND (Status = @Original_Status OR @Original_Status IS NULL AND Status IS NULL) 
AND (StdClass = @Original_StdClass OR @Original_StdClass IS NULL AND StdClass IS NULL) 
AND (StdCraft = @Original_StdCraft OR @Original_StdCraft IS NULL AND StdCraft IS NULL) 
AND (StdInsCode = @Original_StdInsCode OR @Original_StdInsCode IS NULL AND StdInsCode IS NULL) 
AND (StdInsState = @Original_StdInsState OR @Original_StdInsState IS NULL AND StdInsState IS NULL) 
AND (StdLocal = @Original_StdLocal OR @Original_StdLocal IS NULL AND StdLocal IS NULL) 
AND (StdTaxState = @Original_StdTaxState OR @Original_StdTaxState IS NULL AND StdTaxState IS NULL) 
AND (StdUnempState = @Original_StdUnempState OR @Original_StdUnempState IS NULL AND StdUnempState IS NULL) 
AND (Suffix = @Original_Suffix OR @Original_Suffix IS NULL AND Suffix IS NULL) 
AND (TempWorker = @Original_TempWorker) 
AND (TermDate = @Original_TermDate OR @Original_TermDate IS NULL AND TermDate IS NULL) 
AND (TermReason = @Original_TermReason OR @Original_TermReason IS NULL AND TermReason IS NULL) 
AND (TrainingBudget = @Original_TrainingBudget OR @Original_TrainingBudget IS NULL AND TrainingBudget IS NULL) 
AND (UniqueAttchID = @Original_UniqueAttchID OR @Original_UniqueAttchID IS NULL AND UniqueAttchID IS NULL) 
AND (VetDischargeDate = @Original_VetDischargeDate OR @Original_VetDischargeDate IS NULL AND VetDischargeDate IS NULL) 
AND (VetJobCategory = @Original_VetJobCategory OR @Original_VetJobCategory IS NULL AND VetJobCategory IS NULL) 
AND (VietnamVetYN = @Original_VietnamVetYN OR @Original_VietnamVetYN IS NULL AND VietnamVetYN IS NULL) 
AND (W4CompleteYN = @Original_W4CompleteYN) 
AND (WorkPhone = @Original_WorkPhone OR @Original_WorkPhone IS NULL AND WorkPhone IS NULL) 
AND (Zip = @Original_Zip OR @Original_Zip IS NULL AND Zip IS NULL);

-- below:
-- synch up PREH to HRRM

-- 142422 - removing depreciated call to bspHRPRUpdate because this is done in triggers now
--declare @rcode int, @msg varchar(255)
--set @rcode = 0

--set @msg = NULL

--exec @rcode = dbo.bspHRPRUpdate @HRCo, @PRCo, @HRRef, @PREmp, @msg output
 	



GO
GRANT EXECUTE ON  [dbo].[vpspHRResourceItemUpdate] TO [VCSPortal]
GO
