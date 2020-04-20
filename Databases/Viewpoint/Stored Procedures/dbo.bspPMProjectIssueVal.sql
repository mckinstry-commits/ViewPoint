SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMProjectIssueVal    Script Date: 8/28/99 9:35:17 AM ******/
   CREATE  proc [dbo].[bspPMProjectIssueVal]
   /*************************************
   * CREATED BY    : CJW  12/3/97
   * LAST MODIFIED : SAE  12/12/97   'Issue now accepts Chars
   * validates PM Issues
   *
   * Pass:
   *	PM Company
   *	PM Project
   *	PM Issue
   *
   * Returns:
   
   
   *
   * Success returns:
   *	0 and Description from Issue
   *
   * Error returns:
   
   *	1 and error message
   *******
   *******************************/
   (@co bCompany, @project bJob = null, @sissue varchar(10) = null, @status int output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @issue bIssue
   
   select @rcode = 0
   
   if @project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end
   
   if substring(@sissue,1,1) in ('N','n')
   	begin
       select @msg = 'New Issue', @rcode=0
       goto bspexit
   	end
   
   if isnumeric(@sissue)=0
   	begin
       select @msg = 'Issue must be numeric!', @rcode=1
       goto bspexit
   	end
   
   select @issue = convert(int,@sissue)
   if @issue is null
   	begin
   	select @msg = 'Missing Issue!', @rcode = 1
   	goto bspexit
   	end
   
   select @status = Status, @msg = Description 
   from bPMIM with (nolock) where PMCo = @co and Project = @project and Issue = @issue
   if @@rowcount = 0
   	begin
   	select @msg = 'PM Issue not on file!', @rcode = 1
   	end
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMProjectIssueVal] TO [public]
GO
