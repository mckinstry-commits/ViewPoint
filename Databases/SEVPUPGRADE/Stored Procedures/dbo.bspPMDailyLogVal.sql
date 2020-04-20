SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDailyLogVal    Script Date: 8/28/99 9:33:03 AM ******/
   CREATE  proc [dbo].[bspPMDailyLogVal]
   /***********************************************************
    * CREATED BY: SAE 12/25/98
    * MODIFIED By : CJW 12/25/98
    *				 mh 2/1/01 - @dailylog is smallint in tables.  
    *					changed variable declaration from tinyint to smallint
    *
    * USAGE:
    * validates Daily logs
    * and returns the description
    * an error is returned if any of the following occurs
    * no job passed, no project found in JCJM
    *
    * INPUT PARAMETERS
    *   PMCo   		PM Co to validate against 
    *   Project    	Project to validate
    *   LogDate		Date of the Daily Log
    *   DailyLog           Number of the log on that date
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of Project
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   (@pmco bCompany = 0, @project bJob = null, @logdate bDate, @dailylog smallint, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @pmco is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   
   	end
   
   if @project is null
   	begin
   	select @msg = 'Missing project!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @msg = Description from PMDL with (nolock) 
   where PMCo = @pmco and Project = @project and LogDate=@logdate and DailyLog=@dailylog
   if @@rowcount = 0
   	begin
   	select @msg = 'Log not on file!', @rcode = 1
   	goto bspexit
   	end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDailyLogVal] TO [public]
GO
