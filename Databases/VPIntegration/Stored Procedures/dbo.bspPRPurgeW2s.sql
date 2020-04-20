SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeW2s    Script Date: 8/28/99 9:35:39 AM ******/
   CREATE procedure [dbo].[bspPRPurgeW2s]
   /***********************************************************
    * CREATED BY: EN 12/08/00
	* Modified:  mh 1/30/2007 - Do not purge PRWI.  Issue 123749
    *			CHS 10/6/2010 - issue 137687
    *			Dan So 07/24/2012 - D-02774 - deleted references to PRWM
    *
    * USAGE:
    * Purges W-2 Header and State info for a given tax year.  Files
    * involved are bPRWH, bPRWI, bPRWM, bPRWC, bPRWT, bPRWE, bPRWA,
    * bPRWS, and bPRWL.
    *
    * INPUT PARAMETERS
    *   @PRCo		PR Company
    *   @TaxYear	Tax Year to purge
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
   (@PRCo bCompany, @TaxYear char(4),
   	 @errmsg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   delete from bPRWE where PRCo=@PRCo and TaxYear = @TaxYear
   delete from bPRWT where PRCo=@PRCo and TaxYear = @TaxYear
   delete from bPRWC where PRCo=@PRCo and TaxYear = @TaxYear
   --Issue 123749
   --delete from bPRWI where TaxYear = @TaxYear
   delete from bPRWH where PRCo=@PRCo and TaxYear = @TaxYear
   
   -- Though bPRWE delete trigger purges bPRWA, bPRWS and bPRWL for each employee
   -- in bPRWE for company/tax year, ensure that ALL entries for company/tax year are
   -- purged from those tables.
   delete from bPRWA where PRCo=@PRCo and TaxYear = @TaxYear
   delete from bPRWS where PRCo=@PRCo and TaxYear = @TaxYear
   delete from bPRWL where PRCo=@PRCo and TaxYear = @TaxYear
   
   --#137687
   delete from bPRW2MiscDetail where PRCo=@PRCo and TaxYear = @TaxYear
   delete from bPRW2MiscHeader where PRCo=@PRCo and TaxYear = @TaxYear
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeW2s] TO [public]
GO
