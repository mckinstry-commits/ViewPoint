IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[spGenVPCelluarAllocation]'))
	DROP PROCEDURE [dbo].[spGenVPCelluarAllocation]
GO

CREATE PROCEDURE [dbo].[spGenVPCelluarAllocation]
    (
      @Year INT
     ,@Month INT 
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
    DECLARE @GLDepartmentNumber CHAR(20)
    DECLARE @EffectiveDate DATETIME

    DECLARE @JobNumber VARCHAR(10)
    DECLARE @JobGLDepartmentNumber CHAR(20)
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
	
	DECLARE @StdRate MONEY
	DECLARE @Markup DECIMAL(5, 2)

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
        FROM    UsageSummary (nolock)
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
            FROM    sprint.BILL_SUBSCRIBER_SAS (nolock)
            WHERE   PTN = CAST(@PhoneNumber AS CHAR(10))
            AND @Carrier = 'SPRINT' -- Added 12/2013 - Brendan Mason - Prevents ported numbers being assigned Sprint PTT

            PRINT '[' + CAST(@InvoiceDate AS VARCHAR(20)) + '] '
                + CAST(@PhoneNumber AS VARCHAR(20)) + ' [' + COALESCE(@PTT,
                                                              'NoPTT')
                + '] : ' + CAST(@TotalCharges AS VARCHAR(20)) + ' Carrier:'
                + @Carrier

	-- Check if no match, then insert raw totals
            IF EXISTS ( SELECT  1
                        FROM    VPEmployeePhoneAssignment (nolock)
                        WHERE   PhoneNumber = @PhoneNumber
                                OR ( @PTT IS NOT NULL
                                     AND PTT = @PTT
                                   ) )
                BEGIN -- Begin Employee Phone Assignment Found

                    IF EXISTS ( SELECT  1
                                FROM    VPEmployeePhoneAssignment (nolock)
                                WHERE   PhoneNumber = @PhoneNumber )
                        BEGIN
                            DECLARE epcur CURSOR
                            FOR
                                SELECT TOP 1
                                        EmpId ,
                                        LastName ,
                                        FirstName ,
                                        --REPLACE(STR(GLDepartmentNumber,4), SPACE(1), '0') AS GLDepartmentNumber ,
					GLDepartmentNumber ,
                                        EffectiveDate
                                FROM    VPEmployeePhoneAssignment epa (nolock)
                                WHERE   PhoneNumber = @PhoneNumber AND
                                        epa.[EffectiveDate] <= CAST(CAST(@Month AS VARCHAR(2)) + '/1/' + CAST(@Year AS CHAR(4)) AS DATETIME)
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
                                        --REPLACE(STR(GLDepartmentNumber,4), SPACE(1), '0') AS GLDepartmentNumber ,
					GLDepartmentNumber ,
                                        EffectiveDate
                                FROM    VPEmployeePhoneAssignment epa (nolock)
                                WHERE   ( @PTT IS NOT NULL
                                          AND PTT = @PTT
                                        )
                                        AND 
                                        epa.[EffectiveDate] <= CAST(CAST(@Month AS VARCHAR(2)) + '/1/' + CAST(@Year AS CHAR(4)) AS DATETIME)
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
                                            FROM    vwVPJobAllocation (nolock)
                                            WHERE   EffectiveYear = @Year
                                                    AND EffectiveMonth = @Month
                                                    AND EmployeeId = @EmployeeId )
                                BEGIN -- Begin Job Allocation NOT Found
									SET @StdRate = dbo.fnGetEffectiveCompanyRate(REPLACE(STR(@GLDepartmentNumber, 4),SPACE(1),'0'), 'CELLJC')
									SET @Markup = dbo.fnGetEffectiveCompanyRate(REPLACE(STR(@GLDepartmentNumber, 4),SPACE(1),'0'), 'CELLMU')

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

                                    SELECT  @mu = @TotalCharges * ( 1 + @Markup )
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
                                              [Carrier],
											  [VPEmployeeGLDepartment] ,
											  [VPJobGLDepartment]
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
                                              NULL ,
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
                                              @Carrier ,
											  @GLDepartmentNumber ,
											  null
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
                                        FROM    vwVPJobAllocation (nolock)
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
					    SET @StdRate = dbo.fnGetEffectiveCompanyRate(REPLACE(STR(@JobGLDepartmentNumber, 4),SPACE(1),'0'), 'CELLJC')
					    SET @Markup = dbo.fnGetEffectiveCompanyRate(REPLACE(STR(@JobGLDepartmentNumber, 4),SPACE(1),'0'), 'CELLMU')
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
                                                      [Carrier] ,
													  [VPEmployeeGLDepartment] ,
													  [VPJobGLDepartment]
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
                                                      NULL ,
                                                      @EffectiveDate ,
                                                      @JobNumber ,
                                                      @JobName ,
                                                      @PercentAlloc ,
                                                      NULL ,
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
                                                      @Carrier,
													  @GLDepartmentNumber ,
													  COALESCE(@JobGLDepartmentNumber,
                                                              @GLDepartmentNumber)
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
					SET @StdRate = dbo.fnGetEffectiveCompanyRate('0000', 'CELLJC')
					SET @Markup = dbo.fnGetEffectiveCompanyRate('0000', 'CELLMU')

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
                              [Carrier] ,
							  [VPEmployeeGLDepartment] ,
							  [VPJobGLDepartment]
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
                              @Carrier ,
							  NULL ,
							  NULL
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
	
	SELECT glpi3.Instance, glpi3.Description
	INTO #tmpGLPI
	FROM [ViewpointAG\Viewpoint].[Viewpoint].[dbo].[GLPI] glpi3 (nolock)
	WHERE glpi3.PartNo=3 

	UPDATE  [CostAllocation]
    SET     EmployeeGLDepartmentName = glpi3.Description
    FROM    #tmpGLPI glpi3 (nolock)
    WHERE   [VPEmployeeGLDepartment] = glpi3.Instance COLLATE SQL_Latin1_General_CP1_CI_AS
            AND [BillingYear] = @Year
            AND [BillingMonth] = @Month

	UPDATE  [CostAllocation]
    SET     JobGLDepartmentName = glpi3.Description
    FROM    #tmpGLPI glpi3 (nolock)
    WHERE   [VPJobGLDepartment] = glpi3.Instance COLLATE SQL_Latin1_General_CP1_CI_AS
            AND [BillingYear] = @Year
            AND [BillingMonth] = @Month
GO

-- Test Script
EXEC [dbo].[spGenVPCelluarAllocation] 2014, 11
--EXEC [dbo].[spGenVPCelluarAllocation] 2014, 5
--EXEC [dbo].[spGenVPCelluarAllocation] 2014, 4
--EXEC [dbo].[spGenVPCelluarAllocation] 2014, 3
--EXEC [dbo].[spGenVPCelluarAllocation] 2014, 2
--EXEC [dbo].[spGenVPCelluarAllocation] 2014, 1
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 12
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 11
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 10
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 9
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 8
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 7
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 6
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 5
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 4
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 3
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 2
--EXEC [dbo].[spGenVPCelluarAllocation] 2013, 1