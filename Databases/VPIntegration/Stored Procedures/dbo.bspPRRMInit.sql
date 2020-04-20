SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRRMInit    Script Date: 8/28/99 9:35:39 AM ******/
  
  CREATE          procedure [dbo].[bspPRRMInit]
  /***********************************************************
   * CREATED BY: GG 11/11/98
   * MODIFIED By : GG 12/21/98 - updated for 1999 tax routines
   *              EN 12/07/99 - updated for 2000 tax routines
   *              GG 12/08/99 - update bPRRM with current tax procedures, added NY Disability
   *              EN 12/27/99 - update routine name for Michigan, Vermont, and Massachusetts
   *              GG 05/02/00 - fix bPRRM update - limit to a single 'like' entry
   *              EN 5/30/00 - fixed to look up routine names in sysobjects rather than have them hardcoded and have to keep updating this bsp
   *              EN 9/13/00 - added NY Worker's Comp update
   *              EN 12/28/00 - fixed to use today's date as last update date
   *              EN 8/21/01 - issue 14405
   *              EN 9/10/01 - issue 13564 - add feature for calculating Earned Income Credit
   *				EN 4/19/02 - issue 16832 - add Philadelphia city tax to the init list
   *				EN 10/9/02 - issue 18877 change double quotes to single
   *				EN 9/15/03 - issue 21186 add Benefit based on day of week routine (bspPRDailyBen)
   *				EN 2/10/04 - issue 23613 add init code for bspPRORM??
   *				EN 8/03/04 issue 24545  add init for bspPRExemptRateOfGross
   *				EN 7/05/05 issue 29207  remove code to init NY WC routine (bspPRNYI)
   *				EN 9/5/06 issue 122062  added init for bspPRKentonKYC06
   *				EN 10/5/07 issue 119634  removed code to init Multnomah county tax
   *				EN 6/6/08 #127015  add initialization for Canadian tax routines and use HQCO_DefaultCountry to 
   *							determine which set of routines to init
   *				EN 6/17/08 #127270  add initialization for Australia PAYG tax routine
   *				EN 3/13/2009 #127888 add init for Australia ROSG, Allowance and AllowanceRDO routines
   *				EN 8/10/09 - #133605 add init for AUS Superannuation Guarantee routine
   *				EN 2/15/2010 #136039 add init for AUS RDO Accrual routine and rename ROSG routine to RateOfGros
   *										and split AllowRDO routine to AllowRDO36 and AllowRDO38
   *				EN 2/19/2010 #132653 add init for AUS AmtPerDay, OTMealAllow, OTCribAllow, and RPHwkend routines
   *				EN 3/09/2010 #136099 add init for Virgin Island tax routine
   *				CHS 10/14/2010 #139417 added Guam tax routine
   *				EN 4/18/2011 D-01575 #143739  [AUS] Added routine AllowRDO (bspPR_AU_AllowWithRDOFactor)
   *				CHS 05/12/2010 #142867 added Saipan tax routine
   *				KK/EN 06/09/2011 TK-05849 Added ROSG and AmtPerDay to CA list
   *				EN 5/22/2012 B-09715/TK-15008 Removed code to replace proc name on RateOfGros routine and removed
   *												old moldy code to replace ROG routine with RateOfGros routine because
   *												that is soooo passe
   *				EN 5/22/2012 B-09715/TK-15008 Removed code to replace proc name on Allowance routine
   *				EN 11/27/2012 D-05383/#146657 added code to init new routine 'Addl Med' (vspPRMedicareSurcharge)
   *
   * USAGE:
   * Initializes and updates the PR Routine Master with default information
   * for all Viewpoint supplied tax routines.
   *
   *  INPUT PARAMETERS
   *   @prco - company
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
  	(@prco bCompany = null, @msg varchar(60) output)
  as
  set nocount on
  
  declare @rcode int, @date bDate, @cnt int, @currentname sysname, @country varchar(2)
  
  select @rcode = 0, @date = convert(varchar,getdate(),101)	-- today's date used as last update date
  
  -- validate PR Company
  if @prco is null
  	begin
  	select @msg = 'Missing PR Company #.  Cannot initialize Routines.', @rcode = 1
  	goto bspexit
  	end
  
  if not exists(select * from dbo.bPRCO with (nolock) where PRCo = @prco)
  	begin
  	select @msg = 'Invalid PR Company #.  Cannot initialize Routines!', @rcode = 1
  	goto bspexit
  	end

  -- get country the company resides in  
  select @country = DefaultCountry from dbo.bHQCO with (nolock) where HQCo = @prco

  -- default routine set based on the country
  if @country = 'US'
  begin
	  -- Alabama State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRALT%' and name not like 'bspPRALT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRALT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRALT%'
	  if @cnt = 0	  -- add most current routine
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AL Tax', 'Alabama Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1     -- update with current routine if only one entry exists
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRALT%'
	  
	  -- Arkansas State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRART%' and name not like 'bspPRART9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRART%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRART%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AR Tax', 'Arkansas Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRART%'
	  
	  -- Arizona State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRAZT%' and name not like 'bspPRAZT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRAZT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRAZT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AZ Tax', 'Arizona Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRAZT%'
	  
	  -- California State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRCAT%' and name not like 'bspPRCAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRCAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRCAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'CA Tax', 'California Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRCAT%'
	  
	  -- Colorado Occupational Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRCOO%' and name not like 'bspPRCOO9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRCOO%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRCOO%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'CO OP Tax', 'Colorado Occup Priv Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRCOO%'
	  
	  -- Colorado State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRCOT%' and name not like 'bspPRCOT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRCOT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRCOT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'CO Tax', 'Colorado Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRCOT%'
	  
	  -- Connecticut State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRCTT%' and name not like 'bspPRCTT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRCTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRCTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'CT Tax', 'Connecticut Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRCTT%'
	  
	  -- District of Columbia Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRDCT%' and name not like 'bspPRDCT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRDCT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRDCT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'DC Tax', 'District of Columbia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRDCT%'
	  
	  -- Delaware State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRDET%' and name not like 'bspPRDET9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRDET%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRDET%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'DE Tax', 'Delaware Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRDET%'

	  -- Federal Income Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRFWT%[^old]' and name not like 'bspPRFWT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRFWT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRFWT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'FED Tax', 'Federal Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
	  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
	  where PRCo = @prco and ProcName like 'bspPRFWT%'
	  
	  -- Georgia State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRGAT%' and name not like 'bspPRGAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRGAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRGAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'GA Tax', 'Georgia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRGAT%'
	  
	  -- Hawaii State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRHIT%' and name not like 'bspPRHIT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRHIT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRHIT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'HI Tax', 'Hawaii Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date         -- most current Hawaii tax proc
		  where PRCo = @prco and ProcName like 'bspPRHIT%'
	  
	  -- Iowa State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRIAT%' and name not like 'bspPRIAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRIAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRIAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'IA Tax', 'Iowa Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRIAT%'
	  
	  -- Idaho State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRIDT%' and name not like 'bspPRIDT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRIDT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRIDT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'ID Tax', 'Idaho Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRIDT%'
	  
	  -- Illinois State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRILT%' and name not like 'bspPRILT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRILT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRILT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'IL Tax', 'Illinois Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRILT%'
	  
	  -- Indiana County Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRINC%' and name not like 'bspPRINC9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRINC%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRINC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'INCnty Tax', 'Indiana County Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRINC%'
	  
	  -- Indiana State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRINT%' and name not like 'bspPRINT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRINT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRINT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'IN Tax', 'Indiana Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRINT%'
	  
	  -- Kansas State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRKST%' and name not like 'bspPRKST9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRKST%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRKST%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'KS Tax', 'Kansas Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRKST%'
	  
	  -- Kentucky State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRKYT%' and name not like 'bspPRKYT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRKYT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRKYT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'KY Tax', 'Kentucky Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRKYT%'

	  -- Kenton County, Kentucky State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRKentonKYC%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRKentonKYC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'KenKY Tax', 'Kenton County, Kentucky Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRKentonKYC%'
	  
	  -- Louisiana State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRLAT%' and name not like 'bspPRLAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRLAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRLAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'LA Tax', 'Louisiana Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRLAT%'
	  
	  -- Massachusetts State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMAT%' and name not like 'bspPRMAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MA Tax', 'Massachusetts Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMAT%'
	  
	  
	  -- Maryland State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMDT%' and name not like 'bspPRMDT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMDT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMDT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MD Tax', 'Maryland Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMDT%'
	  
	  -- Maine State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMET%' and name not like 'bspPRMET9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMET%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMET%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'ME Tax', 'Maine Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMET%'
	  
	  -- Michigan City Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMIC%' and name not like 'bspPRMIC9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMIC%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMIC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MICity Tax', 'Michigan City Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMIC%'
	  
	  -- Michigan State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMIT%' and name not like 'bspPRMIT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMIT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMIT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MI Tax', 'Michigan Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMIT%'
	  
	  -- Minnesota State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMNT%' and name not like 'bspPRMNT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMNT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMNT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MN Tax', 'Minnesota Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMNT%'
	  
	  -- Missouri State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMOT%' and name not like 'bspPRMOT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMOT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMOT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MO Tax', 'Missouri Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMOT%'
	  
	  -- Mississippi State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMST%' and name not like 'bspPRMST9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMST%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMST%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MS Tax', 'Mississipi Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMST%'
	  
	  -- Montana State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRMTT%' and name not like 'bspPRMTT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MT Tax', 'Montana Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMTT%'
	  
	  -- North Carolina State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNCT%' and name not like 'bspPRNCT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNCT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNCT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NC Tax', 'North Carolina Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNCT%'
	  
	  -- North Dakota State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNDT%' and name not like 'bspPRNDT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNDT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNDT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'ND Tax', 'North Dakota Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNDT%'
	  
	  -- Nebraska State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNET%' and name not like 'bspPRNET9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNET%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNET%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NE Tax', 'Nebraska Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNET%'
	  
	  -- New Jersey State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNJT%' and name not like 'bspPRNJT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNJT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNJT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NJ Tax', 'New Jersey Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNJT%'
	  
	  -- New Mexico State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNMT%' and name not like 'bspPRNMT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNMT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNMT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NM Tax', 'New Mexico Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNMT%'
	  
	  -- New York City Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNYC%' and name not like 'bspPRNYC9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNYC%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNYC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NYCity Tax', 'New York City Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNYC%'
	  
	  -- New York State Disability (liability)
	  select @currentname = max(name) from sysobjects where name like 'bspPRNYD%' and name not like 'bspPRNYD9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNYD%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNYD%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NYDis Tax', 'New York Disability Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNYD%'
	  
	  -- New York State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNYT%' and name not like 'bspPRNYT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNYT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNYT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NY Tax', 'New York Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNYT%'
	  
	  -- Yonkers City Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRNYY%' and name not like 'bspPRNYY9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRNYY%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNYY%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NYY Tax', 'Yonkers City Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRNYY%'
	  
	  ---- New York Worker's Compensation
	  --select @currentname = max(name) from sysobjects where name like 'bspPRNYI%'
	  --select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRNYI%'
	  --if @cnt = 0
	  --	insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
	  --	values (@prco, 'NY WC', 'New York Worker''s Compensation', @currentname, @date, 0, 0, 0, 0)
	  --if @cnt = 1
	  --    update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
	  --    where PRCo = @prco and ProcName like 'bspPRNYI%'
	  
	  -- Ohio State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPROHT%' and name not like 'bspPROHT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPROHT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPROHT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OH Tax', 'Ohio Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPROHT%'
	  
	  -- Oklahoma State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPROKT%' and name not like 'bspPROKT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPROKT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPROKT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OK Tax', 'Oklahoma Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPROKT%'
	  
	  -- Oregon State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRORT%' and name not like 'bspPRORT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRORT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRORT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OR Tax', 'Oregon Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRORT%'
	  
	  -- Ohio School District Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPROST%' and name not like 'bspPROST9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPROST%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPROST%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OHSch Tax', 'Ohio School District Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPROST%'
	  
	  -- Philadelphia City Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRPHC%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRPHC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'PHCity Tax', 'Philadelphia City Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRPHC%'
	  
	  -- Puerto Rico Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRPRT%' and name not like 'bspPRPRT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRPRT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRPRT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'PR Tax', 'Puerto Rico Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRPRT%'
	  
	  -- Rhode Island State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRRIT%' and name not like 'bspPRRIT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRRIT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRRIT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'RI Tax', 'Rhode Island Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRRIT%'
	  
	  -- South Carolina State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRSCT%' and name not like 'bspPRSCT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRSCT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRSCT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'SC Tax', 'South Carolina Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRSCT%'
	  
	  -- Utah State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRUTT%' and name not like 'bspPRUTT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRUTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRUTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'UT Tax', 'Utah Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRUTT%'
	  
	  -- Virginia State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRVAT%' and name not like 'bspPRVAT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRVAT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRVAT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'VA Tax', 'Virginia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRVAT%'
	  
	  -- Vermont State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRVTT%' and name not like 'bspPRVTT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRVTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRVTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'VT Tax', 'Vermont Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRVTT%'
	  
	  -- #136099 Virgin Islands Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRVIT%' and name not like 'bspPRVIT%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRVIT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRVIT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'VI Tax', 'Virgin Islands Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRVIT%'
	  
	  	  -- #139417 Guam Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRGUT%' and name not like 'bspPRGUT%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRGUT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRGUT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'GU Tax', 'Guam Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRGUT%'
		  
		-- #142867  
	  select @currentname = max(name) from sysobjects where name like 'bspPRMPT%' and name not like 'bspPRMPT%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRMPT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRMPT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MP Tax', 'Saipan Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRMPT%'		  
		  
	  -- Wisconsin State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRWIT%' and name not like 'bspPRWIT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRWIT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRWIT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'WI Tax', 'Wisconsin Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update  dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRWIT%'
	  
	  -- West Virginia State Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPRWVT%' and name not like 'bspPRWVT9%'
	  if @currentname is null select @currentname = max(name) from sysobjects where name like 'bspPRWVT%'
	  select @cnt = count(*) from  dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRWVT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'WV Tax', 'West Virginia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPRWVT%'
	  
	  -- EIC  - issue 13564 - add feature for calculating Earned Income Credit
	  select @currentname = max(name) from sysobjects where name like 'bspPREIC%'
	  
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPREIC%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'EIC', 'Earned Income Credit', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPREIC%'

	  -- D-05383/#146657 Additional Medicare Surcharge
	  SELECT @currentname = MAX(name) FROM sysobjects WHERE name LIKE 'vspPRMedicareSurcharge%'
	  
	  IF NOT EXISTS (SELECT * FROM dbo.bPRRM WHERE PRCo = @prco AND ProcName LIKE 'vspPRMedicareSurcharge%')
	  BEGIN
		  INSERT dbo.bPRRM	(PRCo,			Routine,		[Description],	
							 ProcName,		LastUpdated,	MiscAmt1,	MiscAmt2,	MiscAmt3,	MiscAmt4)
		  VALUES			(@prco,			'Addl Med',		'Additional Medicare Surcharge',
							 @currentname,	@date,			0,			0,			0,			0)
	  END
	  ELSE
	  BEGIN
		  UPDATE dbo.bPRRM 
		  SET ProcName = @currentname, LastUpdated = @date
		  WHERE PRCo = @prco AND ProcName LIKE 'bspPRMedicareSurcharge%'
	  END
	  
  end

  if @country = 'CA' --Canada
  begin
	  -- Federal Income Tax
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_FWT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_FWT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'FED Tax', 'Federal Income Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
	  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
	  where PRCo = @prco and ProcName like 'bspPR_CA_FWT%'

	  -- Alberta
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_ABT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_ABT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AB Tax', 'Alberta Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update  dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_ABT%'

	  -- British Columbia
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_BCT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_BCT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'BC Tax', 'British Columbia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_BCT%'

	  -- Manitoba
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_MBT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_MBT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'MB Tax', 'Manitoba Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_MBT%'

	  -- New Brunswick
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_NBT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_NBT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NB Tax', 'New Brunswick Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_NBT%'

	  -- Newfoundland and Labrador
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_NLT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_NLT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NL Tax', 'Newfoundland/Labrador Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_NLT%'

	  -- Nova Scotia
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_NST%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_NST%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NS Tax', 'Nova Scotia Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_NST%'

	  -- Northwest Territories
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_NTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_NTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NT Tax', 'Northwest Territories Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_NTT%'

	  -- Nunavut
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_NUT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_NUT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'NU Tax', 'Nunavut Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_NUT%'

	  -- Ontario
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_ONT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_ONT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'ON Tax', 'Ontario Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_ONT%'

	  -- Prince Edward Island
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_PET%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_PET%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'PE Tax', 'Prince Edward Island Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_PET%'

	  -- Saskatchewan
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_SKT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_SKT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'SK Tax', 'Saskatchewan Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_SKT%'

	  -- Yukon
	  select @currentname = max(name) from sysobjects where name like 'bspPR_CA_YTT%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_CA_YTT%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'YT Tax', 'Yukon Tax', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_CA_YTT%'

	  -- Canada Pension Plan
	  select @currentname = max(name) from sysobjects where name = 'bspPRCPP'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'CPP'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'CPP', 'Canada Pension Plan', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and Routine = 'CPP'
		  
	  -- Rate of Subject Gross
	  if exists (select * from dbo.bPRRM with (nolock) where PRCo=@prco and Routine = 'ROSG')
		delete from dbo.bPRRM where PRCo=@prco and Routine = 'ROSG'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'RateOfGros'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'RateOfGros', 'Earn: Rate of Subject Gross', 'bspPR_CA_ROSG', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_CA_ROSG', LastUpdated = @date
		  where PRCo = @prco and Routine = 'RateOfGros'
		  
	  -- Amount Per Day
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'AmtPerDay'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AmtPerDay', 'Earn: Amount Per Day', 'bspPR_CA_AmtPerDay', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_CA_AmtPerDay', LastUpdated = @date
		  where PRCo = @prco and Routine = 'AmtPerDay'
  end

  if @country = 'AU' --Australia
  begin
	  -- PAYG (Pay As You Go)
	  select @currentname = max(name) from sysobjects where name like 'bspPR_AU_PAYG%'
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPR_AU_PAYG%'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'PAYG Tax', 'Dedn: Pay As You Go', @currentname, @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
		  where PRCo = @prco and ProcName like 'bspPR_AU_PAYG%'

	  -- Allowance
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'Allowance'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'Allowance', 'Earn: Allowance', 'bspPR_AU_Allowance', @date, 0, 0, 0, 0)

	  -- Allowance With RDO Factor
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'AllowRDO'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AllowRDO', 'Earn: RDO factored Allowance', 'bspPR_AU_AllowWithRDOFactor', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_AllowWithRDOFactor', LastUpdated = @date
		  where PRCo = @prco and Routine = 'AllowRDO'


	  -- Allowance with RDO factor adjustment for 36 hour work week
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'AllowRDO36'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AllowRDO36', 'Earn: RDO factord 36 day allow', 'bspPR_AU_AllowRDO36', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_AllowRDO36', LastUpdated = @date
		  where PRCo = @prco and Routine = 'AllowRDO36'

	  -- Allowance with RDO factor adjustment for 38 hour work week
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'AllowRDO38'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AllowRDO38', 'Earn: RDO factord 38 day allow', 'bspPR_AU_AllowRDO38', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_AllowRDO38', LastUpdated = @date
		  where PRCo = @prco and Routine = 'AllowRDO38'

	  -- Rate of Subject Gross
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'RateOfGros'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'RateOfGros', 'Earn: Rate of Subject Gross', 'bspPR_AU_ROSG', @date, 0, 0, 0, 0)

	  -- Superannuation
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'SuperMin'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'SuperMin', 'Liab: Superannuation', 'bspPR_AU_SuperWithMin', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_SuperWithMin', LastUpdated = @date
		  where PRCo = @prco and Routine = 'SuperMin'

	  -- #136039 RDO Accrual
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'RDOAccrual'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'RDOAccrual', 'Earn: RDO Accrual', 'bspPR_AU_RDOAccrual', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_RDOAccrual', LastUpdated = @date
		  where PRCo = @prco and Routine = 'RDOAccrual'

	  -- #132653 Amount Per Day
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'AmtPerDay'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'AmtPerDay', 'Earn: Amount Per Day', 'bspPR_AU_AmtPerDay', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_AmtPerDay', LastUpdated = @date
		  where PRCo = @prco and Routine = 'AmtPerDay'

	  -- #132653 OT Meal Allowance
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'OTMeal'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OTMeal', 'Earn: Overtime Meal Allowance', 'bspPR_AU_OTMealAllow', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_OTMealAllow', LastUpdated = @date
		  where PRCo = @prco and Routine = 'OTMeal'

	  -- #132653 OT Crib Allowance
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'OTCrib'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OTCrib', 'Earn: Overtime Crib Allowance', 'bspPR_AU_OTCribAllow', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_OTCribAllow', LastUpdated = @date
		  where PRCo = @prco and Routine = 'OTCrib'

	  -- #132653 OT Meal/Rest/Crib Allowance
	  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'OTCribWknd'
	  if @cnt = 0
  		insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  		values (@prco, 'OTCribWknd', 'Earn: Overtime Meal/Rest/Crib', 'bspPR_AU_OTWeekendCrib', @date, 0, 0, 0, 0)
	  if @cnt = 1
		  update dbo.bPRRM set ProcName = 'bspPR_AU_OTWeekendCrib', LastUpdated = @date
		  where PRCo = @prco and Routine = 'OTCribWknd'

  end
	  
  -- Exempt Rate of Gross
  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = 'ExemptROG'
  if @cnt = 0
  	insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  	values (@prco, 'ExemptROG', 'Exempt Rate Of Gross', 'bspPRExemptRateOfGross', @date, 0, 0, 0, 0)
  if @cnt = 1
      update dbo.bPRRM set Description = 'Exempt Rate Of Gross', ProcName = 'bspPRExemptRateOfGross', LastUpdated = @date
      where PRCo = @prco and Routine = 'ExemptROG'
  
  -- Benefit based on day of week
  select @currentname = max(name) from sysobjects where name like 'bspPRDailyBen%'
  select @cnt = count(*) from dbo.bPRRM with (nolock) where PRCo = @prco and ProcName like 'bspPRDailyBen%'
  if @cnt = 0
  	insert dbo.bPRRM(PRCo, Routine, Description, ProcName, LastUpdated, MiscAmt1, MiscAmt2, MiscAmt3, MiscAmt4)
  	values (@prco, 'Daily Ben', 'Benefit based on day of week', @currentname, @date, 0, 0, 0, 0)
  if @cnt = 1
      update dbo.bPRRM set ProcName = @currentname, LastUpdated = @date
      where PRCo = @prco and ProcName like 'bspPRDailyBen%'
  
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRRMInit] TO [public]
GO
