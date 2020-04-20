SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDeleteWithoutPC    Script Date: 11/29/2010 16:36:28 ******/
   
   CREATE  proc [dbo].[vspPMDeleteWithoutPC]
    	(@JCCo bCompany, @Project bJob, @msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		JG 11/29/2010
     * MODIFIED By :	JG 01/06/2011 - TFS# 1662 - Updated delete without PC for refactored JCJM.
     *
     * USAGE:
     *	"Removes" the PM Project by deleting all related records,
     *  and resetting the PM back to before it was created.
     *
     * INPUT PARAMETERS
     *  JCCo		Company of the Project
	 *	Project		Project tied to a Potential Project to remove.
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int, @PotentialProjectID bigint
   
    set @rcode = 0

	----------------
	-- Validation --
	----------------
    if @JCCo is null
    begin
    	select @msg = 'Missing Company!', @rcode = 1
       	goto vspexit
    end
	if @Project is null
    begin
    	select @msg = 'Missing Project!', @rcode = 1
       	goto vspexit
    end

	-- Check to make sure Project is related to a Potential Project.
	if not exists(select top 1 1 from bJCJM with(nolock) where JCCo = @JCCo AND Job = @Project AND PotentialProjectID IS NOT NULL)
	begin
		select @msg = 'Related Potential Project doesn''t exist.', @rcode = 1
		goto vspexit
	end
	
	CREATE TABLE #deleted (
	JCCo INT, Job VARCHAR(10), JobStatus TINYINT)

	INSERT INTO #deleted
	SELECT TOP 1 JCCo, Job, JobStatus FROM bJCJM WHERE JCCo = @JCCo AND Job = @Project
	
	-- Handle delete for PM --

	---- Check bJCAJ for detail
	if exists(select top 1 1 from #deleted d JOIN dbo.bJCAJ o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
		begin
		select @msg = 'Entries exist in bJCAJ', @rcode = 1
		goto vspexit
		END
		
	---- Check bJCJP for detail
	if exists(select top 1 1 from #deleted d JOIN dbo.bJCJP o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
		begin
		select @msg = 'Entries exist in bJCJP', @rcode = 1
		goto vspexit
		end	

	---- Check bJCOH for detail
	if exists(select top 1 1 from #deleted d JOIN dbo.bJCOH o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
		begin
		select @msg = 'Entries exist in bJCOH', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMOP o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMOP', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMOH o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMOH', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMMM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMMM', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMPU o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMPU', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMRI o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMRI', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMSM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMSM', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMTM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMTM', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMDG o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMDG', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMIL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMIL', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMTL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMTL', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMIM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMIM', @rcode = 1
		goto vspexit
		end

	---- need to check PM tables for detail, but these checks only apply if the job status is not pending
	if exists(select top 1 1 from #deleted d join dbo.bPMPL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
		begin
		select @msg = 'Entries exist in bPMPL', @rcode = 1
		goto vspexit
		end
	   

	   
	-- CHS 11/07/08 - #130950
	if exists(select * from EMLB b join #deleted d on (b.ToJCCo = d.JCCo and b.ToJob = d.Job) or (b.FromJCCo = d.JCCo and b.FromJob = d.Job))
		 begin
		 select @msg = 'Entries exist in bEMLB', @rcode = 1
		 goto vspexit
		 end

	-- CHS 11/07/08 - #130950
	if exists(select * from EMLH h join #deleted d on h.ToJCCo = d.JCCo and h.ToJob = d.Job and h.DateOut is Null)
		 begin
		 select @msg = 'Entries exist in bEMLH', @rcode = 1
		 goto vspexit
		 end

	-- CHS 11/07/08 - #130950
	if exists(select * from EMEM e join #deleted d on e.EMCo = d.JCCo and e.Job = d.Job)
		 begin
		 select @msg = 'Entries exist in bEMEM', @rcode = 1
		 goto vspexit
		 end
		 
	begin try
		begin transaction
		
		---- delete PMPA - Project Addons
		delete bPMPA from bPMPA join #deleted d on bPMPA.PMCo=d.JCCo and bPMPA.Project=d.Job
		---- delete PMPC - Project Cost Type Markups
		delete bPMPC from bPMPC join #deleted d on bPMPC.PMCo=d.JCCo and bPMPC.Project=d.Job
		---- delete PMPF - Project Firms
		delete bPMPF from bPMPF join #deleted d on bPMPF.PMCo=d.JCCo and bPMPF.Project=d.Job

		---------------------------------------------
		-- DELETE ALL RELATED RECORDS IN PM --
		---------------------------------------------
		DELETE bJCJP FROM bJCJP e JOIN #deleted d ON e.JCCo = d.JCCo AND e.Job = d.Job
		
		delete bPMBC from bPMBC e join #deleted d on e.Co = d.JCCo and e.Project = d.Job
		delete bPMBE from bPMBE e join #deleted d on e.Co = d.JCCo and e.Project = d.Job
		delete bPMCD from bPMCD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDC from bPMDC e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMMD from bPMMD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMMF from bPMMF e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMML from bPMML e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOA from bPMOA e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOC from bPMOC e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOM from bPMOM e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job

		delete bPMPD from bPMPD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMQD from bPMQD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMRD from bPMRD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMSL from bPMSL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMSI from bPMSI e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMSM from bPMSM e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMSS from bPMSS e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMTC from bPMTC e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMTS from bPMTS e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDR from bPMDR e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDG from bPMDG e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMIL from bPMIL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMTL from bPMTL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMED from bPMED e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMEH from bPMEH e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDZ from bPMDZ e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job

		delete bPMNR from bPMNR e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMPN from bPMPN e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDD from bPMDD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMDL from bPMDL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMMI from bPMMI e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMMM from bPMMM e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOD from bPMOD e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOL from bPMOL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOI from bPMOI e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOP from bPMOP e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMOH from bPMOH e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMPI from bPMPI e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMPL from bPMPL e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMPU from bPMPU e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMRI from bPMRI e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMRQ from bPMRQ e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMTM from bPMTM e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job

		delete bPMDH from bPMDH e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMIH from bPMIH e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job
		delete bPMIM from bPMIM e join #deleted d on e.PMCo = d.JCCo and e.Project = d.Job

		delete vJCJobRoles from vJCJobRoles e join #deleted d on e.JCCo=d.JCCo and e.Job=d.Job
	
		-- Reset the PM
		UPDATE bJCJM 
		SET PCVisibleInJC = 'N'
		, Job = dbo.vfJCJMGetNextTempProjID(@JCCo)
		,[Contract] = NULL ,
		LockPhases = 'N' ,
		JobPhone = NULL ,
		JobFax = NULL ,
		MailAddress = NULL ,
		MailCity = NULL ,
		MailState = NULL ,
		MailZip = NULL ,
		MailAddress2 = NULL ,
		LiabTemplate = NULL ,
		TaxGroup = 0 ,
		TaxCode = NULL ,
		InsTemplate = NULL ,
		MarkUpDiscRate = 0 ,
		PRLocalCode = NULL ,
		PRStateCode = NULL ,
		Certified = 'N' ,
		EEORegion = NULL ,
		SMSACode = NULL ,
		CraftTemplate = NULL ,
		ProjMinPct = 0 ,
		SLCompGroup = NULL ,
		POCompGroup = NULL ,
		ArchEngFirm = NULL ,
		OTSched = NULL ,
		PriceTemplate = NULL ,
		HaulTaxOpt = 0 ,
		GeoCode = NULL ,
		BaseTaxOn = 'J' ,
		UpdatePlugs = 'N' ,
		ContactCode = NULL ,
		ClosePurgeFlag = 'N' ,
		OurFirm = NULL ,
		AutoAddItemYN = 'N' ,
		OverProjNotes = NULL ,
		WghtAvgOT = 'N' ,
		HrsPerManDay = 8 ,
		AutoGenSubNo = 'T' ,
		SecurityGroup = NULL ,
		DefaultStdDaysDue = NULL ,
		DefaultRFIDaysDue = NULL ,
		UpdateAPActualsYN = 'Y' ,
		UpdateMSActualsYN = 'Y' ,
		AutoGenPCONo = 'P' ,
		AutoGenMTGNo = 'P' ,
		AutoGenRFINo = 'P' ,
		RateTemplate = NULL ,
		RevGrpInv = NULL ,
		MailCountry = NULL ,
		CertDate = NULL ,
		AutoGenRFQNo = 'P' ,
		ApplyEscalators = 'P' ,
		UseTaxYN = 'N' ,
		TimesheetRevGroup = NULL
		WHERE JCCo = @JCCo AND Job = @Project
	
		commit transaction
	end try

	begin catch
		select @msg = error_message(), @rcode = 1
		rollback transaction
		goto vspexit
	end catch

    vspexit:
		DROP TABLE #deleted
		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMDeleteWithoutPC] TO [public]
GO
