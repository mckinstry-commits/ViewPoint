SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/7/11
-- Description:	Retrieves the labor rate for a given SMCo and EntitySeq
-- Modified:    Jacob VH	2/6/13 TFS-39301 Modified to work with changes made to support company copy on rate overrides
-- =============================================
CREATE FUNCTION [dbo].[vfSMRateLaborAdvanced]
(	
	@SMCo bCompany,
	@EntitySeq int,
	@PRCo bCompany,
	@PayType varchar(10),
	@CallType varchar(10),
	@Craft bCraft,
	@Class bClass,
	@Technician varchar(20)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT TOP 1 Rate, AdvancedRateSource
	FROM
	(
		SELECT Rate,
			--By using a ranking system to deterimine the highest matching attribute will be
			--the setup that is used for the rate.
			--So any time the technician matches then it will return its rate no matter how many other
			--attributes match.
			CASE WHEN PayType = @PayType THEN 1 ELSE 0 END +
			CASE WHEN CallType = @CallType THEN 2 ELSE 0 END +
			CASE WHEN PRCo = @PRCo AND Craft = @Craft THEN 4 ELSE 0 END +
			CASE WHEN PRCo = @PRCo AND Craft = @Craft AND Class = @Class THEN 8 ELSE 0 END +
			CASE WHEN Technician = @Technician THEN 16 ELSE 0 END AdvancedRateSource
		FROM dbo.vSMRateOverrideLabor
		WHERE SMCo = @SMCo AND EntitySeq = @EntitySeq
			AND (PayType IS NULL OR PayType = @PayType)
			AND (CallType IS NULL OR CallType = @CallType)
			AND (Craft IS NULL OR (PRCo = @PRCo AND Craft = @Craft))
			AND (Class IS NULL OR (PRCo = @PRCo AND Craft = @Craft AND Class = @Class))
			AND (Technician IS NULL OR Technician = @Technician)) RateOverrides
	ORDER BY AdvancedRateSource DESC
)
GO
GRANT SELECT ON  [dbo].[vfSMRateLaborAdvanced] TO [public]
GO
