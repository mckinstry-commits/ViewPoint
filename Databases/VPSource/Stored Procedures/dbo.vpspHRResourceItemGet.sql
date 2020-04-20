SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspHRResourceItemGet]
 /************************************************************
 * CREATED:     SDE 6/12/2006
* MODIFIED:		6/7/07	CHS
 *
 * USAGE:
 *   Returns the HR Resource based on the HRCo and HRRef
 *	 Joins pvHRMaritalCodes for the MaritalCode Description
 *
 * CALLED FROM:
 *	ViewpointCS Portal  
 *
 * INPUT PARAMETERS
 *    HRCo, HRRef        
 *
 * OUTPUT PARAMETERS
 *   
 * RETURN VALUE
 *   
 ************************************************************/
 (@HRCo bCompany, @HRRef bHRRef,
	@KeyID int = Null)
 AS
 	SET NOCOUNT ON;

select 
	h.KeyID, h.HRCo, h.HRRef, 
	h.PRCo, h.PREmp, h.LastName, h.FirstName, 
	h.MiddleName, h.SortName, h.Address, h.City, h.State, h.Zip, 
	h.Address2, h.Phone, h.WorkPhone, 
	h.Pager, h.CellPhone, h.SSN, h.Sex, h.Race, h.BirthDate, h.HireDate, 
	h.TermDate, h.TermReason, h.ActiveYN, h.Status, h.PRGroup, 
	h.PRDept, h.StdCraft, h.StdClass, 
	h.StdInsCode, h.StdTaxState, h.StdUnempState, h.StdInsState, 
	h.StdLocal, h.W4CompleteYN, h.PositionCode, h.NoRehireYN, h.MaritalStatus,
	c.MaritalStatusDesc as 'MaritalStatusDesc', 

	h.MaidenName, h.SpouseName, h.PassPort, h.RelativesYN, h.HandicapYN, h.HandicapDesc, 
	h.VetJobCategory, h.PhysicalYN, h.PhysDate, h.PhysExpireDate, 
	h.PhysResults, h.LicNumber, h.LicType, h.LicState, h.LicExpDate, h.DriveCoVehiclesYN, 
	h.I9Status, h.I9Citizen, h.I9ReviewDate, h.TrainingBudget, 
	h.CafeteriaPlanBudget, h.HighSchool, h.HSGradDate, h.College1, h.College1BegDate, 
	h.College1EndDate, h.College1Degree, h.College2, h.College2BegDate, 
	h.College2EndDate,  h.College2Degree, h.ApplicationDate, h.AvailableDate, 
	h.LastContactDate, h.ContactPhone, h.AltContactPhone, h.ExpectedSalary, 
	h.Source, h.SourceCost, h.CurrentEmployer, h.CurrentTime, 
	h.PrevEmployer, h.PrevTime, h.NoContactEmplYN, h.HistSeq, 
	h.Notes, 

	h.ExistsInPR, h.EarnCode, h.PhotoName, h.UniqueAttchID, 
	h.TempWorker, h.Email, h.Suffix, 
	h.DisabledVetYN, h.VietnamVetYN, h.OtherVetYN, h.VetDischargeDate, h.OccupCat, h.CatStatus, h.LicClass, h.DOLHireState 
 
from HRRM h with (nolock)
	left join pvHRMaritalCodes c on h.MaritalStatus = c.KeyField

where h.HRCo = @HRCo and h.HRRef = @HRRef
and h.KeyID = IsNull(@KeyID, h.KeyID)




GO
GRANT EXECUTE ON  [dbo].[vpspHRResourceItemGet] TO [VCSPortal]
GO
