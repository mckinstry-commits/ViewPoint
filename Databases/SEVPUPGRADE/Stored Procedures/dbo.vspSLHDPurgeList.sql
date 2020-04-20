SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLHDPurgeList    Script Date: 10/4/06  ******/
   CREATE   proc [dbo].[vspSLHDPurgeList]
   /***********************************************************
    * CREATED BY	: DC 10/4/06
    * MODIFIED BY	: 
    *
    * USAGE:
	* This routine is used to load listbox with SL's where Status = 2 i.e closed and
	* Closed Month is <= Purge through Month
	*
    *
    * INPUT PARAMETERS
    *   Co  		SL Company
	*	MthClose	Closed Month
    *
	*
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
       (@slco bCompany = 0, @mthclosed bMonth)
   as
   
   set nocount on
   
   
	Select SL, '   ' + isnull(Description,'') 
	from SLHD with (NOLOCK)
	where SLCo = @slco And Status = 2 And InUseBatchId is null And MthClosed <= @mthclosed


   
   return 0

GO
GRANT EXECUTE ON  [dbo].[vspSLHDPurgeList] TO [public]
GO
