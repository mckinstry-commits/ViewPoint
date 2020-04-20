USE [CellularBill]
GO
/****** Object:  StoredProcedure [dbo].[spGenJobReport]    Script Date: 9/12/2014 11:15:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER procedure [dbo].[spGenJobReport]
(
	@JobNumber varchar(20) = null
,	@Year int = null
,	@Month int = null
)
WITH RECOMPILE
as
IF (@Year IS NOT NULL AND @Month IS NOT NULL AND ((@Year = 2014 AND @Month >= 11) OR @Year > 2014))
	SELECT [BillingYear]
	,	   [BillingMonth]
	,	   case [BillingMonth]
			when 1 then 'Q1'
			when 2 then 'Q1'
			when 3 then 'Q1'
			when 4 then 'Q2'
			when 5 then 'Q2'
			when 6 then 'Q2'
			when 7 then 'Q3'
			when 8 then 'Q3'
			when 9 then 'Q3'
			when 10 then 'Q4'
			when 11 then 'Q4'
			when 12 then 'Q4'
			else 'Q?'
		   end as [BillingQuarterName]
	,	   case [BillingMonth]
			when 1 then '01 - Jan'
			when 2 then '02 - Feb'
			when 3 then '03 - Mar'
			when 4 then '04 - Apr'
			when 5 then '05 - May'
			when 6 then '06 - Jun'
			when 7 then '07 - Jul'
			when 8 then '08 - Aug'
			when 9 then '09 - Sep'
			when 10 then '10 - Oct'
			when 11 then '11 - Nov'
			when 12 then '12 - Dec'
			else '?? - Unk'
		   end as [BillingMonthName]
		  ,[EmployeeId]
		  ,[EmployeeLastName]
		  ,[EmployeeFirstName]
		  ,[VPEmployeeGLDepartment] as [EmployeeGLDepartment]
		  ,[PhoneNumber]
		  ,[PTT]
		  ,[JobNumber]
		  ,[JobName]
		  ,avg([JobPercentage]) as JobPct
		  ,[VPJobGLDepartment] as [JobGLDepartment]
		  ,[BurdenRate]
		  ,[MarkupPercentRate]
			,cast(sum([DataCharges]) as decimal(18,2)) as DataCharges
			,cast(sum([PhoneCharges]) as decimal(18,2)) as PhoneCharges
			,cast(sum([MessagingCharges]) as decimal(18,2)) as MessagingCharges
			,cast(sum([EquipmentCharges]) as decimal(18,2)) as EquipmentCharges
			,cast(sum([DirectConnectCharges]) as decimal(18,2)) as DirectConnectCharges
			,cast(sum([GPSCharges]) as decimal(18,2)) as GPSCharges
			,cast(sum([DirAssistCharges]) as decimal(18,2)) as DirAsstCharges
			,cast(sum([BillingCharges]) as decimal(18,2)) as TotalCharges
		  ,cast(sum([ActualData] ) as decimal(18,2)) as DataUsage
		  ,cast(sum([ActualMessages] ) as decimal(18,2)) as MessagingUsage
		  ,cast(sum([ActualMinutes] ) as decimal(18,2)) as PhoneUsage
		  ,cast(sum([ActualDirectConnectMinutes]) as decimal(18,2)) as TwoWayUsage
			,cast(sum([DataCharges] * [JobPercentage]) as decimal(18,2)) as JobDataCharges
			,cast(sum([PhoneCharges]  * [JobPercentage]) as decimal(18,2)) as JobPhoneCharges
			,cast(sum([MessagingCharges]  * [JobPercentage]) as decimal(18,2)) as JobMessagingCharges
			,cast(sum([EquipmentCharges]  * [JobPercentage]) as decimal(18,2)) as JobEquipmentCharges
			,cast(sum([DirectConnectCharges]  * [JobPercentage]) as decimal(18,2)) as JobDirectConnectCharges
			,cast(sum([GPSCharges] * [JobPercentage]) as decimal(18,2)) as JobGPSCharges
			,cast(sum([DirAssistCharges] * [JobPercentage]) as decimal(18,2)) as JobDirAsstCharges
		  ,cast(sum([BillingCharges] * [JobPercentage]) as decimal(18,2)) as JobTotalCharges
		  ,cast(sum([ActualData] * [JobPercentage]) as decimal(18,2)) as JobDataUsage
		  ,cast(sum([ActualMessages] * [JobPercentage]) as decimal(18,2)) as JobMessagingUsage
		  ,cast(sum([ActualMinutes] * [JobPercentage]) as decimal(18,2)) as JobPhoneUsage
		  ,cast(sum([ActualDirectConnectMinutes] * [JobPercentage]) as decimal(18,2)) as JobTwoWayUsage
			,/* cast(sum([GPSCharges]) as decimal(18,2)) */ 0.00 as JobDirAsstUsage
		 ,cast(sum([ActualJobCostAllocation]) as decimal(18,2)) as ActualJC
		  ,cast(sum([BurdenJobCostAllocation]) as decimal(18,2)) as StandardJC
		  ,cast(sum([MarkupJobCostAllocation]) as decimal(18,2)) as MarkupJC
	--      ,[EmployeeEffectiveDate]
	--      ,[BurdenRate]
	--      ,[MarkupPercentRate]
			,[Carrier]
	  FROM [dbo].[CostAllocation]
	where(
				[BillingYear] < Year(getdate()) 
			or 
				( 
					[BillingYear] = Year(getdate()) 
				and [BillingMonth] < Month(getdate())  
				) 
			)
	and		([BillingYear] = @Year or @Year is null)
	and		([BillingMonth] = @Month or @Month is null)
	and		([JobNumber] = @JobNumber or @JobNumber is null)
	group by
			[BillingYear]
		  ,[BillingMonth]
		  ,[PhoneNumber]
		  ,[PTT]
		  ,[EmployeeId]
		  ,[EmployeeLastName]
		  ,[EmployeeFirstName]
		  ,[VPEmployeeGLDepartment]
		  ,[JobNumber]
		  ,[JobName]
		  ,[VPJobGLDepartment]
		  ,[BurdenRate]
		  ,[MarkupPercentRate] 
	  			,[Carrier]
	order by
		[BillingYear] desc
	,	[BillingMonth]
	,	[EmployeeId]
ELSE
	SELECT [BillingYear]
	,	   [BillingMonth]
	,	   case [BillingMonth]
			when 1 then 'Q1'
			when 2 then 'Q1'
			when 3 then 'Q1'
			when 4 then 'Q2'
			when 5 then 'Q2'
			when 6 then 'Q2'
			when 7 then 'Q3'
			when 8 then 'Q3'
			when 9 then 'Q3'
			when 10 then 'Q4'
			when 11 then 'Q4'
			when 12 then 'Q4'
			else 'Q?'
		   end as [BillingQuarterName]
	,	   case [BillingMonth]
			when 1 then '01 - Jan'
			when 2 then '02 - Feb'
			when 3 then '03 - Mar'
			when 4 then '04 - Apr'
			when 5 then '05 - May'
			when 6 then '06 - Jun'
			when 7 then '07 - Jul'
			when 8 then '08 - Aug'
			when 9 then '09 - Sep'
			when 10 then '10 - Oct'
			when 11 then '11 - Nov'
			when 12 then '12 - Dec'
			else '?? - Unk'
		   end as [BillingMonthName]
		  ,[EmployeeId]
		  ,[EmployeeLastName]
		  ,[EmployeeFirstName]
		  ,CAST([EmployeeGLDepartment] as CHAR(20)) as [EmployeeGLDepartment]
		  ,[PhoneNumber]
		  ,[PTT]
		  ,[JobNumber]
		  ,[JobName]
		  ,avg([JobPercentage]) as JobPct
		  ,CAST([JobGLDepartment] as CHAR(20)) as [JobGLDepartment]
		  ,[BurdenRate]
		  ,[MarkupPercentRate]
			,cast(sum([DataCharges]) as decimal(18,2)) as DataCharges
			,cast(sum([PhoneCharges]) as decimal(18,2)) as PhoneCharges
			,cast(sum([MessagingCharges]) as decimal(18,2)) as MessagingCharges
			,cast(sum([EquipmentCharges]) as decimal(18,2)) as EquipmentCharges
			,cast(sum([DirectConnectCharges]) as decimal(18,2)) as DirectConnectCharges
			,cast(sum([GPSCharges]) as decimal(18,2)) as GPSCharges
			,cast(sum([DirAssistCharges]) as decimal(18,2)) as DirAsstCharges
			,cast(sum([BillingCharges]) as decimal(18,2)) as TotalCharges
		  ,cast(sum([ActualData] ) as decimal(18,2)) as DataUsage
		  ,cast(sum([ActualMessages] ) as decimal(18,2)) as MessagingUsage
		  ,cast(sum([ActualMinutes] ) as decimal(18,2)) as PhoneUsage
		  ,cast(sum([ActualDirectConnectMinutes]) as decimal(18,2)) as TwoWayUsage
			,cast(sum([DataCharges] * [JobPercentage]) as decimal(18,2)) as JobDataCharges
			,cast(sum([PhoneCharges]  * [JobPercentage]) as decimal(18,2)) as JobPhoneCharges
			,cast(sum([MessagingCharges]  * [JobPercentage]) as decimal(18,2)) as JobMessagingCharges
			,cast(sum([EquipmentCharges]  * [JobPercentage]) as decimal(18,2)) as JobEquipmentCharges
			,cast(sum([DirectConnectCharges]  * [JobPercentage]) as decimal(18,2)) as JobDirectConnectCharges
			,cast(sum([GPSCharges] * [JobPercentage]) as decimal(18,2)) as JobGPSCharges
			,cast(sum([DirAssistCharges] * [JobPercentage]) as decimal(18,2)) as JobDirAsstCharges
		  ,cast(sum([BillingCharges] * [JobPercentage]) as decimal(18,2)) as JobTotalCharges
		  ,cast(sum([ActualData] * [JobPercentage]) as decimal(18,2)) as JobDataUsage
		  ,cast(sum([ActualMessages] * [JobPercentage]) as decimal(18,2)) as JobMessagingUsage
		  ,cast(sum([ActualMinutes] * [JobPercentage]) as decimal(18,2)) as JobPhoneUsage
		  ,cast(sum([ActualDirectConnectMinutes] * [JobPercentage]) as decimal(18,2)) as JobTwoWayUsage
			,/* cast(sum([GPSCharges]) as decimal(18,2)) */ 0.00 as JobDirAsstUsage
		 ,cast(sum([ActualJobCostAllocation]) as decimal(18,2)) as ActualJC
		  ,cast(sum([BurdenJobCostAllocation]) as decimal(18,2)) as StandardJC
		  ,cast(sum([MarkupJobCostAllocation]) as decimal(18,2)) as MarkupJC
	--      ,[EmployeeEffectiveDate]
	--      ,[BurdenRate]
	--      ,[MarkupPercentRate]
			,[Carrier]
	  FROM [dbo].[CostAllocation]
	where(
				[BillingYear] < Year(getdate()) 
			or 
				( 
					[BillingYear] = Year(getdate()) 
				and [BillingMonth] < Month(getdate())  
				) 
			)
	and		([BillingYear] = @Year or @Year is null)
	and		([BillingMonth] = @Month or @Month is null)
	and		([JobNumber] = @JobNumber or @JobNumber is null)
	group by
			[BillingYear]
		  ,[BillingMonth]
		  ,[PhoneNumber]
		  ,[PTT]
		  ,[EmployeeId]
		  ,[EmployeeLastName]
		  ,[EmployeeFirstName]
		  ,[EmployeeGLDepartment]
		  ,[JobNumber]
		  ,[JobName]
		  ,[JobGLDepartment]
		  ,[BurdenRate]
		  ,[MarkupPercentRate] 
	  			,[Carrier]
	order by
		[BillingYear] desc
	,	[BillingMonth]
	,	[EmployeeId]