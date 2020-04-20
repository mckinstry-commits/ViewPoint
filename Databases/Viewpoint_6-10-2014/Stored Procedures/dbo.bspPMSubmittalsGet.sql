SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
   CREATE    procedure [dbo].[bspPMSubmittalsGet]
   /************************************************************************
   * Created By:	GF 06/01/2004
   * Modified By:	
   *
   * Purpose of Stored Procedure to get submittals for copying
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   (@pmco bCompany, @project bProject, @submittaltype bDocType, @copy_items bYN, @copy_revisions bYN)
   as
   set nocount on
   
   declare @rcode int
   
   set @rcode = 0
   
   if isnull(@submittaltype,'') = '' set @submittaltype = null
   
   -- get submittal information
   select @copy_items, @copy_revisions, SubmittalType, Submittal, Rev, Description
   from PMSM with (nolock) where PMCo=@pmco and Project = @project
   and SubmittalType = isnull(@submittaltype, SubmittalType) and Rev=0
   -- -- --and ((@origonly = 'Y' and Rev=0) or (@origonly <> 'Y' and Rev=Rev))
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSubmittalsGet] TO [public]
GO
