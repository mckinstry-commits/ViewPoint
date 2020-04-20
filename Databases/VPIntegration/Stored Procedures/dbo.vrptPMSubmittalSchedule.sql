SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* 
StoredProcedure [dbo].[vrptPMSubmittalSchedule]

Author:		Sean O'Halloran 
Created:	12/17/2012
Reports:	PM/PMSubmittalSchedule.rpt

Purpose:	returns contents of PMSubmittal table in a form that mimics the Submittal Register
			or returns data from the PMSubmittal table in a more 'standard' form to be
			processed by the report. Action is controlled by value present in latestRev param
			
Revision History      
Date	Author	Issue	Description


*/

CREATE procedure [dbo].[vrptPMSubmittalSchedule](
	@Company bCompany, 
	@Project bProject, 
	@BegDate bDate,
	@EndDate bDate,
	@latestRev char(1)	
)
AS

-- latestRev values: Y - returns all data, N returns the latest revisions only
-- vrvPMSubmittalRegister
IF @latestRev = 'Y'
	BEGIN
		SELECT PMS.*
		FROM [dbo].[vrvPMSubmittalRegister] PMS
		WHERE
			PMS.Company=@Company and PMS.Project=@Project
			and not exists 
			(SELECT 1 
			FROM [dbo].[vrvPMSubmittalRegister] m
			WHERE PMS.Company = m.Company
				and PMS.Project = m.Project 
				and PMS.SubmittalNumber = m.SubmittalNumber 
				and isnull(m.SubmittalRev,0) > isnull(PMS.SubmittalRev,0)
			)
			and PMS.ActivityDate between @BegDate and @EndDate
		ORDER BY SubmittalNumber, Package
	END
ELSE
	BEGIN
		SELECT p.*
		FROM [dbo].[vrvPMSubmittalRegister] p
		WHERE p.Company = @Company
			and p.Project = @Project
			and p.ActivityDate between @BegDate and @EndDate
END
GO
GRANT EXECUTE ON  [dbo].[vrptPMSubmittalSchedule] TO [public]
GO
