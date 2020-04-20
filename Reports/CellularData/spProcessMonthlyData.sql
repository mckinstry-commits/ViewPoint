/****** Object:  StoredProcedure [dbo].[spProcessMonthlyData]    Script Date: 9/5/2014 9:32:15 AM 
******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [dbo].[spProcessMonthlyData]
(
	@StartDate	int 
,	@EndDate	int
,	@Year		int
,	@Month		int
,	@StdRate money = 55.00
,	@Markup decimal(5,2) = .33
)

as

-- Retrieve Job Labor Allocation for date range
IF (@StartDate <= 20141031)
	BEGIN
		exec spGetHRDBPhoneAssignment
		exec spGetCGCJobAssignment @StartDate, @EndDate
		exec spGenCGCCelluarAllocation @Year,@Month,@StdRate,@Markup
	END
ELSE
	BEGIN
		truncate table VPEmployeeJobAssignment
		truncate table VPEmployeePhoneAssignment
		delete from CostAllocation where BillingMonth = @Month and BillingYear=@Year

		exec spGetHRNetPhoneAssignment
		exec spGetVPJobAssignment @StartDate, @EndDate
		exec spGenVPCelluarAllocation @Year,@Month
	END

--Test Script
 --exec spProcessMonthlyData 20141101, 20141130, 2014, 11, 55, .33
 --exec spProcessMonthlyData 20101001, 20101031, 2010, 10, 55, .33
 --exec spProcessMonthlyData 20150301, 20150331, 2015, 3, 55, .33