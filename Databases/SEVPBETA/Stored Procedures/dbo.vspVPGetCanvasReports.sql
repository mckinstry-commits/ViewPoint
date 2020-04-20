SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPGetCanvasReports]  
/**************************************************  
* Created: CC 09/04/2008  
* Modified:   
*     6/6/2012 - Ken Eucker -- Changed the stored procedure to grab ReportType of 'My VP' in place
*				of the AppType 'PartReport'
*   
* Retrieves all available reports for the canvas report part given the current template  
*   
*  
*  
****************************************************/  
(@user bVPUserName, @co bCompany, @TemplateName VARCHAR(20))  
  
AS  
SET NOCOUNT ON  
   
 SELECT  
  t.ReportID,   
  t.Title,  
  t.ReportMemo,  
  t.ReportDesc,  
  CASE  
   WHEN t.AppType = 'OLAPReport' THEN 'True'  
   ELSE 'False'  
  END AS IsOLAPReport  
 FROM RPRTShared t   
 INNER JOIN RPTMShared r ON t.ReportID = r.ReportID  
 INNER JOIN  
 (  
  SELECT DISTINCT ReportID, COALESCE(MAX(CASE WHEN [Type] = 'User' THEN Access END) OVER (PARTITION BY ReportID), MAX(CASE WHEN [Type] = 'Group' THEN Access END)OVER (PARTITION BY ReportID)) AS 'Access'  
  FROM  
  (  
   SELECT DISTINCT COALESCE(MAX(CASE WHEN [Type] ='OneCompany' THEN Access END) OVER (PARTITION BY ReportID), MAX(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY ReportID)) AS 'Access', ReportID, 'User' as 'Type'  FROM   
    (  
     -- 1st check: Report security for user and active company, Security Group -1  
     select Access, RPRS.ReportID, 'OneCompany' as 'Type'  
     from dbo.RPRS (nolock)  
     inner join RPRTShared on RPRS.ReportID = RPRTShared.ReportID  
     where Co = @co and SecurityGroup = -1 and VPUserName = @user  
  
     UNION ALL  
  
     -- 2nd check: Report security for user across all companies, Security Group -1 and Company = -1  
     select Access, RPRS.ReportID, 'AllCompany' as 'Type'  
     from dbo.RPRS (nolock)  
     inner join RPRTShared on RPRS.ReportID = RPRTShared.ReportID  
     where Co = -1 and SecurityGroup = -1 and VPUserName = @user  
    )  
    AS UserReportSecurity  
  
  
    UNION   
      
   SELECT DISTINCT COALESCE(MIN(CASE WHEN [Type] = 'OneCompany' THEN Access END) OVER (PARTITION BY ReportID), MIN(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY ReportID), 2), ReportID, 'Group' as 'Type' FROM  
    (  
     -- 3rd check: Report security for groups that user is a member of within active company  
     select min(r.Access) over (partition by t.ReportID) AS 'Access', t.ReportID, 'OneCompany' AS 'Type'  
     from RPRTShared t  
     inner join RPRS r ON t.ReportID = r.ReportID and r.SecurityGroup <> -1  
     inner join DDSU s on s.SecurityGroup = r.SecurityGroup and s.VPUserName = @user  
     where r.Co = @co   
  
     UNION ALL  
  
     -- 4th check: Report security for groups that user is a member of across all companies, Company = -1  
     select min(r.Access) over (partition by t.ReportID) AS 'Access', t.ReportID, 'AllCompany' AS 'Type'  
     from RPRTShared t  
     inner join RPRS r ON t.ReportID = r.ReportID and r.SecurityGroup <> -1  
     inner join DDSU s on s.SecurityGroup = r.SecurityGroup and s.VPUserName = @user  
     where (r.Co = -1 or r.Co is null)   
    )  
    AS GroupReportSecurity  
  )   
  AS ReportSecurity  
 ) AS ReportAccess ON t.ReportID = ReportAccess.ReportID AND ReportAccess.Access = 0  
 WHERE (t.ReportType = 'My VP' OR t.ReportType = 'OLAPReport') AND (UPPER(r.TemplateName) = 'ANY' OR r.TemplateName = @TemplateName)  
 ORDER BY Title  
  
 SELECT ParameterName,  
   p.[Description],  
   ParameterDefault,  
   p.ReportID,  
   COALESCE(p.InputType, DDDTShared.InputType) AS 'InputType',   
   COALESCE(p.InputLength, DDDTShared.InputLength) AS 'InputLength',
   COALESCE(p.InputMask, DDDTShared.InputMask) AS 'InputMask',
   COALESCE(p.Prec, DDDTShared.Prec) AS 'Prec'  
 FROM RPRPShared p  
 INNER JOIN RPRTShared t ON p.ReportID = t.ReportID  
 INNER JOIN RPTMShared r ON t.ReportID = r.ReportID  
 INNER JOIN  
 (  
  SELECT DISTINCT ReportID, COALESCE(MAX(CASE WHEN [Type] = 'User' THEN Access END) OVER (PARTITION BY ReportID), MAX(CASE WHEN [Type] = 'Group' THEN Access END)OVER (PARTITION BY ReportID)) AS 'Access'  
  FROM  
  (  
   SELECT DISTINCT COALESCE(MAX(CASE WHEN [Type] ='OneCompany' THEN Access END) OVER (PARTITION BY ReportID), MAX(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY ReportID)) AS 'Access', ReportID, 'User' as 'Type'  FROM   
    (  
     -- 1st check: Report security for user and active company, Security Group -1  
     select Access, RPRS.ReportID, 'OneCompany' as 'Type'  
     from dbo.RPRS (nolock)  
     inner join RPRTShared on RPRS.ReportID = RPRTShared.ReportID  
     where Co = @co and SecurityGroup = -1 and VPUserName = @user  
  
     UNION ALL  
  
     -- 2nd check: Report security for user across all companies, Security Group -1 and Company = -1  
     select Access, RPRS.ReportID, 'AllCompany' as 'Type'  
     from dbo.RPRS (nolock)  
     inner join RPRTShared on RPRS.ReportID = RPRTShared.ReportID  
     where Co = -1 and SecurityGroup = -1 and VPUserName = @user  
    )  
    AS UserReportSecurity  
  
  
    UNION   
      
   SELECT DISTINCT COALESCE(MIN(CASE WHEN [Type] = 'OneCompany' THEN Access END) OVER (PARTITION BY ReportID), MIN(CASE WHEN [Type] = 'AllCompany' THEN Access END) OVER (PARTITION BY ReportID), 2), ReportID, 'Group' as 'Type' FROM  
    (  
     -- 3rd check: Report security for groups that user is a member of within active company  
     select min(r.Access) over (partition by t.ReportID) AS 'Access', t.ReportID, 'OneCompany' AS 'Type'  
     from RPRTShared t  
     inner join RPRS r ON t.ReportID = r.ReportID and r.SecurityGroup <> -1  
     inner join DDSU s on s.SecurityGroup = r.SecurityGroup and s.VPUserName = @user  
     where r.Co = @co   
  
     UNION ALL  
  
     -- 4th check: Report security for groups that user is a member of across all companies, Company = -1  
     select min(r.Access) over (partition by t.ReportID) AS 'Access', t.ReportID, 'AllCompany' AS 'Type'  
     from RPRTShared t  
     inner join RPRS r ON t.ReportID = r.ReportID and r.SecurityGroup <> -1  
     inner join DDSU s on s.SecurityGroup = r.SecurityGroup and s.VPUserName = @user  
     where (r.Co = -1 or r.Co is null)   
    )  
    AS GroupReportSecurity  
  )   
  AS ReportSecurity  
 ) AS ReportAccess ON t.ReportID = ReportAccess.ReportID AND ReportAccess.Access = 0  
 LEFT OUTER JOIN DDDTShared ON p.Datatype = DDDTShared.Datatype  
 WHERE (t.ReportType = 'My VP' OR t.ReportType = 'OLAPReport') AND (UPPER(r.TemplateName) = 'ANY' OR r.TemplateName = @TemplateName)

GO
GRANT EXECUTE ON  [dbo].[vspVPGetCanvasReports] TO [public]
GO
