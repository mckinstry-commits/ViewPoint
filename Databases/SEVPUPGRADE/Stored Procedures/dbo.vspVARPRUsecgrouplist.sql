SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspVARPRUuserlist    Script Date: 8/28/99 9:35:54 AM ******/
CREATE  PROC [dbo].[vspVARPRUsecgrouplist]
    /*******************************************************************
    * Object:  Stored Procedure dbo.bspVADDMSsecgrouplist
    ********************************************************************
    * lists security set up in bDDMS for a module, ordered by security group
    * input:  module, report, msg
    * ouput:  username, RepGrant(None,Full)
    * Modified	01/12/00 LM - added report security by company feature
    *			AMR 06/22/11 - Issue TK-07089 , Fixing performance issue with if exists statement.
    *********************************************************************/
    (
      @Mod CHAR(2) = NULL ,
      @co SMALLINT ,
      @msg VARCHAR(60) OUTPUT
    )
AS 
    SET nocount ON
    BEGIN
        DECLARE @rcode INTEGER
   
        SELECT  @rcode = 0
        IF ( SELECT COUNT(*)
             FROM   DDMO
             WHERE  Mod = @Mod
           ) <> 1
            AND @Mod <> '' 
            BEGIN
                SELECT  @msg = 'Invalid Module!' ,
                        @rcode = 1
                GOTO bspexit
            END
   
        IF @Mod = '' 
            BEGIN 
                SELECT  @Mod = 'RP'	
            END

        SELECT  r.ReportID ,
                r.Title ,
                ISNULL(s.SecurityGroup, g.SecurityGroup) AS [SecGroup] ,
                s.Access
        FROM    dbo.RPRMShared m 
			--use inline table function for performance issue
                CROSS APPLY (SELECT ReportID, Title FROM dbo.vfRPRTShared(m.ReportID)) r
                LEFT JOIN dbo.vDDSG g ON GroupType = 2
                LEFT JOIN dbo.vRPRS s ON s.ReportID = r.ReportID
                                         AND s.SecurityGroup = g.SecurityGroup
                                         AND s.Co = @co
        WHERE   m.[Mod] = @Mod 

--    case s.SecurityGroup
--      when u.SecurityGroup then 'Full'
--      else 'None'
--    END
--select m.[Mod], t.[ReportID], t.Title, ISNULL(s.Access, 3) AS RepGrant, g.[Name]
--	
--FROM [RPRTShared] t WITH (NOLOCK)
--
--	JOIN [RPRMShared] m WITH(NOLOCK)
--
--	ON m.[ReportID] = t.[ReportID]
--
--	left join dbo.vDDSG g on GroupType = 2
--
--	LEFT JOIN [RPRS] s WITH (NOLOCK) ON s.[ReportID] = t.[ReportID]  
--
--	WHERE m.[Mod] = @Mod AND s.[Co] = @co AND s.[SecurityGroup] <> -1
--
--	UNION
--
--	SELECT m.[Mod], t.[ReportID], t.Title, 3 AS RepGrant, g.[Name] 
--
--	FROM [RPRTShared] t 
--
--	JOIN [RPRMShared] m WITH(NOLOCK)
--
--	ON m.[ReportID] = t.[ReportID]
--
--	CROSS join dbo.vDDSG g
--	
--	CROSS JOIN (SELECT HQCo FROM [HQCO] WHERE HQCo = @co) h
--
--	WHERE Cast(HQCo as varchar(3))+ CAST(t.[ReportID]AS VARCHAR(4)) not in(
--
--	select Cast(Co as varchar(3))+CAST(RPRS.[ReportID] AS VARCHAR(4)) from RPRS WITH (NOLOCK)
-- 
--	LEFT OUTER JOIN DDSG ON RPRS.[SecurityGroup] = [dbo].[DDSG].[SecurityGroup]
-- 
--	WHERE RPRS.[Co] = @co AND RPRS.[SecurityGroup] <> -1) AND m.Mod = @Mod AND GroupType = 2
	--t.Title = @rept
    /*from bRPRT t JOIN bRPRU r ON
       t.Title=r.Title
       JOIN bRPRM m ON
       t.Title = m.Title 
       RIGHT JOIN DDUP u ON
       u.name=r.VPUserName
       Where r.Co=@co and t.Title=@rept and m.Mod = @Mod*/
  
        bspexit:
        RETURN @rcode
    END
   
   
  
 




    SELECT  *
    FROM    DDUP
GO
GRANT EXECUTE ON  [dbo].[vspVARPRUsecgrouplist] TO [public]
GO
