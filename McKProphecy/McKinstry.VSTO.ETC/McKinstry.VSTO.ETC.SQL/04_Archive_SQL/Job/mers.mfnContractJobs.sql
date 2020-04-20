use Viewpoint
go

if exists ( select 1 from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mfnContractJobs' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='FUNCTION' )
begin
	print 'DROP FUNCTION mers.mfnContractJobs'
	DROP FUNCTION mers.mfnContractJobs
end
go

print 'CREATE FUNCTION mers.mfnContractJobs'
go

create function mers.mfnContractJobs
(
	@JCCo		bCompany
,	@Contract	bContract
,	@Job		bJob
)
-- ========================================================================
-- mers.mfnContractJobs
-- Author:	Ziebell, Jonathan
-- Create date: 06/21/2016
-- Description:	
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
returns table as return

select
	jcjm.JCCo	
,	jcjm.Contract	
,	jcjm.Job	
,	jcjm.Description as JobDescription	
,	contract_header.JCDepartmentId
,	contract_header.JCDepartment
,	contract_header.GLDepartmentId
,	contract_header.GLDepartment
,	jcjm.JobStatus	
,	ddci.DisplayValue as JobStatusDesc
,	jcjm.BidNumber	
,	jcjm.LockPhases	
,	jcjm.ProjectMgr	
,	jcmp.Name as ProjectMgrName
,	jcmp.udPRCo as ProjectMgrPRCo
,	jcmp.udEmployee as ProjectMgrEmployee
,	preh.FullName as ProjectMgrFullName
,	preh.ActiveYN as ProjectMgrEmployeeActiveYN
,	ddup.VPUserName as ProjectMgrUserName
,	jcjm.JobPhone	
,	jcjm.JobFax	
,	jcjm.MailAddress	
,	jcjm.MailAddress2	
,	jcjm.MailCity	
,	jcjm.MailState	
,	jcjm.MailZip	
,	jcjm.MailCountry	
--,	jcjm.ShipAddress	
--,	jcjm.ShipAddress2	
--,	jcjm.ShipCity	
--,	jcjm.ShipState	
--,	jcjm.ShipZip	
--,	jcjm.ShipCountry	
--,	jcjm.LiabTemplate	
--,	jcjm.TaxGroup	
--,	jcjm.TaxCode	
--,	jcjm.InsTemplate	
--,	jcjm.MarkUpDiscRate	
--,	jcjm.PRLocalCode	
--,	jcjm.PRStateCode	
--,	jcjm.Certified	
--,	jcjm.EEORegion	
--,	jcjm.SMSACode	
--,	jcjm.CraftTemplate	
--,	jcjm.ProjMinPct	
--,	jcjm.Notes	
--,	jcjm.SLCompGroup	
--,	jcjm.POCompGroup	
--,	jcjm.VendorGroup	
--,	jcjm.ArchEngFirm	
--,	jcjm.OTSched	
--,	jcjm.PriceTemplate	
--,	jcjm.HaulTaxOpt	
--,	jcjm.GeoCode	
--,	jcjm.BaseTaxOn	
--,	jcjm.UpdatePlugs	
--,	jcjm.ContactCode	
--,	jcjm.ClosePurgeFlag	
--,	jcjm.OurFirm	
--,	jcjm.AutoAddItemYN	
--,	jcjm.OverProjNotes	
--,	jcjm.WghtAvgOT	
--,	jcjm.HrsPerManDay	
--,	jcjm.AutoGenSubNo	
--,	jcjm.SecurityGroup	
--,	jcjm.DefaultStdDaysDue	
--,	jcjm.DefaultRFIDaysDue	
--,	jcjm.UpdateAPActualsYN	
--,	jcjm.UpdateMSActualsYN	
--,	jcjm.AutoGenPCONo	
--,	jcjm.AutoGenMTGNo	
--,	jcjm.AutoGenRFINo	
--,	jcjm.RateTemplate	
--,	jcjm.RevGrpInv	
--,	jcjm.CertDate	
--,	jcjm.AutoGenRFQNo	
--,	jcjm.ApplyEscalators	
--,	jcjm.UseTaxYN	
--,	jcjm.TimesheetRevGroup	
--,	jcjm.PotentialProjectID	
--,	jcjm.PCVisibleInJC	
--,	jcjm.SubmittalReviewDaysResponsibleFirm	
--,	jcjm.SubmittalReviewDaysApprovingFirm	
--,	jcjm.SubmittalReviewDaysRequestingFirm	
--,	jcjm.SubmittalReviewDaysAutoCalcYN	
--,	jcjm.SubmittalApprovingFirm	
--,	jcjm.SubmittalApprovingFirmContact	
--,	jcjm.udDatePhaseDelete	
--,	jcjm.udCGCJob	
--,	jcjm.udBET	
--,	jcjm.udBuildNum	
--,	jcjm.udSquFootage	
--,	jcjm.udOccOwn	
--,	jcjm.udDTReqd	
--,	jcjm.udDTRespParty	
--,	jcjm.udEnergySRating	
--,	jcjm.udLeedTarget	
--,	jcjm.udGovntYN	
--,	jcjm.udAARAYN	
--,	jcjm.udJobsNowYN	
--,	jcjm.udEnable84YN	
--,	jcjm.udBuyAmericanYN	
--,	jcjm.udGovSector	
--,	jcjm.udGovtOwner	
--,	jcjm.udAwardAgency	
--,	jcjm.udPubFundTrail	
--,	jcjm.udSINNum	
--,	jcjm.udProcVeh	
--,	jcjm.udIFFFeeYN	
,	jcjm.udCRMNum	
,	jcjm.udProjWrkstrm	
--,	jcjm.udBLocAddress	
--,	jcjm.udBLocAddress2	
--,	jcjm.udBLocCity	
--,	jcjm.udBLocState	
--,	jcjm.udBLocZip	
--,	jcjm.udAcctMngr	
--,	jcjm.udRFPDueDate	
--,	jcjm.udDesignStrt	
--,	jcjm.udDesignEnd	
--,	jcjm.udConstStrt	
--,	jcjm.udConstEnd	
--,	jcjm.FourProjectsContainerName	
--,	jcjm.FourProjectsContainerId	
--,	jcjm.udWABOTax	
--,	jcjm.udGovtOwnYN	
--,	jcjm.udRiskProfile	
--,	jcjm.udOCCIPCCIPYN	
--,	jcjm.udExistingBuildYN	
--,	jcjm.udPrevailWage	
--,	jcjm.udWorkRecYN	
--,	jcjm.udAuthType	
--,	jcjm.udFAR	
--,	jcjm.udFARYN	
--,	jcjm.udVARYN	
--,	jcjm.udDEARYN	
--,	jcjm.udBOClass	
--,	jcjm.udStateSpecificTax	
--,	jcjm.udProjIns	
--,	jcjm.udProjSummary	
--,	jcjm.udHardcardYN	
--,	jcjm.udPublicFundsYN	
,	jcjm.udDateChanged	
,	jcjm.udProjStart	
,	jcjm.udProjEnd
from
	mers.mfnContractHeader(@JCCo,@Contract) contract_header left outer join
	JCJM jcjm on
		contract_header.JCCo=jcjm.JCCo
	and contract_header.Contract=jcjm.Contract left outer join
	JCMP jcmp on
		jcjm.JCCo=jcmp.JCCo
	and jcjm.ProjectMgr=jcmp.ProjectMgr left join
	PREHFullName preh on
		jcmp.udPRCo=preh.PRCo
	and jcmp.udEmployee=preh.Employee left join 
	DDUP ddup on
		jcmp.udPRCo=ddup.PRCo
	and jcmp.udEmployee=ddup.Employee left outer join
	DDCIShared ddci on
		ddci.ComboType='JCJMJobStatus'
	and	cast(jcjm.JobStatus as varchar(10))=ddci.DatabaseValue
where
	jcjm.JCCo < 100
and	(jcjm.JCCo=@JCCo or @JCCo is null)
and (jcjm.Job=@Job or @Job is null)
go

--select * from DDCIShared where ComboType like '%JCJMJobStatus%'
/*declare @JCCo bCompany
declare @Contract bContract
declare @Job bJob

select @JCCo=1, @Contract=' 14345-', @Job = null

select * from mers.mfnContractJobs(@JCCo,@Contract, @Job)


select @JCCo=1, @Contract=' 10353-'
select * from mers.mfnContractJobs(@JCCo,@Contract, @Job) order by 1,8,9,10
*/
