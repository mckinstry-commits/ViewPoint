IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spGenCelluarAllocation]'))
	DROP PROCEDURE [dbo].[spGenCelluarAllocation]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spGenCGCCelluarAllocation]'))
	DROP PROCEDURE [dbo].[spGenCGCCelluarAllocation]
GO

/**********************************************************************************************************
** Change History
** Date       Author            Description
** ---------- ----------------- ---------------------------------------------------------------------------
** 08/28/2014 Amit Mody			Renamed spGenCellularAllocation to spGenCGCCellularAllocation
** 
***********************************************************************************************************/

CREATE PROCEDURE [dbo].[spGenCGCCelluarAllocation]
    (
      @Year INT ,
      @Month INT ,
      @StdRate MONEY = 55.00 ,
      @Markup DECIMAL(5, 2) = .33
    )
AS
    SET nocount ON

    DECLARE @InvoiceDate DATETIME
    DECLARE @PhoneNumber VARCHAR(20)
    DECLARE @TotalCharges MONEY
    DECLARE @DataCharges MONEY
    DECLARE @PhoneCharges MONEY
    DECLARE @MessagingCharges MONEY
    DECLARE @EquipmentCharges MONEY
    DECLARE @DirectConnectCharges MONEY
    DECLARE @GPSCharges MONEY
    DECLARE @DirAsstCharges MONEY --DirAssistCharges

    DECLARE @UsageMinutes INT
    DECLARE @UsageMessage INT
    DECLARE @UsageData INT
    DECLARE @UsageDC DECIMAL(9, 2) --ActualDirectConnectMinutes

    DECLARE @PTT VARCHAR(20)

    DECLARE @EmployeeId INT
    DECLARE @LastName VARCHAR(50)
    DECLARE @FirstName VARCHAR(50)
    DECLARE @GLDepartmentNumber INT
    DECLARE @EffectiveDate DATETIME

    DECLARE @JobNumber VARCHAR(10)
    DECLARE @JobGLDepartmentNumber INT
    DECLARE @PercentAlloc DECIMAL(38, 6)
    DECLARE @JobName VARCHAR(50)
    DECLARE @JobGLDepartmentName VARCHAR(50)
    DECLARE @EmployeeGLDepartmentName VARCHAR(50)

    DECLARE @actual MONEY
    DECLARE @burden MONEY
    DECLARE @mu MONEY

    DECLARE @actual_minutes DECIMAL(9, 2)
    DECLARE @actual_message DECIMAL(9, 2)
    DECLARE @actual_data DECIMAL(12, 2)
    DECLARE @actual_dc DECIMAL(9, 2) --ActualDirectConnectMinutes

    DECLARE @Carrier NVARCHAR(50)

    DELETE  [CostAllocation]
    WHERE   BillingYear = @Year
            AND BillingMonth = @Month

    DECLARE cbcur CURSOR
    FOR
        SELECT DISTINCT
                InvoiceDate ,
                CAST(PhoneNumber AS VARCHAR(20)) ,
                COALESCE(SUM(TotalCharges), 0) AS TotalCharges ,
                COALESCE(SUM(DataCharges), 0) ,
                COALESCE(SUM(PhoneCharges), 0) ,
                COALESCE(SUM(MessagingCharges), 0) ,
                COALESCE(SUM(EquipmentCharges), 0) ,
                COALESCE(SUM(DirectConnectCharges), 0) ,
                COALESCE(SUM(GPSCharges), 0) ,
                COALESCE(SUM(DirAssistCharges), 0) ,
                COALESCE(SUM(UsageMinutes), 0) ,
                COALESCE(SUM(SMSMessages), 0) ,
                COALESCE(SUM(DataKB), 0) ,
                COALESCE(SUM(DirectConnectMinutes), 0) ,
                Carrier
        FROM    UsageSummary
        WHERE   DATEPART(Year, BillingEndDate) = @Year
                AND DATEPART(Month, BillingEndDate) = @Month
        GROUP BY InvoiceDate ,
                PhoneNumber ,
                Carrier
        HAVING  SUM(TotalCharges) <> 0
        ORDER BY 2

    OPEN cbcur
    FETCH cbcur INTO @InvoiceDate, @PhoneNumber, @TotalCharges, @DataCharges,
        @PhoneCharges, @MessagingCharges, @EquipmentCharges,
        @DirectConnectCharges, @GPSCharges, @DirAsstCharges, @UsageMinutes,
        @UsageMessage, @UsageData, @UsageDC, @Carrier

    WHILE @@fetch_status = 0
        BEGIN
	-- Get Nextel PTT
            SELECT  @PTT = CAST(UFMI AS VARCHAR(20))
            FROM    sprint.BILL_SUBSCRIBER_SAS
            WHERE   PTN = CAST(@PhoneNumber AS CHAR(10))
            AND @Carrier = 'SPRINT' -- Added 12/2013 - Brendan Mason - Prevents ported numbers being assigned Sprint PTT

            PRINT '[' + CAST(@InvoiceDate AS VARCHAR(20)) + '] '
                + CAST(@PhoneNumber AS VARCHAR(20)) + ' [' + COALESCE(@PTT,
                                                              'NoPTT')
                + '] : ' + CAST(@TotalCharges AS VARCHAR(20)) + ' Carrier:'
                + @Carrier

	-- Check if no match, then insert raw totals
            IF EXISTS ( SELECT  1
                        FROM    EmployeePhoneAssignment
                        WHERE   PhoneNumber = @PhoneNumber
                                OR ( @PTT IS NOT NULL
                                     AND PTT = @PTT
                                   ) )
                BEGIN -- Begin Employee Phone Assignment Found

                    IF EXISTS ( SELECT  1
                                FROM    EmployeePhoneAssignment
                                WHERE   PhoneNumber = @PhoneNumber )
                        BEGIN
                            DECLARE epcur CURSOR
                            FOR
                                SELECT TOP 1
                                        EmpId ,
                                        LastName ,
                                        FirstName ,
                                        GLDepartmentNumber ,
                                        EffectiveDate
                                FROM    EmployeePhoneAssignment epa
                                WHERE   ( PhoneNumber = @PhoneNumber
--	or
--	(
--		@PTT is not null
--	and	PTT = @PTT
--	)
                                          )
                                        AND
                                        --                                        EffectiveYear >= @Year and
--                                        EffectiveMonth >= @Month
                                        epa.[EffectiveDate] >= CAST(CAST(@Month AS VARCHAR(2))
                                        + '/1/' + CAST(@Year AS CHAR(4)) AS DATETIME)
                                ORDER BY EffectiveDate ASC
                        END
                    ELSE
                        BEGIN
                            DECLARE epcur CURSOR
                            FOR
                                SELECT TOP 1
                                        EmpId ,
                                        LastName ,
                                        FirstName ,
                                        GLDepartmentNumber ,
                                        EffectiveDate
                                FROM    EmployeePhoneAssignment epa
                                WHERE   ( @PTT IS NOT NULL
                                          AND PTT = @PTT
                                        )
                                        AND
                                        --                                        EffectiveYear >= @Year and
--                                        EffectiveMonth >= @Month
                                        epa.[EffectiveDate] >= CAST(CAST(@Month AS VARCHAR(2))
                                        + '/1/' + CAST(@Year AS CHAR(4)) AS DATETIME)
                                ORDER BY EffectiveDate ASC
                        END

                    OPEN epcur
                    FETCH epcur INTO @EmployeeId, @LastName, @FirstName,
                        @GLDepartmentNumber, @EffectiveDate

                    WHILE @@fetch_status = 0
                        BEGIN
                            PRINT '     ' + CAST(@EmployeeId AS VARCHAR(10))
                                + ' ' + @LastName + ' ' + @FirstName + ' '
                                + CAST(@GLDepartmentNumber AS VARCHAR(10))
                                + ' [' + CAST(@EffectiveDate AS VARCHAR(20))
                                + ']' + ' Carrier:' + @Carrier

		-- Assigned to Employee but no Time Entry
                            IF NOT EXISTS ( SELECT  1
                                            FROM    vwCGCJobAllocation
                                            WHERE   EffectiveYear = @Year
                                                    AND EffectiveMonth = @Month
                                                    AND EmployeeId = @EmployeeId )
                                BEGIN -- Begin Job Allocation NOT Found
                                    IF @TotalCharges < 0
                                        BEGIN
                                            SELECT  @burden = CAST(( @StdRate
                                                              * -1 ) AS MONEY) ,
                                                    @actual_minutes = @UsageMinutes
                                                    * -1 ,
                                                    @actual_message = @UsageMessage
                                                    * -1 ,
                                                    @actual_data = @UsageData
                                                    * -1 ,
                                                    @actual_dc = @UsageDC * -1
                                        END
                                    ELSE
                                        BEGIN
                                            SELECT  @burden = CAST(( @StdRate ) AS MONEY) ,
                                                    @actual_minutes = @UsageMinutes ,
                                                    @actual_message = @UsageMessage ,
                                                    @actual_data = @UsageData ,
                                                    @actual_dc = @UsageDC
                                        END

                                    SELECT  @mu = @TotalCharges * ( 1
                                                              + @Markup )

		--print '     ' + cast(@EmployeeId as varchar(10)) + ' ' + @LastName + ' ' + @FirstName + ' ' + cast(@GLDepartmentNumber as varchar(10)) + ' [' + cast(@EffectiveDate as varchar(20)) + ']'
                                    PRINT '        ' + 'OH' + ' @ '
                                        + COALESCE(CAST(CAST(1 AS DECIMAL(9, 2)) AS VARCHAR(10)),
                                                   'err') + ' '
                                        + COALESCE(CAST(@JobGLDepartmentNumber AS VARCHAR(10)),
                                                   CAST(@GLDepartmentNumber AS VARCHAR(10)))
                                        + '    Actual:'
                                        + COALESCE(CAST(@TotalCharges AS VARCHAR(10)),
                                                   'err') + '    Burden:'
                                        + COALESCE(CAST(@burden AS VARCHAR(10)),
                                                   'err') + '    Markup:'
                                        + COALESCE(CAST(@mu AS VARCHAR(10)),
                                                   'err') + ' Carrier:'
                                        + @Carrier
                                    PRINT ' '

                                    INSERT  INTO [CostAllocation]
                                            ( [BillingYear] ,
                                              [BillingMonth] ,
                                              [PhoneNumber] ,
                                              [PTT] ,
                                              [BillingCharges] ,
                                              [DataCharges] ,
                                              [PhoneCharges] ,
                                              [MessagingCharges] ,
                                              [EquipmentCharges] ,
                                              [DirectConnectCharges] ,
                                              [GPSCharges] ,
                                              [DirAssistCharges] ,
                                              [EmployeeId] ,
                                              [EmployeeLastName] ,
                                              [EmployeeFirstName] ,
                                              [EmployeeGLDepartment] ,
                                              [EmployeeEffectiveDate] ,
                                              [JobNumber] ,
                                              [JobPercentage] ,
                                              [JobGLDepartment] ,
                                              [BurdenRate] ,
                                              [MarkupPercentRate] ,
                                              [ActualJobCostAllocation] ,
                                              [BurdenJobCostAllocation] ,
                                              [MarkupJobCostAllocation] ,
                                              [ActualMinutes] ,
                                              [ActualMessages] ,
                                              [ActualData] ,
                                              [ActualDirectConnectMinutes] ,
                                              [Carrier]
                                            )
                                    VALUES  ( @Year ,
                                              @Month ,
                                              COALESCE(@PhoneNumber,
                                                       'unavailable') ,
                                              COALESCE(@PTT, 'NOPTT') ,
                                              @TotalCharges ,
                                              @DataCharges ,
                                              @PhoneCharges ,
                                              @MessagingCharges ,
                                              @EquipmentCharges ,
                                              @DirectConnectCharges ,
                                              @GPSCharges ,
                                              @DirAsstCharges ,
                                              @EmployeeId ,
                                              @LastName ,
                                              @FirstName ,
                                              @GLDepartmentNumber ,
                                              @EffectiveDate ,
                                              'OH' ,
                                              1.0 ,
                                              NULL ,
                                              @StdRate ,
                                              @Markup ,
                                              @TotalCharges ,
                                              @burden ,
                                              @mu ,
                                              @actual_minutes ,
                                              @actual_message ,
                                              @actual_data ,
                                              @actual_dc ,
                                              @Carrier
				                            )
                                END -- End Job Allocation Found  
                            ELSE
                                BEGIN -- Begin Job Allocation NOT Found -- Begin Employee Phone Assignment NOT Found
                                    DECLARE jacur CURSOR
                                    FOR
                                        SELECT  JobNumber ,
                                                JobName ,
                                                GLDepartmentNumber ,
                                                GLDepartmentName ,
                                                PercentAlloc
                                        FROM    vwCGCJobAllocation
                                        WHERE   EffectiveYear = @Year
                                                AND EffectiveMonth = @Month
                                                AND EmployeeId = @EmployeeId
                                        ORDER BY JobNumber

                                    OPEN jacur
                                    FETCH jacur INTO @JobNumber, @JobName,
                                        @JobGLDepartmentNumber,
                                        @JobGLDepartmentName, @PercentAlloc

                                    WHILE @@fetch_status = 0
                                        BEGIN
                                            SELECT  @actual = CAST(( @TotalCharges
                                                              * @PercentAlloc ) AS MONEY)
                                            SELECT  @mu = @actual * ( 1
                                                              + @Markup )
                                            IF @TotalCharges < 0
                                                BEGIN
                                                    SELECT  @burden = CAST(( @StdRate
                                                              * @PercentAlloc )
                                                            * -1 AS MONEY) ,
                                                            @actual_minutes = @UsageMinutes
                                                            * @PercentAlloc
                                                            * -1 ,
                                                            @actual_message = @UsageMessage
                                                            * @PercentAlloc
                                                            * -1 ,
                                                            @actual_data = @UsageData
                                                            * @PercentAlloc
                                                            * -1 ,
                                                            @actual_dc = @UsageDC
                                                            * @PercentAlloc
                                                            * -1

                                                END
                                            ELSE
                                                BEGIN
                                                    SELECT  @burden = CAST(( @StdRate
                                                              * @PercentAlloc ) AS MONEY) ,
                                                            @actual_minutes = @UsageMinutes
                                                            * @PercentAlloc ,
                                                            @actual_message = @UsageMessage
                                                            * @PercentAlloc ,
                                                            @actual_data = @UsageData
                                                            * @PercentAlloc ,
                                                            @actual_dc = @UsageDC
                                                            * @PercentAlloc 

                                                END

                                            IF LTRIM(RTRIM(@JobNumber)) = ''
                                                OR @JobNumber IS NULL
                                                SELECT  @JobNumber = 'OH'

                                            PRINT '        '
                                                + COALESCE(@JobNumber, 'OH')
                                                + ' @ '
                                                + COALESCE(CAST(CAST(@PercentAlloc AS DECIMAL(9,
                                                              2)) AS VARCHAR(10)),
                                                           'err') + ' '
                                                + COALESCE(CAST(@JobGLDepartmentNumber AS VARCHAR(10)),
                                                           CAST(@GLDepartmentNumber AS VARCHAR(10)))
                                                + '    Actual:'
                                                + COALESCE(CAST(@actual AS VARCHAR(10)),
                                                           'err')
                                                + '    Burden:'
                                                + COALESCE(CAST(@burden AS VARCHAR(10)),
                                                           'err')
                                                + '    Markup:'
                                                + COALESCE(CAST(@mu AS VARCHAR(10)),
                                                           'err')
                                                + ' Carrier:' + @Carrier


                                            INSERT  INTO [CostAllocation]
                                                    ( [BillingYear] ,
                                                      [BillingMonth] ,
                                                      [PhoneNumber] ,
                                                      [PTT] ,
                                                      [BillingCharges] ,
                                                      [DataCharges] ,
                                                      [PhoneCharges] ,
                                                      [MessagingCharges] ,
                                                      [EquipmentCharges] ,
                                                      [DirectConnectCharges] ,
                                                      [GPSCharges] ,
                                                      [DirAssistCharges] ,
                                                      [EmployeeId] ,
                                                      [EmployeeLastName] ,
                                                      [EmployeeFirstName] ,
                                                      [EmployeeGLDepartment] ,
                                                      [EmployeeEffectiveDate] ,
                                                      [JobNumber] ,
                                                      [JobName] ,
                                                      [JobPercentage] ,
                                                      [JobGLDepartment] ,
                                                      [JobGLDepartmentName] ,
                                                      [BurdenRate] ,
                                                      [MarkupPercentRate] ,
                                                      [ActualJobCostAllocation] ,
                                                      [BurdenJobCostAllocation] ,
                                                      [MarkupJobCostAllocation] ,
                                                      [ActualMinutes] ,
                                                      [ActualMessages] ,
                                                      [ActualData] ,
                                                      [ActualDirectConnectMinutes] ,
                                                      [Carrier]
                                                    )
                                            VALUES  ( @Year ,
                                                      @Month ,
                                                      @PhoneNumber ,
                                                      COALESCE(@PTT, 'NOPTT') ,
                                                      @TotalCharges ,
                                                      @DataCharges ,
                                                      @PhoneCharges ,
                                                      @MessagingCharges ,
                                                      @EquipmentCharges ,
                                                      @DirectConnectCharges ,
                                                      @GPSCharges ,
                                                      @DirAsstCharges ,
                                                      @EmployeeId ,
                                                      @LastName ,
                                                      @FirstName ,
                                                      @GLDepartmentNumber ,
                                                      @EffectiveDate ,
                                                      @JobNumber ,
                                                      @JobName ,
                                                      @PercentAlloc ,
                                                      COALESCE(@JobGLDepartmentNumber,
                                                              @GLDepartmentNumber) ,
                                                      @JobGLDepartmentName ,
                                                      @StdRate ,
                                                      @Markup ,
                                                      @actual ,
                                                      @burden ,
                                                      @mu ,
                                                      @actual_minutes ,
                                                      @actual_message ,
                                                      @actual_data ,
                                                      @actual_dc ,
                                                      @Carrier
						                            )

                                            FETCH jacur INTO @JobNumber,
                                                @JobName,
                                                @JobGLDepartmentNumber,
                                                @JobGLDepartmentName,
                                                @PercentAlloc
                                        END
		
                                    CLOSE jacur
                                    DEALLOCATE jacur
		
                                    PRINT ''
                                END  -- End Job Allocation NOT Found
                            SELECT  @EmployeeId = NULL ,
                                    @LastName = NULL ,
                                    @FirstName = NULL ,
                                    @GLDepartmentNumber = NULL ,
                                    @EffectiveDate = NULL
                            FETCH epcur INTO @EmployeeId, @LastName,
                                @FirstName, @GLDepartmentNumber,
                                @EffectiveDate
                        END 

                    CLOSE epcur
                    DEALLOCATE epcur

                END -- End Employee Phone Assignment Found
            ELSE
                BEGIN -- End Employee Phone Assignment NOT Found

                    IF @TotalCharges < 0
                        BEGIN
                            SELECT  @burden = CAST(( @StdRate * -1 ) AS MONEY) ,
                                    @actual_minutes = @UsageMinutes * -1 ,
                                    @actual_message = @UsageMessage * -1 ,
                                    @actual_data = @UsageData * -1 ,
                                    @actual_dc = @UsageDC * -1
                        END
                    ELSE
                        BEGIN
                            SELECT  @burden = CAST(( @StdRate ) AS MONEY) ,
                                    @actual_minutes = @UsageMinutes ,
                                    @actual_message = @UsageMessage ,
                                    @actual_data = @UsageData ,
                                    @actual_dc = @UsageDC 

                        END
                    SELECT  @mu = @TotalCharges * ( 1 + @Markup )

                    PRINT '     ' + 'No Employee' 
                    PRINT '        ' + 'OH' + ' @ '
                        + COALESCE(CAST(CAST(1 AS DECIMAL(9, 2)) AS VARCHAR(10)),
                                   'err') + ' '
                        + COALESCE(CAST(@JobGLDepartmentNumber AS VARCHAR(10)),
                                   CAST(@GLDepartmentNumber AS VARCHAR(10)))
                        + '    Actual:'
                        + COALESCE(CAST(@TotalCharges AS VARCHAR(10)), 'err')
                        + '    Burden:'
                        + COALESCE(CAST(@burden AS VARCHAR(10)), 'err')
                        + '    Markup:' + COALESCE(CAST(@mu AS VARCHAR(10)),
                                                   'err') + ' Carrier:'
                        + @Carrier
                    PRINT ' '

                    INSERT  INTO [CostAllocation]
                            ( [BillingYear] ,
                              [BillingMonth] ,
                              [PhoneNumber] ,
                              [PTT] ,
                              [BillingCharges] ,
                              [DataCharges] ,
                              [PhoneCharges] ,
                              [MessagingCharges] ,
                              [EquipmentCharges] ,
                              [DirectConnectCharges] ,
                              [GPSCharges] ,
                              [DirAssistCharges] ,
                              [EmployeeId] ,
                              [EmployeeLastName] ,
                              [EmployeeFirstName] ,
                              [EmployeeGLDepartment] ,
                              [EmployeeEffectiveDate] ,
                              [JobNumber] ,
                              [JobPercentage] ,
                              [JobGLDepartment] ,
                              [BurdenRate] ,
                              [MarkupPercentRate] ,
                              [ActualJobCostAllocation] ,
                              [BurdenJobCostAllocation] ,
                              [MarkupJobCostAllocation] ,
                              [ActualMinutes] ,
                              [ActualMessages] ,
                              [ActualData] ,
                              [ActualDirectConnectMinutes] ,
                              [Carrier]
                            )
                    VALUES  ( @Year ,
                              @Month ,
                              COALESCE(@PhoneNumber, 'unavailable') ,
                              COALESCE(@PTT, 'NOPTT') ,
                              @TotalCharges ,
                              @DataCharges ,
                              @PhoneCharges ,
                              @MessagingCharges ,
                              @EquipmentCharges ,
                              @DirectConnectCharges ,
                              @GPSCharges ,
                              @DirAsstCharges ,
                              NULL ,
                              NULL ,
                              NULL ,
                              NULL ,
                              NULL ,
                              'OH' ,
                              1.0 ,
                              NULL ,
                              @StdRate ,
                              @Markup ,
                              @TotalCharges ,
                              @burden ,
                              @mu ,
                              @actual_minutes ,
                              @actual_message ,
                              @actual_data ,
                              @actual_dc ,
                              @Carrier
				            )
                END -- End Employee Phone Assignment NOT Found
	

            FETCH cbcur INTO @InvoiceDate, @PhoneNumber, @TotalCharges,
                @DataCharges, @PhoneCharges, @MessagingCharges,
                @EquipmentCharges, @DirectConnectCharges, @GPSCharges,
                @DirAsstCharges, @UsageMinutes, @UsageMessage, @UsageData,
                @UsageDC, @Carrier
        END

    CLOSE cbcur
    DEALLOCATE cbcur

	/*
    UPDATE  [CostAllocation]
    SET     EmployeeGLDepartmentName = LD15A
    FROM    CMS.S1017192.CMSFIL.GLPPFS
    WHERE   [EmployeeGLDepartment] = LGLSA
            AND [BillingYear] = @Year
            AND [BillingMonth] = @Month
	*/
GO