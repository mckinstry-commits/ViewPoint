SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspPRW2Initialize]  
/************************************************************************  
* CREATED: mh 12/13/06       
* MODIFIED:      
    *	SKA 11/1/2011 - #144904 - remove 2010 New Hire Act processing
*  
* Purpose of Stored Procedure  
*  
*    Initialize W2 run by inserting PRWT, PRWC, and PRWI records.  
*      
*             
* Notes about Stored Procedure  
*   
* This is a combination of 5.x bspPRWILoad and bspPRW2InitPrep.  5.x bspPRW2InitPrep  
* contained inserts/updates to PRWH which are no longer needed due to design changes  
* in 6.x.    
*  
* The following are change notes from 5.x bspPRWiLoad to preserve history.  
    *  Created: EN 12/17/98  
    *  Modified: EN 1/12/99  
    *  Modified: EN 10/18/99 - add items to load for 1999  
    *  Modified: EN 10/21/99 - allow to load same item configuration for future years as is used for the current one  
    *            EN 3/23/00 - within the code, specify the lastest year it was updated for and warn if user tries to initialize past that year  
    *                          ** Note: @LatestYear will now have to be updated each year **  
    *            EN 3/23/00 - cleaned up the code a bit and included warning if user tries to initialize a year prior to 1998  
    *            MV 8/2/01 - Issue 11918 added code 'V' for nonstatutory stock options and changed @LatestYear = 2001  
    *            EN 9/5/01 - issue 11999 removed reference to Box 14 since box #'s change occasionally  
    *     EN 11/9/01 - issue 15217 don't init item 18 as of TaxYear 2001  
    *    EN 10/9/02 - issue 18877 change double quotes to single  
    *     EN 10/10/02 - issue 18916 changed @LatestYear to 2002  
    *     GF 11/05/02 - Item 15 - Military Pay is no longer valid. issue #19255  
    *     EN 9/11/03 - issue 22448 changed @LatestYear to 2003  
    *   EN 8/18/04 - issue 24336  added code W and changed @LatestYear to 2004  
    *   EN 8/10/05 - issue 26787  added codes Y and Z and changed @LatestYear to 2005  
    *   EN 9/07/05 - issue 26938  added codes for Misc lines 3 & 4  
	*   EN 9/5/06 - issue 122395  updated @LatestYear to 2006  
	*   EN 9/6/06 - issue 122401  add codes AA (item #48) and AB (item #49)  
    *   EN 11/07/06 - issue 123025  code for item #49 is actually BB, not AB  
    *   LS 8/19/10 - #139671 Add Code CC for 2010 New Hire Act  
	*   EN 11/5/10 - #141972 Changed AmtType for new Code CC to 'E' (it was 'A')  
    *	AR 11/29/2010 - #142278 - removing old style joins replace with ANSI correct form  
    *	EN 11/14/2011 TK-09867/#141805 Added Code DD for Employer Provided Health Coverage
*  
* The following are change notes from 5.x bspPRW2InitPrep to preserve history  
     * CREATED BY:   EN 11/23/98  
     * MODIFIED By : EN 1/6/99  
     * MODIFIED BY : EN 10/28/99 - add PIN number to inputs  
     *               EN 9/5/01 - issue 11999  
     *   EN 5/21/02 - issue 16510 include bPRLD entries when initialize bPRWT localities  
     *   GG 07/19/02 - #16595 - include dedns flagged as local employee based  
     *   EN 10/9/02 - issue 18877 change double quotes to single  
     *  DC 6/11/03 - Issue 21254 / Improve the intialize choices - clear/startover or just updates accums  
     *  DC 10/22/03 - Issue 22778 - Federal Initialization grid is blank for a year that has already been initialize  
     *  EN 9/06/05 - issue 26938 - include Misc3Desc and Misc4Desc  
     *  
*  
* returns 0 if successfull   
* returns 1 and error msg if failed  
*  
*************************************************************************/  
  
(@prco bCompany, 
 @action char(1), 
 @taxyear char(4), 
 @errmsg varchar(255) = '' OUTPUT)  
  
AS  
SET NOCOUNT ON  
  
DECLARE @rcode int, 
		@latestyear char(4)  

SELECT	@rcode = 0, 
		@latestyear = CONVERT(char(4), YEAR(GETDATE()))  

/* validate action */  
IF @action<>'I' AND @action<>'R'  
BEGIN  
	SELECT @errmsg = 'Option to Initialize or Re-create a W-2 run has not been selected.'  
	RETURN 1  
END  

/* verify Tax Year Ending Month */  
IF @taxyear IS NULL  
BEGIN  
	SELECT @errmsg = 'Tax Year has not been selected.'  
	RETURN 1  
END  

-- If tax year specified is before 1998, warn user that item cannot be loaded unless for some reason that information is found in PRWI  
IF @taxyear < '1998' AND NOT EXISTS (SELECT 1 FROM dbo.bPRWI WHERE TaxYear = @taxyear)  
BEGIN  
	SELECT @errmsg = 'Cannot initialize items list for years prior to 1998.'
	RETURN 1 
END  

IF @action = 'I' --Initializing W2 Run  
BEGIN  
	--Delete any previous records from PRWT for the Tax Year  
	DELETE dbo.PRWT 
	WHERE PRCo = @prco AND TaxYear = @taxyear  
	  
	/* initialize PRWT */  
	INSERT  dbo.PRWT  
	( PRCo,  
	  TaxYear,  
	  [State],  
	  LocalCode,  
	  DednCode,  
	  [Description],  
	  Initialize  
	)  
	--#142278  
	SELECT  i.PRCo,  
			TaxYear = @taxyear,  
			i.[State],  
			LocalCode = ' ',  
			DednCode = i.TaxDedn,  
			d.[Description],  
			'Y'  
	FROM dbo.PRSI i  
	JOIN dbo.PRDL d ON d.PRCo = i.PRCo AND d.DLCode = i.TaxDedn  
	WHERE i.PRCo = @prco  
		  AND i.TaxDedn IS NOT NULL  

	UNION  
	--#142278  
	SELECT  i.PRCo,  
			TaxYear = @taxyear,  
			i.[State],  
			i.LocalCode,  
			DednCode = i.TaxDedn,  
			d.[Description],  
			'Y'  
	FROM dbo.PRLI i  
	JOIN dbo.PRDL d ON d.PRCo = i.PRCo AND d.DLCode = i.TaxDedn  
	WHERE i.PRCo = @prco  
		  AND i.TaxDedn IS NOT NULL  
	               
	--issue 16510 insert additional local deductions  
	INSERT dbo.PRWT  
	( PRCo,  
	TaxYear,  
	[State],  
	LocalCode,  
	DednCode,  
	[Description],  
	Initialize  
	)  

	SELECT i.PRCo,  
		   TaxYear = @taxyear,  
		   i.[State],  
		   i.LocalCode,  
		   DednCode = l.DLCode,  
		   d.[Description],  
		   'Y'  
	FROM dbo.PRLI i  
	JOIN PRLD l ON i.PRCo = l.PRCo AND i.LocalCode = l.LocalCode  
	JOIN PRDL d ON i.PRCo = d.PRCo AND l.DLCode = d.DLCode  
	WHERE i.PRCo = @prco  
		  AND NOT EXISTS (SELECT 1 FROM dbo.PRWT WHERE PRCo = i.PRCo  
													   AND TaxYear = @taxyear  
													   AND State = i.State  
													   AND LocalCode = i.LocalCode  
													   AND DednCode = l.DLCode )  

	-- #16595 add employee based dedns flagged for local reporting  
	INSERT dbo.PRWT  
	( PRCo,  
	TaxYear,  
	State,  
	LocalCode,  
	DednCode,  
	Description,  
	Initialize  
	)  
	SELECT @prco,  
		   @taxyear,  
		   d.W2State,  
		   d.W2Local,  
		   d.DLCode,  
		   d.Description,  
		   'Y'  
	FROM dbo.PRDL d  
	WHERE d.PRCo = @prco  
		  AND d.IncldW2 = 'Y'  
		  AND NOT EXISTS ( SELECT 1 FROM dbo.PRWT WHERE PRCo = @prco  
														AND TaxYear = @taxyear  
														AND State = d.W2State  
														AND LocalCode = d.W2Local  
														AND DednCode = d.DLCode )  

	--#21254  set the values in PRWC to default to the previous years information  
	IF EXISTS ( SELECT TOP 1 1 FROM dbo.PRWC WHERE PRCo = @prco AND TaxYear = @taxyear )  
	BEGIN  
		DELETE FROM dbo.PRWC WHERE PRCo = @prco and TaxYear = @taxyear  
	END  

	INSERT dbo.PRWC 
	( PRCo, 
	TaxYear, 
	Item, 
	EDLType, 
	EDLCode, 
	Description
	)  
	SELECT @prco, 
		   @taxyear,
		   c.Item,
		   c.EDLType,
		   c.EDLCode,
		   c.Description  
	FROM dbo.PRWC c  
	JOIN dbo.PRWI i ON i.Item = c.Item AND i.TaxYear = c.TaxYear  
	WHERE c.PRCo = @prco 
		  AND c.TaxYear = (CAST(@taxyear AS int)-1)  
		  --mod for #144904 - remove Item 50 related to New Hire Act - customers can manually add if desired
		  AND c.Item <> 50
		  --end mod
END  

IF @action = 'R' --Recreating W2 run  
BEGIN  
	IF NOT EXISTS ( SELECT 1 FROM PRWH WHERE PRCo = @prco AND TaxYear = @taxyear )  
	BEGIN  
		SELECT @errmsg = 'Year has not been previously initialized.' 
		RETURN 1
	END  

	/* add missing states/locals to PRWT */  
	INSERT dbo.PRWT  
	( PRCo,  
	TaxYear,  
	[State],  
	LocalCode,  
	DednCode,  
	[Description],  
	Initialize  
	)  
	--#142278  
	SELECT  i.PRCo,  
			TaxYear = @taxyear,  
			i.[State],  
			LocalCode = ' ',  
			DednCode = i.TaxDedn,  
			d.[Description],  
			'Y'  
	FROM dbo.PRSI i  
	JOIN dbo.PRDL d ON d.PRCo = i.PRCo AND d.DLCode = i.TaxDedn  
	WHERE i.PRCo = @prco  
		  AND i.TaxDedn IS NOT NULL  
		  AND NOT EXISTS ( SELECT 1 FROM dbo.PRWT WHERE PRCo = i.PRCo  
													    AND TaxYear = @taxyear  
													    AND [State] = i.[State]  
													    AND LocalCode = ' '  
													    AND DednCode = i.TaxDedn )  
	UNION  
	--#142278  
	SELECT  i.PRCo,  
			TaxYear = @taxyear,  
			i.[State],  
			i.LocalCode,  
			DednCode = i.TaxDedn,  
			d.[Description],  
			'Y'  
	FROM dbo.PRLI i  
	JOIN dbo.PRDL d ON d.PRCo = i.PRCo AND d.DLCode = i.TaxDedn  
	WHERE i.PRCo = @prco  
		  AND i.TaxDedn IS NOT NULL  
		  AND NOT EXISTS ( SELECT 1 FROM dbo.PRWT WHERE PRCo = i.PRCo  
														AND TaxYear = @taxyear  
														AND [State] = i.[State]  
														AND LocalCode = i.LocalCode  
														AND DednCode = i.TaxDedn )  

	--issue 16510 insert additional local deductions  
	INSERT dbo.PRWT 
	( PRCo, 
	TaxYear, 
	[State], 
	LocalCode, 
	DednCode, 
	[Description], 
	Initialize
	)  
	SELECT	i.PRCo, 
			TaxYear = @taxyear, 
			i.[State], 
			i.LocalCode, 
			DednCode = l.DLCode, 
			d.[Description], 
			'Y'  
	FROM dbo.PRLI i  
	JOIN dbo.PRLD l ON i.PRCo=l.PRCo AND i.LocalCode=l.LocalCode  
	JOIN dbo.PRDL d ON i.PRCo=d.PRCo AND l.DLCode=d.DLCode  
	WHERE	i.PRCo= @prco 
			AND NOT EXISTS ( SELECT 1 FROM dbo.PRWT WHERE PRCo=i.PRCo 
														  AND TaxYear=@taxyear  
														  AND State=i.State 
														  AND LocalCode=i.LocalCode 
														  AND DednCode=l.DLCode)  

	-- #16595 add employee based dedns flagged for local reporting  
	INSERT dbo.PRWT 
	( PRCo, 
	TaxYear, 
	[State], 
	LocalCode, 
	DednCode, 
	[Description], 
	Initialize
	)  
	SELECT	@prco, 
			@taxyear, 
			d.W2State, 
			d.W2Local, 
			d.DLCode, 
			d.[Description], 
			'Y'  
	FROM dbo.PRDL d   
	WHERE	d.PRCo = @prco 
			AND d.IncldW2 = 'Y' 
			AND NOT EXISTS (SELECT 1 FROM dbo.PRWT WHERE PRCo=@prco 
														 AND TaxYear=@taxyear  
														 AND State=d.W2State 
														 AND LocalCode=d.W2Local 
														 AND DednCode=d.DLCode) 

	-- issue #144904 - remove New Hire Act related Item code
	DELETE FROM dbo.PRWC 
	WHERE PRCo = @prco 
		  AND TaxYear = @taxyear 
		  AND Item = 50

END  
  
/* load PRWI Report Items */  

-- initialize years starting at 1998  
IF @taxyear >= '1998'  
BEGIN  
	/* clear out pre-existing entries */  
	DELETE dbo.PRWI WHERE TaxYear = @taxyear  

	/* load item information */  
	INSERT dbo.PRWI  
	SELECT @taxyear, 1,'Federal Wages','S',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 2,'Federal Tax Withheld','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 3,'Social Security Wages','E',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 4,'Social Security Tax Withheld','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 5,'Medicare Wages','E',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 6,'Medicare Tax Withheld','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 7,'Social Security Tips','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 8,'Advance EIC','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear, 9,'Dependent Care Benefits','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,10,'Deferred Comp - 401(k)','A','D'  
	INSERT dbo.PRWI  
	SELECT @taxyear,11,'Deferred Comp - 403(b)','A','E'  
	INSERT dbo.PRWI  
	SELECT @taxyear,12,'Deferred Comp - 408(k)(6)','A','F'  
	INSERT dbo.PRWI  
	SELECT @taxyear,13,'Deferred Comp - 457(b)','A','G'  
	INSERT dbo.PRWI  
	SELECT @taxyear,14,'501(c)(18)(D) Tax Exempt Plans','A','H'  

	IF @taxyear < '2002' -- issue #19255  
	BEGIN  
		INSERT dbo.PRWI  
		SELECT @taxyear,15,'Military Pay','A','Q'  
	END  

	INSERT dbo.PRWI  
	SELECT @taxyear,16,'Non-qualified 457 Dist/Contrib','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,17,'Non-qualified non 457','A',''  

	IF @taxyear < '2001' --issue 15217 - don't init item 18 as of tax year 2001  
	BEGIN  
		INSERT dbo.PRWI  
		SELECT @taxyear,18,'Fringe Benefits','A',''  
	END  

	INSERT dbo.PRWI  
	SELECT @taxyear,19,'Group Term Life Ins. > $50K','A','C'  
	INSERT dbo.PRWI  
	SELECT @taxyear,20,'Allocated Tips','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,21,'Uncollected Soc. Sec. on Tips','A','A'  
	INSERT dbo.PRWI  
	SELECT @taxyear,22,'Uncollected Med. Tax on Tips','A','B'  
	INSERT dbo.PRWI  
	SELECT @taxyear,23,'Employer Contributions to MSA','A','R'  
	INSERT dbo.PRWI  
	SELECT @taxyear,24,'Simple Retiremnt Acct - 408(p)','A','S'  
	INSERT dbo.PRWI  
	SELECT @taxyear,25,'Adoption Expenses','A','T'  
	INSERT dbo.PRWI  
	SELECT @taxyear,26,'Puerto Rico Wages','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,27,'Puerto Rico Commissions','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,28,'Puerto Rico Allowances','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,29,'Puerto Rico Tips','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,30,'Puerto Rico Tax Withheld','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,31,'Puerto Rico Retirement Fund','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,32,'Virgin Islands, Guam ... wages','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,33,'Virgin Islands, Guam ... w/h','A',''  
	INSERT dbo.PRWI  
	SELECT @taxyear,34,'Nontaxable Sick Pay','A','J'  
	INSERT dbo.PRWI  
	SELECT @taxyear,35,'Tax on Goldn Parachute Paymnts','A','K'  
	INSERT dbo.PRWI  
	SELECT @taxyear,36,'Nontax Reimb Business Expenses','A','L'  
	INSERT dbo.PRWI  
	SELECT @taxyear,37,'Uncollected Soc Sec Ins Tax','A','M'  
	INSERT dbo.PRWI  
	SELECT @taxyear,38,'Uncollected Medicare Ins Tax','A','N'  
	INSERT dbo.PRWI  
	SELECT @taxyear,39,'Nontax Reimb Moving Expense','A','P'  
	INSERT dbo.PRWI  
	SELECT @taxyear,40,'Box 14 Line 1','A','' -- issue 137687 - changed description back to 'Box 14 Line 1 Misc'  
	INSERT dbo.PRWI  
	SELECT @taxyear,41,'Box 14 Line 2','A','' -- issue 137687 - changed description back to 'Box 14 Line 2 Misc'  
	INSERT dbo.PRWI  
	SELECT @taxyear,42,'Nonstatutory stock options','A','V'  
	
	IF @taxyear >= '2004' --issue 24336  new code 'W' as of 2004  
	BEGIN  
		INSERT dbo.PRWI  
		SELECT @taxyear,43,'Employer Contributions to HSA','A','W'  
	END
	  
	IF @taxyear >= '2005' --issue 26787  new codes 'Y' and 'Z' as of 2005  
	BEGIN  
		INSERT dbo.PRWI  
		SELECT @taxyear,44,'Deferred Comp - 409A','A','Y'  
		INSERT dbo.PRWI  
		SELECT @taxyear,45,'Income under 409A','A','Z'  
		INSERT dbo.PRWI  
		SELECT @taxyear,46,'Box 14 Line 3','A','' -- issue 137687 - changed description back to 'Box 14 Line 3 Misc'  
		INSERT dbo.PRWI  
		SELECT @taxyear,47,'Box 14 Line 4','A','' -- issue 137687 - changed description back to 'Box 14 Line 4 Misc'  
	END 
	 
	IF @taxyear >= '2006' --issue 122401  new codes 'AA' and 'AB' as of 2006 --issue 123025 changed AB to BB  
	BEGIN  
		INSERT dbo.PRWI  
		SELECT @taxyear,48,'After-tax Contrib to 401(k)','A','AA'  
		INSERT dbo.PRWI  
		SELECT @taxyear,49,'After-tax Contrib to 403(b)','A','BB'  
	END 
	 
	--remove New Hire Act info - #144904
	--IF @taxyear>='2010' --#139671 Add Code CC for 2010 New Hire Act 
	IF @taxyear = '2010' --#144904 should only be = 2010, not >=
	BEGIN  
		INSERT dbo.PRWI   
		SELECT @taxyear,50,'HIRE exempt wages and tips', 'E','CC'
	END
	
	IF @taxyear >= '2010' -- #144904 this was orginally in the New Hire Act section, but now it only applies to the code below
	BEGIN
		INSERT dbo.PRWI  
		SELECT @taxyear,51,'Box 14 Line 5','A','' -- issue 137687 - Added 4 more Box 14 Lines  
		INSERT dbo.PRWI  
		SELECT @taxyear,52,'Box 14 Line 6','A','' -- issue 137687 - Added 4 more Box 14 Lines  
		INSERT dbo.PRWI  
		SELECT @taxyear,53,'Box 14 Line 7','A','' -- issue 137687 - Added 4 more Box 14 Lines  
		INSERT dbo.PRWI  
		SELECT @taxyear,54,'Box 14 Line 8','A','' -- issue 137687 - Added 4 more Box 14 Lines  
	END  
	
	-- add code for Employer Provided Health Coverage as per IRS.gov "Affordable Care Act Tax Provisions"
	IF @taxyear >= '2011'
	BEGIN  
		INSERT dbo.PRWI   
		SELECT @taxyear,55,'Employer Provided Health Cover', 'A','DD'
	END
END  

-- if specified year is great than the last year this routine was updated for, warn the user with a conditional success return code 7  
IF @taxyear > @latestyear 
BEGIN
	SELECT @errmsg = 'Items for this tax year are not known.  Using the last known set of items' 
	RETURN 7
END
  

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRW2Initialize] TO [public]
GO
