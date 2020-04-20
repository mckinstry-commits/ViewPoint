
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPR_AU_SuperWithMin]
   /********************************************************
   * CREATED BY:  EN 8/10/09
   * MODIFIED BY:	MV/DS	06/19/2013	TFS-#49141 expected monthly gross and highest SuperWeeklyMin 
   *				from PRDL, PRED, Craft/Class, Craft/Class templates.
   *				MV		07/31/2013  TFS-57603 corrected typo for PRGroup = @PRGroup	
   *
   * USAGE:
   *   Calculates Superannuation Guarantee (liability) amount as a rate of gross
   *   with a minimum contributio amount that is the greater of Expected Mthly gross or the highest SuperWeeklyMin
   *	from Craft/Class, PRDL,PRED or Craft template or craft class template
   *
   *	Called from bspPRProcessEmpl routine
   *
   * INPUT PARAMETERS:
   *	@calcbasis		subject amount, this pay pd/pay seq
   *	@rate			dedn/liab rate
   *	@workstate		employee's work (unemployment) state
   *
   * OUTPUT PARAMETERS:
   *	@calcamt		calculated dedn/liab amount
   *	@errmsg		error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
  (@calcbasis bDollar,			@rate bUnitCost,	@workstate varchar(4),	@ppds tinyint,			@PRCo bCompany,
    @DLCode bEDLCode,			@PRGroup bGroup,	@PREndDate bDate,		@Employee bEmployee,	@PaySeq tinyint,
    @calcamt bDollar output,	@msg varchar(255) = null output)

   AS
   SET NOCOUNT ON

   DECLARE	@rcode int,	@procname varchar(30), @HighestSuperWeeklyMin bDollar,@WeeksInPayPeriod tinyint

   SELECT @rcode = 0, @procname = 'bspPR_AU_SuperWithMin'
   
	-- Get # weeks in ppd
	SELECT @WeeksInPayPeriod = Wks
	FROM dbo.PRPC 
	WHERE PRCo=@PRCo AND PRGroup = @PRGroup AND PREndDate = @PREndDate

	-- determine highest weekly minimum
	SELECT @HighestSuperWeeklyMin = MAX(SuperWeeklyMin) 
	FROM (
			-- GET PRED AND PRDL --
			SELECT SuperWeeklyMin = 
					CASE WHEN MAX(l.SuperWeeklyMin) > MAX(d.SuperWeeklyMin) 
						 THEN MAX(l.SuperWeeklyMin) ELSE MAX(d.SuperWeeklyMin) END
			FROM PRDL l
			JOIN PRED d on d.PRCo=d.PRCo AND d.DLCode=l.DLCode
			WHERE l.PRCo=@PRCo AND l.ATOCategory in ('S','SE') 
				AND d.Employee=@Employee AND d.DLCode=@DLCode	
							
			UNION 
			--- GET CLASS AND CRAFT/CLASS ----		  
			SELECT SuperWeeklyMin =
					CASE WHEN MAX(cc.SuperWeeklyMin) > MAX(c.SuperWeeklyMin)
						 THEN MAX(cc.SuperWeeklyMin) ELSE MAX(c.SuperWeeklyMin) END
					FROM dbo.PRTH t
					LEFT JOIN dbo.PRCC cc ON cc.PRCo=t.PRCo AND cc.Craft=t.Craft AND cc.Class=t.Class
					LEFT JOIN dbo.PRCM c ON c.PRCo=t.PRCo AND c.Craft=t.Craft
					WHERE t.PRCo= @PRCo 
						AND PRGroup=@PRGroup 
						AND PREndDate=@PREndDate 
						AND Employee=@Employee 
						AND PaySeq=@PaySeq

			UNION
			-- GET CRAFT AND CRAFT/CLASS TEMPLATE ---
			SELECT SuperWeeklyMin =
					CASE WHEN MAX(cc.SuperWeeklyMin) > MAX(c.SuperWeeklyMin)
						 THEN MAX(cc.SuperWeeklyMin) ELSE MAX(c.SuperWeeklyMin) END
			FROM dbo.PRTH t
			LEFT JOIN dbo.JCJM j ON t.PRCo=j.JCCo AND t.Job=j.Job
			LEFT JOIN dbo.PRTC cc ON cc.PRCo=j.JCCo And cc.Template=j.CraftTemplate AND cc.Craft=t.Craft AND cc.Class=t.Class
			LEFT JOIN dbo.PRCT c ON c.PRCo=j.JCCo AND c.Template=j.CraftTemplate AND c.Craft=t.Craft
			WHERE t.PRCo=@PRCo
				AND PRGroup=@PRGroup 
				AND PREndDate=@PREndDate 
				AND Employee=@Employee 
				AND PaySeq=@PaySeq

		) mySuperWeeklyMin

 
   -- determine tax
   SELECT @calcamt = 
	   CASE WHEN (@HighestSuperWeeklyMin * @WeeksInPayPeriod) > (@calcbasis * @rate) 
	   THEN (@HighestSuperWeeklyMin * @WeeksInPayPeriod) 
	   ELSE (@calcbasis * @rate) END

   
   bspexit:
   	RETURN @rcode

   
  
  
GO

GRANT EXECUTE ON  [dbo].[bspPR_AU_SuperWithMin] TO [public]
GO
