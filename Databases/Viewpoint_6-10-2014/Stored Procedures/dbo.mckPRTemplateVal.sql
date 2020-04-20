SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTemplateVal    Script Date: 8/28/99 9:33:35 AM ******/
   CREATE proc [dbo].[mckPRTemplateVal]
   /***********************************************************
    * CREATED BY: kb 11/20/97
    * MODIFIED By : kb 11/20/97
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *
    * USAGE:
    * validates PR Templates from PRTM
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   @prco     PR Co to validate agains 
    *   @template PR Templateto validate
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs otherwise Description of EarnCode
    * RETURN VALUE
    *   0         success  *   1         Failure
    *****************************************************/ 
   
   	(@prco bCompany = 0, @template smallint, @PMCo bCompany = 0, @Project bJob = '', @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @template is null
   	begin
   	select @msg = 'Missing PR Template!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description
   	from dbo.PRTM with (nolock)
   	where PRCo = @prco and Template=@template
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Template not on file!', @rcode = 1
   	goto bspexit
   	end
   
   IF EXISTS(SELECT TOP 1 1 FROM JCJMPM WHERE @PMCo = PMCo AND @Project = Project AND JobStatus <> 0)
	BEGIN
		SELECT @msg = 'Project already interfaced.  Contact accounting for changes.', @rcode = 1
		GOTO bspexit
	END

   bspexit:
   	return @rcode

GO
