SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL,vspVAProcessCubes
-- Create date: 7/30/08
-- Description:	Runs the OLAP_ProcessCube job.
-- =============================================
CREATE PROCEDURE [dbo].[vspVAProcessCubes] 

--with execute as 'viewpointcs'	
(@jobname as varchar(30))
	
AS
BEGIN
	
	
		select  top 1 instance_id, run_status --YAY    
		from  msdb.dbo.sysjobs j
		join  msdb.dbo.sysjobsteps js on js.job_id = j.job_id
		join  msdb.dbo.sysjobhistory jh on jh.job_id = js.job_id
        and jh.step_id = js.step_id
		where j.[name] = @jobname
		order by instance_id desc
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVAProcessCubes] TO [public]
GO
