SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRWILoad    Script Date: 8/28/99 9:35:43 AM ******/
   CREATE       proc [dbo].[bspPRWILoad]

/* Procedure is obsolete.  See vspPRW2Initialize mh 12/13/06 */

    /******************************************************************
    *  Created: EN 12/17/98
    *  Modified: EN 1/12/99
    *  Modified: EN 10/18/99 - add items to load for 1999
    *  Modified: EN 10/21/99 - allow to load same item configuration for future years as is used for the current one
    *            EN 3/23/00 - within the code, specify the lastest year it was updated for and warn if user tries to initialize past that year
    *                          ** Note: @LatestYear will now have to be updated each year **
    *            EN 3/23/00 - cleaned up the code a bit and included warning if user tries to initialize a year prior to 1998
    *            MV 8/2/01 - Issue 11918 added code 'V' for nonstatutory stock options and changed @LatestYear = 2001
    *            EN 9/5/01 - issue 11999 removed reference to Box 14 since box #'s change occasionally
    *			  EN 11/9/01 - issue 15217 don't init item 18 as of TaxYear 2001
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *			  EN 10/10/02 - issue 18916 changed @LatestYear to 2002
    *			  GF 11/05/02 - Item 15 - Military Pay is no longer valid. issue #19255
    *			  EN 9/11/03 - issue 22448 changed @LatestYear to 2003
    *			EN 8/18/04 - issue 24336  added code W and changed @LatestYear to 2004
    *			EN 8/10/05 - issue 26787  added codes Y and Z and changed @LatestYear to 2005
    *			EN 9/07/05 - issue 26938  added codes for Misc lines 3 & 4
	*			EN 9/5/06 - issue 122395  updated @LatestYear to 2006
	*			EN 9/6/06 - issue 122401  add codes AA (item #48) and AB (item #49)
    *			EN 11/07/06 - issue 123025  code for item #49 is actually BB, not AB
	*			mh 05/06/09 - PRWI load is now being done within vspPRW2Initialize
    *
    *
    * USAGE:
    * Loads/reloads item information for a specific tax year into bPRWI.
    *
    * This stored procedure needs to be updated yearly to include item
    * information for each tax year.
    * Returns an error if this SP has not been updated for the
    * tax year specified.
    *
    * INPUT PARAMETERS
    *   TaxYear	tax year to load
    *
    * OUTPUT PARAMETERS
    *   @LatestYear    the latest year to be updated to this bsp
    *   @msg      error message if error occurs
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *******************************************************************/
   (@TaxYear char(4), @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int, @LatestYear char(4)
   
   select @rcode = 0, @LatestYear = '2006'
   
   /* load PRWI */
   -- If tax year specified is before 1998, warn user that item cannot be loaded unless for some reason that information is found in bPRWI
   if @TaxYear < '1998' and not exists (select * from bPRWI where TaxYear = @TaxYear)
       begin
       select @msg = 'Cannot initialize items list for years prior to 1998.', @rcode = 1
        goto bspexit
       end
   
   -- initialize years starting at 1998
   if @TaxYear >= '1998'
   	begin
   	 /* clear out pre-existing entries */
   	 delete bPRWI
   	 where TaxYear = @TaxYear
   
   	 /* load item information */
   	 insert bPRWI
   	 select @TaxYear, 1,'Federal Wages','S',''
   	 insert bPRWI
   	 select @TaxYear, 2,'Federal Tax Withheld','A',''
   	 insert bPRWI
   	 select @TaxYear, 3,'Social Security Wages','E',''
   	 insert bPRWI
   	 select @TaxYear, 4,'Social Security Tax Withheld','A',''
   	 insert bPRWI
   	 select @TaxYear, 5,'Medicare Wages','E',''
   	 insert bPRWI
   	 select @TaxYear, 6,'Medicare Tax Withheld','A',''
   	 insert bPRWI
   	 select @TaxYear, 7,'Social Security Tips','A',''
   	 insert bPRWI
   	 select @TaxYear, 8,'Advance EIC','A',''
   	 insert bPRWI
   	 select @TaxYear, 9,'Dependent Care Benefits','A',''
   	 insert bPRWI
   	 select @TaxYear,10,'Deferred Comp - 401(k)','A','D'
   	 insert bPRWI
   	 select @TaxYear,11,'Deferred Comp - 403(b)','A','E'
   	 insert bPRWI
   	 select @TaxYear,12,'Deferred Comp - 408(k)(6)','A','F'
   	 insert bPRWI
   	 select @TaxYear,13,'Deferred Comp - 457(b)','A','G'
   	 insert bPRWI
   	 select @TaxYear,14,'501(c)(18)(D) Tax Exempt Plans','A','H'
   	 if @TaxYear<'2002' -- issue #19255
   		 begin
   		 insert bPRWI
   		 select @TaxYear,15,'Military Pay','A','Q'
   		 end
   	 insert bPRWI
   	 select @TaxYear,16,'Non-qualified 457 Dist/Contrib','A',''
   	 insert bPRWI
   	 select @TaxYear,17,'Non-qualified non 457','A',''
   	 if @TaxYear<'2001' --issue 15217 - don't init item 18 as of tax year 2001
   		begin
   		insert bPRWI
   		select @TaxYear,18,'Fringe Benefits','A',''
   		end
   	 insert bPRWI
   	 select @TaxYear,19,'Group Term Life Ins. > $50K','A','C'
   	 insert bPRWI
   	 select @TaxYear,20,'Allocated Tips','A',''
   	 insert bPRWI
   	 select @TaxYear,21,'Uncollected Soc. Sec. on Tips','A','A'
   	 insert bPRWI
   	 select @TaxYear,22,'Uncollected Med. Tax on Tips','A','B'
   	 insert bPRWI
   	 select @TaxYear,23,'Employer Contributions to MSA','A','R'
   	 insert bPRWI
   	 select @TaxYear,24,'Simple Retiremnt Acct - 408(p)','A','S'
   	 insert bPRWI
   	 select @TaxYear,25,'Adoption Expenses','A','T'
   	 insert bPRWI
   	 select @TaxYear,26,'Puerto Rico Wages','A',''
   	 insert bPRWI
   	 select @TaxYear,27,'Puerto Rico Commissions','A',''
   	 insert bPRWI
   	 select @TaxYear,28,'Puerto Rico Allowances','A',''
   	 insert bPRWI
   	 select @TaxYear,29,'Puerto Rico Tips','A',''
   	 insert bPRWI
   	 select @TaxYear,30,'Puerto Rico Tax Withheld','A',''
   	 insert bPRWI
   	 select @TaxYear,31,'Puerto Rico Retirement Fund','A',''
   	 insert bPRWI
   	 select @TaxYear,32,'Virgin Islands, Guam ... wages','A',''
   	 insert bPRWI
   	 select @TaxYear,33,'Virgin Islands, Guam ... w/h','A',''
   	 insert bPRWI
   	 select @TaxYear,34,'Nontaxable Sick Pay','A','J'
   	 insert bPRWI
   	 select @TaxYear,35,'Tax on Goldn Parachute Paymnts','A','K'
   	 insert bPRWI
   	 select @TaxYear,36,'Nontax Reimb Business Expenses','A','L'
   	 insert bPRWI
   	 select @TaxYear,37,'Uncollected Soc Sec Ins Tax','A','M'
   	 insert bPRWI
   	 select @TaxYear,38,'Uncollected Medicare Ins Tax','A','N'
   	 insert bPRWI
   	 select @TaxYear,39,'Nontax Reimb Moving Expense','A','P'
   	 insert bPRWI
   	 select @TaxYear,40,'Other Line 1','A','' -- issue 11999 - changed description from 'Box 14 Line 1 Misc'
   	 insert bPRWI
   	 select @TaxYear,41,'Other Line 2','A','' -- issue 11999 - changed description from 'Box 14 Line 2 Misc'
   	 insert bPRWI
   	 select @TaxYear,42,'Nonstatutory stock options','A','V'
   	 if @TaxYear>='2004' --issue 24336  new code 'W' as of 2004
   		begin
   		insert bPRWI
   		select @TaxYear,43,'Employer Contributions to HSA','A','W'
   		end
   	 if @TaxYear>='2005' --issue 26787  new codes 'Y' and 'Z' as of 2005
   		begin
   		insert bPRWI
   		select @TaxYear,44,'Deferred Comp - 409A','A','Y'
   		insert bPRWI
   		select @TaxYear,45,'Income under 409A','A','Z'
   		insert bPRWI
   		select @TaxYear,46,'Other Line 3','A','' -- issue 26938 - changed description from 'Box 14 Line 3 Misc'
   		insert bPRWI
   		select @TaxYear,47,'Other Line 4','A','' -- issue 26938 - changed description from 'Box 14 Line 4 Misc'
   		end
	 if @TaxYear>='2006' --issue 122401  new codes 'AA' and 'AB' as of 2006 --issue 123025 changed AB to BB
		begin
		insert bPRWI
		select @TaxYear,48,'After-tax Contrib to 401(k)','A','AA'
		insert bPRWI
		select @TaxYear,49,'After-tax Contrib to 403(b)','A','BB'
		end
   	end
   
   -- if specified year is great than the last year this routine was updated for, warn the user
   if @TaxYear > @LatestYear select @msg = 'Items for this tax year are not known.  Using the last known set of items', @rcode = 1
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRWILoad] TO [public]
GO
