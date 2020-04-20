SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     view  [dbo].[brvLookupUsage] as
/*************************************************************************/
--  Purpose:
--  Extract system Lookup (F4)information for Forms and Reports
--
--	NOTE:  
--	To determine if a Lookup, Form, or Report is Custom, the 
--	view xxxxShared is linked (Left Outer Join) with the view xxxx
--  and any null values from xxxx are Custom.
--
--  Maintenance Log:
--  User:		Date		Issue		Description
--  NF			07/01/04	15322		New
--	C Wirtz		09/24/07	125349		Viewpoint 6.0 Release
--
/*************************************************************************/

select
  Lookup =DDDTShared.Lookup
, Custom = Case	when (DDFI.Form is null OR DDDT.Datatype is null) then 'Custom' Else 'VP'	end
, LookupType = 'F' 
, Form=DDFIShared.Form
, FormSeq = DDFIShared.Seq
, ViewName = DDFIShared.ViewName  
, ColumnName = DDFIShared.ColumnName
, Datatype = DDDTShared.Datatype
, ReportID = NULL
, ParameterName = NULL
, ReportParams = Null
, Record = 'DDDT_F                        '
from dbo.DDFIShared DDFIShared (nolock) 
	inner join dbo.DDDTShared DDDTShared (nolock)
	On DDFIShared.Datatype = DDDTShared.Datatype
		Left Outer Join  dbo.DDFI DDFI
		on DDFIShared.Form = DDFI.Form and
		DDFIShared.Seq = DDFI.Seq 
		Left Outer Join  dbo.DDDT DDDT
		on DDDTShared.Datatype = DDDT.Datatype 



Union All

Select
  Lookup = DDDTShared.ReportLookup
, Custom = Case	when (RPRP.ReportID is null OR DDDT.Datatype is null) then 'Custom' Else 'VP'	end
, LookupType = 'R' 
, Form = NULL
, FormSeq = NULL
, ViewName = NULL  
, ColumnName = NULL
, Datatype = DDDTShared.Datatype
, ReportID = RPRPShared.ReportID
, ParameterName = RPRPShared.ParameterName
, ReportParams = NULL 
, Record = 'DDDT_R'
   from dbo.DDDTShared DDDTShared with(NoLock)
    join dbo.RPRPShared RPRPShared with(NoLock) on
   	DDDTShared.Datatype = RPRPShared.Datatype 
		left outer join dbo.RPRP RPRP
		On RPRP.ReportID = RPRPShared.ReportID 
		and RPRP.ParameterName = RPRPShared.ParameterName
		Left Outer Join  dbo.DDDT DDDT
		on DDDTShared.Datatype = DDDT.Datatype 

Union All
Select
  Lookup = DDFLShared.Lookup
, Custom = Case	when (DDFI.Form is null OR DDFL.Form is null) then 'Custom' Else 'VP'	end
, LookupType = 'F' 
, Form =  DDFLShared.Form
, FormSeq = DDFLShared.Seq
, ViewName = DDFIShared.ViewName
, ColumnName = DDFIShared.ColumnName
, Datatype = DDFIShared.Datatype
, ReportID = NULL
, ParameterName = NULL
, ReportParams = NULL 
, Record = 'DDFL'
   from dbo.DDFLShared DDFLShared with(NoLock)
     join dbo.DDFIShared DDFIShared with(NoLock) on 
   	DDFLShared.Form = DDFIShared.Form and
           DDFLShared.Seq = DDFIShared.Seq
		Left Outer Join dbo.DDFL DDFL
		on DDFLShared.Form = DDFL.Form and
		DDFLShared.Seq = DDFL.Seq and
		DDFLShared.Lookup = DDFL.Lookup 
		Left Outer Join dbo.DDFI DDFI
		on DDFIShared.Form = DDFI.Form and
		DDFIShared.Seq = DDFI.Seq 

Union All
Select
  Lookup = RPPLShared.Lookup
, Custom = Case	when (RPRP.ReportID is null OR RPPL.ReportID is null) then 'Custom' Else 'VP'	end
, LookupType = 'R' 
, Form = NULL
, FormSeq =NULL
, ViewName = NULL
, ColumnName = NULL
, Datatype = NULL
, ReportID = RPPLShared.ReportID
, ParameterName = RPPLShared.ParameterName
, ReportParams = RPPLShared.LookupParams
, Record = 'RPPL'
   from dbo.RPPLShared RPPLShared with(NoLock)
     join dbo.RPRPShared RPRPShared with(NoLock) on
   	RPPLShared.ReportID = RPRPShared.ReportID and
   	RPPLShared.ParameterName = RPRPShared.ParameterName
		left outer join dbo.RPRP RPRP
		On RPRPShared.ReportID = RPRP.ReportID 
		and RPRPShared.ParameterName = RPRP.ParameterName
		Left Outer Join  dbo.RPPL RPPL
		on RPPLShared.ReportID = RPPL.ReportID
		and RPPLShared.ParameterName = RPPL.ParameterName
		and RPPLShared.Lookup = RPPL.Lookup



GO
GRANT SELECT ON  [dbo].[brvLookupUsage] TO [public]
GRANT INSERT ON  [dbo].[brvLookupUsage] TO [public]
GRANT DELETE ON  [dbo].[brvLookupUsage] TO [public]
GRANT UPDATE ON  [dbo].[brvLookupUsage] TO [public]
GRANT SELECT ON  [dbo].[brvLookupUsage] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvLookupUsage] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvLookupUsage] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvLookupUsage] TO [Viewpoint]
GO
