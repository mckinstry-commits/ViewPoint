SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspJCContractMasterGet]
/************************************************************
* CREATED:		2/6/07  CHS
* MODIFIED:		6/7/07	CHS
*				GF 03/21/2008 - issue #12076 international addresses
*
* USAGE:
*   Returns the Job Cost Job Master
*	
* CALLED FROM:
*	ViewpointCS Portal  
*
* INPUT PARAMETERS
*    JCCo, Job, VendorGroup
*   
************************************************************/
(@JCCo bCompany, @Job bJob)

AS

SET NOCOUNT ON;

SELECT
	c.KeyID, c.JCCo, c.Contract, c.Description, c.Department, 

	d.Description as 'DepartmentDescription',

	c.ContractStatus, 
	
	case c.ContractStatus
		when '1' then '1 - Open'
		when '2' then '2 - Soft Close'
		when '3' then '3 - Hard Close'
		else ''
		end as 'ContractStatusDescription',
		
	c.OriginalDays, c.CurrentDays, c.StartMonth, c.MonthClosed, c.ProjCloseDate, 
	c.ActualCloseDate, c.CustGroup, c.Customer, 
	
	a.Name as 'CustomerName',

	c.PayTerms, 

	p.Description as 'PayTermsDescription',

	c.TaxInterface, 
	
	case c.TaxInterface
		when 'Y' then 'Yes'
		when 'N' then 'No'
		else ''
		end as 'TaxInterfaceYesNo',
	
	c.TaxGroup, c.TaxCode, 
	
	t.Description as 'TaxCodeDescription',
	
	c.RetainagePCT, 
	
	c.RetainagePCT * 100 as 'RetainagePCT100',
	
	c.DefaultBillType, 
	
	case c.DefaultBillType
		when 'P' then 'Progress'
		when 'T' then 'T & M'
		when 'B' then 'Both'
		when 'N' then 'None'
		else '' 
		end as 'DefaultBillTypeDescription',
			
	c.OrigContractAmt, 
	c.ContractAmt, c.BilledAmt, c.ReceivedAmt, c.CurrentRetainAmt, c.InBatchMth, 
	c.InUseBatchId, c.Notes, c.SIRegion, c.SIMetric, 
	
	case c.SIMetric
		when 'Y' then 'Yes'
		when 'N' then 'No'
		else ''
		end as 'SIMetricDescription',
	
	c.ProcessGroup, c.BillAddress, 
	c.BillAddress2, c.BillCity, c.BillState, c.BillZip, c.BillNotes, c.BillOnCompletionYN, 
	c.CustomerReference, c.CompleteYN, c.RoundOpt, c.ReportRetgItemYN, c.ProgressFormat, 
	c.TMFormat, c.BillGroup, c.BillDayOfMth, c.ArchitectName, c.ArchitectProject, 
	c.ContractForDesc, c.StartDate, c.JBTemplate, c.JBFlatBillingAmt, c.JBLimitOpt, 
	c.UniqueAttchID, c.RecType, c.OverProjNotes, c.ClosePurgeFlag, c.MiscDistCode, c.SecurityGroup,
	
	s.Description as 'SecurityGroupDescription',
	c.BillCountry


FROM JCCM c with (nolock)
	Left Join JCJM m with (nolock) on c.JCCo=m.JCCo and m.Contract=c.Contract
	Left Join JCDM d with (nolock) on c.JCCo=d.JCCo and c.Department=d.Department
	Left Join ARCM a with (nolock) on c.CustGroup=a.CustGroup and c.Customer=a.Customer
	Left Join HQPT p with (nolock) on c.PayTerms=p.PayTerms
	Left Join DDSG s with (nolock) on c.SecurityGroup=s.SecurityGroup
	Left Join HQTX t with (nolock) on c.TaxCode=t.TaxCode and c.TaxGroup=t.TaxGroup

Where m.JCCo=@JCCo and m.Job=@Job




GO
GRANT EXECUTE ON  [dbo].[vpspJCContractMasterGet] TO [VCSPortal]
GO
