SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[vpspPMDailyLogUpdate]
/************************************************************
* CREATED:     2/15/06  CHS
* MODIFIED:		AMR - 9/15/2011 - TK-08520 - changing bNotes to VARCHAR(MAX)
*				GF 12/06/2011 TK-10599
*
* USAGE:
*   Updates PM Daily Logs releated to a passed in Company
*
* CALLED FROM:
*	ViewpointCS Portal  
*
************************************************************/
    (
      @PMCo NVARCHAR(50),
      @Project NVARCHAR(50),
      @LogDate bDate,
      @DailyLog SMALLINT,
      @Description VARCHAR(255),
      @Weather VARCHAR(60),
      @Wind VARCHAR(30),
      @TempHigh SMALLINT,
      @TempLow SMALLINT,
      @EmployeeYN NVARCHAR(50),
      @CrewYN NVARCHAR(50),
      @SubcontractYN NVARCHAR(50),
      @EquipmentYN NVARCHAR(50),
      @ActivityYN NVARCHAR(50),
      @ConversationsYN NVARCHAR(50),
      @DeliveriesYN NVARCHAR(50),
      @AccidentsYN NVARCHAR(50),
      @VisitorsYN NVARCHAR(50),
      @Notes VARCHAR(MAX),
      @UniqueAttchID UNIQUEIDENTIFIER,
      @Original_DailyLog SMALLINT,
      @Original_LogDate bDate,
      @Original_PMCo NVARCHAR(50),
      @Original_Project NVARCHAR(50),
      @Original_AccidentsYN NVARCHAR(50),
      @Original_ActivityYN NVARCHAR(50),
      @Original_ConversationsYN NVARCHAR(50),
      @Original_CrewYN NVARCHAR(50),
      @Original_DeliveriesYN NVARCHAR(50),
      @Original_Description NVARCHAR(255),
      @Original_EmployeeYN NVARCHAR(50),
      @Original_EquipmentYN NVARCHAR(50),
      @Original_SubcontractYN NVARCHAR(50),
      @Original_TempHigh SMALLINT,
      @Original_TempLow SMALLINT,
      @Original_UniqueAttchID UNIQUEIDENTIFIER,
      @Original_VisitorsYN NVARCHAR(50),
      @Original_Weather VARCHAR(60),
      @Original_Wind VARCHAR(30)
    )
AS 
    SET NOCOUNT ON ;
	
    UPDATE  PMDL
    SET     Description = @Description,
            Weather = @Weather,
            Wind = @Wind,
            TempHigh = @TempHigh,
            TempLow = @TempLow,
            EmployeeYN = @EmployeeYN,
            CrewYN = @CrewYN,
            SubcontractYN = @SubcontractYN,
            EquipmentYN = @EquipmentYN,
            ActivityYN = @ActivityYN,
            ConversationsYN = @ConversationsYN,
            DeliveriesYN = @DeliveriesYN,
            AccidentsYN = @AccidentsYN,
            VisitorsYN = @VisitorsYN,
            Notes = @Notes,
            UniqueAttchID = @UniqueAttchID
    WHERE   ( DailyLog = @Original_DailyLog )
            AND ( LogDate = @Original_LogDate )
            AND ( PMCo = @Original_PMCo )
            AND ( Project = @Original_Project )
            AND ( AccidentsYN = @Original_AccidentsYN )
            AND ( ActivityYN = @Original_ActivityYN )
            AND ( ConversationsYN = @Original_ConversationsYN )
            AND ( CrewYN = @Original_CrewYN )
            AND ( DeliveriesYN = @Original_DeliveriesYN )
            AND ( Description = @Original_Description
                  OR @Original_Description IS NULL
                  AND Description IS NULL
                )
            AND ( EmployeeYN = @Original_EmployeeYN )
            AND ( EquipmentYN = @Original_EquipmentYN )
            AND ( SubcontractYN = @Original_SubcontractYN )
            AND ( TempHigh = @Original_TempHigh
                  OR @Original_TempHigh IS NULL
                  AND TempHigh IS NULL
                )
            AND ( TempLow = @Original_TempLow
                  OR @Original_TempLow IS NULL
                  AND TempLow IS NULL
                )
            AND ( UniqueAttchID = @Original_UniqueAttchID
                  OR @Original_UniqueAttchID IS NULL
                  AND UniqueAttchID IS NULL
                )
            AND ( VisitorsYN = @Original_VisitorsYN )
            AND ( Weather = @Original_Weather
                  OR @Original_Weather IS NULL
                  AND Weather IS NULL
                )
            AND ( Wind = @Original_Wind
                  OR @Original_Wind IS NULL
                  AND Wind IS NULL
                ) ;






GO
GRANT EXECUTE ON  [dbo].[vpspPMDailyLogUpdate] TO [VCSPortal]
GO
