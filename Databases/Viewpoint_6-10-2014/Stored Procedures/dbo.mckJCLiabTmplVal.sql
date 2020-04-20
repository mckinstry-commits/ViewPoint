SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCLiabTmplVal    Script Date: 8/28/99 9:32:59 AM ******/
CREATE proc [dbo].[mckJCLiabTmplVal]
/***********************************************************
* CREATED BY:		SE		10/2/96
* MODIFIED By:		SE		10/2/96
*					TV		23061 added isnulls
*					CHS		06/10/2009 - #132119 - added description
*
* USAGE:
* validates JC liablility tamplate.
* an error is returned if any of the following occurs
* no liability template passed, no liablility template found.
*
* INPUT PARAMETERS
*   JCCo   JC Co to validate against 
*   LiabTemplate  Insurance template to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description of Template description
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany = 0, @liabtemplate smallint = null, @Project bJob = '', @desc varchar(60) output, @msg varchar(255) output)

as
set nocount on   
   
   	declare @rcode int
   	select @rcode = 0
   
   if @jcco is null
   	begin
   	select @msg = 'Missing JC Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @liabtemplate is null
   	begin
   	select @msg = 'Missing Liability Template!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description, @desc = Description
   	from JCTH
   	where JCCo = @jcco and LiabTemplate = @liabtemplate
   
   if @@rowcount = 0
   	begin
   	select @msg = 'Liability template not on file!', @desc = 'New liability template.',@rcode = 1
   	goto bspexit
   	end
   
   IF EXISTS(SELECT TOP 1 1 FROM JCJM WHERE @jcco = JCCo AND @Project = Job AND JobStatus <> 0)
	BEGIN
		SELECT @msg = 'This project has already been interfaced.  Contact Accounting for changes to the Liability Template.', @rcode = 1
		GOTO bspexit
	END

   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[mckJCLiabTmplVal] TO [public]
GO
