SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCACInfo    Script Date: 8/28/99 9:32:55 AM ******/
   CREATE  proc [dbo].[bspJCACInfo]
   /*************************************
    * CREATED BY: SE   11/10/96
    * MODIFIED By : SE 11/10/96
    *				TV - 23061 added isnulls
    * USAGE:
    * used by JCACRUN to get information about the Allocation 
    * before it is run.
    * Pass in :
    *	JCCo, AllocationCode
    *
    * Returns
   
    *	Returns a result set of the information from a specific JCAC Record
    *
    * Error returns no rows
   *******************************/
   (@jcco bCompany, @alloccode smallint)
   as
   set nocount on
   
   declare @costtypes varchar(60), @costtype tinyint
   declare @allocamtrate float(15), @alloccolumn varchar(30)
   
   
   
   done:
   
   select @allocamtrate = case when AmtRateFlag='A' Then AllocAmount else AllocRate END
   from bJCAC where JCCo=@jcco and AllocCode=@alloccode
   
   select @alloccolumn = case when AmtRateFlag='A' Then AmtColumn else RateColumn END
   from bJCAC where JCCo=@jcco and AllocCode=@alloccode
   
   
      select SelectJobs, SelectDepts, AllocBasis, MthDateFlag, AmtRateFlag, 'AllocAmtRate'=@allocamtrate,
             'AllocColumn'=@alloccolumn, 'AllocCostTypes'=@costtypes, Phase, CostType 
      from bJCAC where JCCo=@jcco and AllocCode = @alloccode
   
      select CostType from JCAT where JCCo=@jcco and AllocCode=@alloccode

GO
GRANT EXECUTE ON  [dbo].[bspJCACInfo] TO [public]
GO
