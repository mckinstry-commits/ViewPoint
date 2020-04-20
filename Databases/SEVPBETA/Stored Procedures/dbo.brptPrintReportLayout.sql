SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[brptPrintReportLayout]
/**********************************************************
* Created: JRE 05/16/97  for printing a crystal report layout
* Modified:  ALLENN 04/05/02 - Fixed up procedure for changes listed in issue 16915
*			 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
*			fixed : =Null & notes. Issue #20721 
*			11/18/2003 Dan F. Removed Temp table and corrected select statment
*			 Added DDMO to report to get descriptions for Viewpoint Locations need to  display custom locations Issue22933 NF 
*			3/5/04 DH Removed MultiCompany field issue 23977 DH 
*			GG 01/23/06 - VP6.0 use vRP tables
*
*******************************************************************/ 
  (@BeginTitle bReportTitle=Null, @EndTitle bReportTitle=null)

as 

if @BeginTitle is null select @BeginTitle=' '
if @EndTitle is null select @EndTitle='zzzzzzzzzzzzzzzzzzz'
  
select s.Title,
       s.FileName,
       s.Location,
       LocDesc = DDMO.Title,
       s.ReportType,
       s.ReportOwner,    s.ShowOnMenu,/* RPRT.MultiCompany,*/s.Custom,
       s.ReportMemo,RPRP.ParameterName,RPRP.DisplaySeq,RPRP.ReportDatatype,
       RPRP.Datatype,RPRP.Description,RPRP.ParameterDefault,
       FormatSeq=RPRF.Seq,FormatType= Case when RPRF.FieldType is not null then RPRF.FieldType
                                           when RPRP.ParameterName is not null then 'VisSql Param'
                                           else ' ' end,
       FormatName=RPRF.Name, s.ReportDesc,
       ReportDescription=RPRF.Description,ReportText=convert(varchar(8000),RPRF.ReportText),
       ReportNotes=convert(varchar(8000),s.UserNotes)
from RPRTShared s with (nolock)
Left Join RPRP with (nolock) on s.ReportID=RPRP.ReportID
Left join RPRF with (nolock) on s.ReportID=RPRF.ReportID
Left join DDMO with (nolock) on s.Location = DDMO.Mod
where s.Title>=@BeginTitle and s.Title<=@EndTitle

GO
GRANT EXECUTE ON  [dbo].[brptPrintReportLayout] TO [public]
GO
